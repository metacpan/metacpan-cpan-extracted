package Net::Z3950::DBIServer;

use DBI;
use Data::Dumper; # For debugging only
use Net::Z3950::SimpleServer;
use Net::Z3950::OID; # Provided by the SimpleServer package
use Net::Z3950::DBIServer::Config;
use Net::Z3950::DBIServer::ResultSet;
use Net::Z3950::DBIServer::GRS1;
use Net::Z3950::DBIServer::XML;
use Net::Z3950::DBIServer::MARC;
use Net::Z3950::DBIServer::SUTRS;
use Net::Z3950::DBIServer::Exception;
use strict;

use vars qw($VERSION);
$VERSION = '1.07';


=head1 NAME

Net::Z3950::DBIServer - Generic Z39.50-to-Relational Database gateway module

=head1 SYNOPSIS

	use Net::Z3950::DBIServer;
	$handle = new Net::Z3950::DBIServer($configFile);
	$handle->launch_server("myAppName", @yazOptions);

=head1 DESCRIPTION

This module provides a generic, configurable gateway between the
Z39.50 information retrieval protocol and pretty much any SQL database
you can think of.  When the DBIServer server module is running, you
can connect your favourite Z39.50 client to it, and issue searches.
The gateway receives Z39.50 searches, translates them into SQL
queries, executes them against a relational database, translates the
resulting rows of SQL tables into Z39.50 records, and sends them back
out to the client.

The mappings from Z39.50 concepts to SQL and back again are controlled
by tables described in L<Net::Z3950::DBIServer::Spec>

=head1 METHODS

=head2 new()

	$handle = new Net::Z3950::DBIServer($configFile);

Creates and returns a new Z39.50-SQL gateway server, configured to
translate back and forth between Z39.50 and SQL concepts by the named
configuration file.  If the file is invalid, error messages are
printed to the standard error stream, and an undefined value is
returned.

A second, argument may optionally be provided.  If it is true, then
zSQLgate no-ops, producing logs but not searching in, or even
connecting to, the backend database.

=cut

### We need to stash our handle in a global due to interface misdesign.
my $horribleTemporaryGlobalHandle;

sub new {
    my $class = shift();
    my($configFile, $noop) = @_;

    my $config = new Net::Z3950::DBIServer::Config($configFile)
	or return undef;

    #{ use Data::Dumper; print Dumper($config); }
    my $ss = new Net::Z3950::SimpleServer(INIT => \&init_handler,
					  SEARCH => \&search_handler,
					  FETCH => \&fetch_handler);

    # Delay DBI->open() until Init handler so each process gets its own
    $horribleTemporaryGlobalHandle = bless { ss => $ss,
			 configFile => $configFile,
			 config => $config,
			 noop => $noop,
			 rs => {}, # mapping of resultSetId to RS objects
		     }, $class;
    return $horribleTemporaryGlobalHandle;
}


sub dbi_driver {
    my $this = shift();
    my $dbname = $this->{config}->dataSource();
    if ($dbname =~ /^dbi:(.*?):/i) {
	return $1;
    } else {
	die "can't extract DBI driver from '$dbname'";
    }
}

sub init_handler {
    my $args = shift();

    warn("INIT: args = {\n" .
	 join("", map { "    $_ -> '" . $args->{$_} . "'\n" }
	      sort keys %$args) .
	 "}\n") if 0;

    $args->{IMP_ID} = "169"; # Mike Taylor's implementor ID
    $args->{IMP_NAME} = ref($horribleTemporaryGlobalHandle);
    $args->{IMP_VER} = "zSQLgate $VERSION";
    $args->{HANDLE} = $horribleTemporaryGlobalHandle;
    my $this = $args->{HANDLE};
    my $config = $this->{config};

    my $dbname = $config->dataSource();
    my $userName = $config->userName();
    my $passWord = $config->passWord();
    #warn "dbname='$dbname', userName='$userName', passWord='$passWord'";
    if ($this->{noop}) {
	warn "no-op mode: not connecting to database";
    } else {
	$this->{dbh} = DBI->connect($dbname, $userName, $passWord,
				    { RaiseError => 0, AutoCommit => 0 })
	or die "can't open dataSource '$dbname': " . $DBI::errstr;

	my $options = $config->options();
	if ($options) {
	    foreach my $key (sort keys %$options) {
		my $val = $options->{$key};
		my $old = $this->{dbh}->{$key};
		$this->{dbh}->{$key} = $val;
		warn "set option '$key' to '$val' (was '$old')";
	    }
	}
    }

    ### We'd prefer to report a connect() error politely to the
    #	client, but SimpleServer doesn't seem to have a way to do this
    #	yet.  You can pass an error code but no addInfo.


    # I can't imagine why this isn't the default
    #$this->{dbh}->{'mysql_enable_utf8'} = 1;
    warn "UTF8='" . $this->{dbh}->{'mysql_enable_utf8'} . "'";
}


sub search_handler {
    my $args = shift();

    warn "in search_handler()\n";
    eval {
	_real_search_handler($args, @_);
    }; if ($@ && ref $@ && $@->isa('Net::Z3950::DBIServer::Exception')) {
	$args->{ERR_CODE} = $@->code();
	$args->{ERR_STR} = $@->addinfo();
    } elsif ($@) {
	die $@;
    }
}


sub _real_search_handler {
    my $args = shift();
    my $this = $args->{HANDLE};

    $this->_maybe_reload_config();
    my $dbnames = $args->{DATABASES};
    ### Should SimpleServer (or something) provide constants for diagnostics?
    if (@$dbnames == 0) {
	# Specified combination of databases not supported ... not great!
	die new Net::Z3950::DBIServer::Exception(23);
    } elsif (@$dbnames > 1) {
	# Too many databases specified (addInfo = maximum)
	die new Net::Z3950::DBIServer::Exception(111, '1');
    }

    my $dbname = $dbnames->[0];
    my $config = $this->{config}->forDb($dbname);
    if (!defined $config) {
	# Database does not exist (addInfo = database name)
	# How is this different from 109 Database unavailable?
	die new Net::Z3950::DBIServer::Exception(235, $dbname);
    }

    my $rpn = $args->{RPN};
    if (defined $rpn) {
	#warn "*GFS-generated RPN = " . Dumper($rpn);
    } else {
	### Pathetic hack: improve this radically!  :-)
	#die new Net::Z3950::DBIServer::Exception(107, "CQL:" . $args->{CQL});
	$rpn = bless {
	    attributeSet => "1.2.840.10003.3.1",
	    query => bless {
		'attributes' => bless([], 'Net::Z3950::RPN::Attributes'),
		'term' => $args->{CQL},
	    }, "Net::Z3950::RPN::Term",
	}, "Net::Z3950::APDU::Query";
	#warn "*Hand-translated RPN = " . Dumper($rpn);
    }

    my $aux = $config->auxiliary();
    my $tablename = @$aux == 0 ? undef : $config->tablename();
    my $SQLcond = $rpn->{query}->SQLcond($this, $config->searchSpec(),
					 $rpn->{attributeSet}, $tablename);
    my $restriction = $config->restriction();
    $SQLcond = "($SQLcond) AND ($restriction)" if defined $restriction;
    warn "*generated SQL condition '$SQLcond'\n";
    my $rs = new Net::Z3950::DBIServer::ResultSet($this, $config, $SQLcond);
    my $setname = $args->{SETNAME};
    $this->{rs}->{$setname} = $rs;
    $args->{HITS} = $rs->count();
}


sub fetch_handler {
    my $args = shift();
    my $this = $args->{HANDLE};

    my $offset = $args->{OFFSET};
    my $setname = $args->{SETNAME};
    my $rs = $this->{rs}->{$setname};

    eval {
	die new Net::Z3950::DBIServer::Exception(30, $setname)
	    if !defined $rs;
	$this->_maybe_reload_config();
	my $dataSpec = $rs->config()->dataSpec();
	#print Dumper($dataSpec);
	my $hashref = $rs->fetch($offset-1);
	#warn "record $offset = " . Dumper($hashref);
	my($record, $schema) = _format($hashref, $args->{REQ_FORM}, $dataSpec);
	$args->{RECORD} = $record;
	$args->{SCHEMA} = $schema if defined $schema;
    }; if ($@ && ref $@ && $@->isa('Net::Z3950::DBIServer::Exception')) {
	$args->{ERR_CODE} = $@->code();
	$args->{ERR_STR} = $@->addinfo();
    } elsif ($@) {
	die $@;
    }
}


# PRIVATE to fetch_handler()
sub _format {
    my($hashref, $recsyn, $dataSpec) = @_;

    # I'm sure there's a more OO way to make this switch ...
    if ($recsyn eq Net::Z3950::OID::grs1 && defined $dataSpec->{GRS1}) {
	return Net::Z3950::DBIServer::GRS1::format($hashref,
						   $dataSpec->{GRS1});
    } elsif ($recsyn eq Net::Z3950::OID::xml && defined $dataSpec->{XML}) {
	return Net::Z3950::DBIServer::XML::format($hashref,
						  $dataSpec->{XML});
    } elsif ($recsyn eq Net::Z3950::OID::usmarc && defined $dataSpec->{MARC}) {
	return Net::Z3950::DBIServer::MARC::format($hashref,
						   $dataSpec->{MARC});
    } elsif ($recsyn eq Net::Z3950::OID::sutrs) {
	return Net::Z3950::DBIServer::SUTRS::format($hashref,
						    $dataSpec->{SUTRS})
	    if defined $dataSpec->{SUTRS};
	# Fall back to hardwired SUTRS formatting, for debugging only
	return join('', map { my $v = $hashref->{$_};
			      defined $v ? "$_: $v\n" : "$_ undefined\n" }
		    sort keys %$hashref);
    } else {
	my @supported = ("SUTRS");
	push @supported, "XML" if  defined $dataSpec->{XML};
	push @supported, "GRS1" if  defined $dataSpec->{GRS1};
	push @supported, "MARC" if  defined $dataSpec->{MARC};
	die new Net::Z3950::DBIServer::Exception(238, join(",", @supported));
    }
}


# Here we just add the SQLcond() method to the class that we want.
# This is an unconventional alternative to a big switch statement in a
# single recursive SQLcond() function, but it's elegant and Perl
# allows it, so there.
#
# All these methods are in some sense private to our search handler.

package Net::Z3950::RPN::And;
sub SQLcond {
    my $this = shift();

    return "(" . ($this->[0]->SQLcond(@_) . ") AND (" .
		  $this->[1]->SQLcond(@_)) . ")";
}


package Net::Z3950::RPN::Or;
sub SQLcond {
    my $this = shift();

    return "(" . ($this->[0]->SQLcond(@_) . ") OR (" .
		  $this->[1]->SQLcond(@_)) . ")";
}


package Net::Z3950::RPN::AndNot;
sub SQLcond {
    my $this = shift();

    return "(" . ($this->[0]->SQLcond(@_) . ") AND NOT (" .
		  $this->[1]->SQLcond(@_)) . ")";
}


package Net::Z3950::RPN::Term;
sub SQLcond {
    my $this = shift();
    my($server, $config, $attributeSet, $tablename) = @_;

    my %attributes;
    my $defaultAttrs = $config->{"*defaultattrs"};
    if (@{ $this->{attributes} } == 0 && defined $defaultAttrs) {
	foreach my $type (keys %$defaultAttrs) {
	    $attributes{$type} = {
		attributeSet => "1.2.840.10003.3.1", ### fixed BIB-1!
		attributeType => $type,
		attributeValue => $defaultAttrs->{$type},
	    };
	}
    }

    foreach my $attr (@{ $this->{attributes} }) {
	# There's no diagnostic for multiple attributes of the same
	# type, so we just ignore them :-)
	my $type = $attr->{attributeType};
	$attributes{$type} = $attr;
    }
    ### BIB-1/AA assumption (pretty much warranted! :-)
    my $use = $attributes{1};
    my $posVal = $attributes{3}->{attributeValue};

    # Use attribute required but not supplied
    die new Net::Z3950::DBIServer::Exception(116)
	if !defined $use;
    my $val = $use->{attributeValue};
    $attributeSet = $use->{attributeSet} if defined $use->{attributeSet};

    # We now have an attribute set and an access point within it
    my $accessSpec = $config->accessPoint($attributeSet, $val);

    # Unsupported Use attribute
    die new Net::Z3950::DBIServer::Exception(114, $val)
	if !defined $accessSpec;

    # Special case for fulltext searching: relation etc. are ignored
    if (defined $posVal && $posVal == 3 && $accessSpec->{fulltext}) {
	my $term = $this->{term};
	$term = uc($term) if $accessSpec->{uppercase};
	my @fields;
	my $cols = $accessSpec->{columnname};
	foreach my $col (split /\s*,\s*/, $cols) {
	    $col = "$tablename.$col" if defined $tablename && $col !~ /\./;
	    push @fields, $col;
	}

	### We should handle this kind of backend-specific encoding in
	#   a more generic way, probably using Oracle-specific and
	#   MySQL-specific implementations of an abstract class.
	if ($server->dbi_driver() eq "Oracle") {
	    return ("(" . join(" or ", map {
		"CONTAINS($_, " . sqlquote("%$term%") . ") > 0"
			       } @fields) .
		    ")");
	} else {
	    # MySQL syntax
	    return "match (" . join(", ", @fields) . ") " .
		"against (" . sqlquote($term) . ")";
	}
    }

    my $relation = relation($attributeSet, \%attributes);
    my $term = term($attributeSet, \%attributes, $this->{term});
    $term = uc($term) if $accessSpec->{uppercase};
    ###	We're completely ignoring structure (4) and
    #	completeness (6) attributes, in part because I don't honestly
    #	feel 100% that I know what they mean.
    if ($term =~ /%/) {
	### What does it mean to search (e.g.) < left-truncated term?
	die new Net::Z3950::DBIServer::Exception(123,
		"relation other than '=' with truncated term ($term)")
	    if $relation ne "=";
	$relation = "LIKE";
    }

    # We may have multiple comma-separated columns: split 'em up.
    my $cols = $accessSpec->{columnname};
    my @conds;
    foreach my $col (split /\s*,\s*/, $cols) {
	$col = "$tablename.$col" if defined $tablename && $col !~ /\./;
	push @conds, $col . " " . $relation . " " . sqlquote($term);
    }

    return $conds[0] if @conds == 1;
    return "(" . join(" OR ", @conds) . ")";
}

sub sqlquote {
    my($term) = @_;

    $term =~ s/['']/''/g;
    return "'" . $term . "'";
}



sub relation {
    my($attributeSet, $attributes) = @_;

    ### Should check for utility-set attributes as well as BIB-1
    my $attr = $attributes->{2};
    return "=" if !defined $attr;
    my $val = $attr->{attributeValue};

    my @rel = qw(< <= = >= > <>);
    my $rel = $rel[$val-1];
    if (!defined $rel) {
	# Maybe we should try harder on the others?
	#	100 = phonetic
	#	101 = stem
	#	102 = relevance
	#	103 = AlwaysMatches
	die new Net::Z3950::DBIServer::Exception(117, $val);
    }

    return $rel;
}


sub term {
    my($attributeSet, $attributes, $rawterm) = @_;

    ### Should check for utility-set attributes as well as BIB-1
    my $attr = $attributes->{5};
    return $rawterm if !defined $attr;
    my $val = $attr->{attributeValue};

    if ($val == 1) {
	return $rawterm . "%";
    } elsif ($val == 2) {
	return "%" . $rawterm;
    } elsif ($val == 3) {
	# For MySQL only, we could use this kind of hack:
	#	column regexp "^fish[ \t]|[ \t]fish[ \t]|[ \t]fish$";
	# ###
	# We should make backend-specific plugins that know how to do
	# this kind of thing, providing callbacks to interpret
	# completeness, full-text searching, and counting.
	return "%" . $rawterm . "%";
    } elsif ($val == 100) {
	return $rawterm;
    } elsif ($val == 101) {
	$rawterm =~ tr/#/%/;
	return $rawterm;
    }

    # What do the others mean?  Can we implement them?
    #	102 = regExpr-1
    #	103 = regExpr-2
    die new Net::Z3950::DBIServer::Exception(120, $val);
}


# We now return you to your scheduled programmes ...
package Net::Z3950::DBIServer;


sub _maybe_reload_config {
    my $this = shift();

    my $configFile = $this->{configFile};
    my @s = stat($configFile) or die "can't stat '$configFile': $!";
    my $mtime = $s[9];

    if ($mtime > $this->{config}->{"*timeStamp"}) {
	warn "configuation file '$configFile' changed: reloading\n";
	$this->{config} = new Net::Z3950::DBIServer::Config($configFile)
	    or die "can't compile new configuration";
    }
}


=head2 launch_server()

	$handle->launch_server("myAppName", @yazOptions);

Launches the Z39.50-SQL gateway server C<$handle>, using the specified
string as an identifier in any log messages, and with its Z39.50
server behaviour controlled by C<@yazOptions> as described in the YAZ
manual at
http://www.indexdata.com/yaz/doc/server.invocation.php
and also in
L<Net::Z3950::DBIServer::Run>

This method never returns unless an error occurs.

=cut

sub launch_server {
    my $this = shift();
    my($logIdent, @yazOptions) = @_;

    $this->{ss}->launch_server($logIdent, @yazOptions);
}


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Saturday 2nd February 2002.

=head1 SEE ALSO

L<Net::Z3950::DBIServer::Spec>
describes the format of the configuration files which specify this
module's behaviour.

L<Net::Z3950::DBIServer::Config>
describes the API to the configuration file parser.

L<Net::Z3950::DBIServer::ResultSet>
describes the API to the internal representation of result sets.

L<Net::Z3950::DBIServer::GRS1>
describes the API to the GRS1 record formatter.

L<Net::Z3950::DBIServer::XML>
describes the API to the XML record formatter.

L<Net::Z3950::DBIServer::Exception>
describes the simple exception objects used to represent Bib-1
diagnostics.

=cut


1;
