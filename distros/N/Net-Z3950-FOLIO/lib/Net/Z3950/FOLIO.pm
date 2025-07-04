package Net::Z3950::FOLIO;

use 5.008000;
use strict;
use warnings;

use Cpanel::JSON::XS qw(decode_json encode_json);
use Net::Z3950::SimpleServer;
use ZOOM; # For ZOOM::Exception
use LWP::UserAgent;
use HTTP::Cookies;
use MARC::Record;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'USMARC');
use Data::Dumper; $Data::Dumper::Indent = 1;

use Net::Z3950::FOLIO::Session;
use Net::Z3950::FOLIO::OPACXMLRecord qw(makeOPACXMLRecord);
use Net::Z3950::FOLIO::RPN;
use Net::Z3950::FOLIO::SurrogateDiagnostic;


our $VERSION = 'v4.2.0';


sub FORMAT_USMARC { '1.2.840.10003.5.10' }
sub FORMAT_XML { '1.2.840.10003.5.109.10' }
sub FORMAT_JSON { '1.2.840.10003.5.1000.81.3' }
sub ATTRSET_BIB1 { '1.2.840.10003.3.1' }


=head1 NAME

Net::Z3950::FOLIO - Z39.50 server for FOLIO bibliographic data

=head1 SYNOPSIS

 use Net::Z3950::FOLIO;
 $service = new Net::Z3950::FOLIO('config');
 $service->launch_server("someServer", @ARGV);

=head1 DESCRIPTION

The C<Net::Z3950::FOLIO> module provides all the application logic of
a Z39.50 server that allows searching in and retrieval from the
inventory module of FOLIO.  It is used by the C<z2folio> program, and
there is probably no good reason to make any other program to use it.

The library has only two public entry points: the C<new()> constructor
and the C<launch_server()> method.  The synopsis above shows how they
are used: a Net::Z3950::FOLIO object is created using C<new()>, then
the C<launch_server()> method is invoked on it to start the server.
(In fact, this synopsis is essentially the whole of the code of the
C<simple2zoom> program.  All the work happens inside the library.)

=head1 METHODS

=head2 new($configBase)

 $s2z = new Net::Z3950::FOLIO('config');

Creates and returns a new Net::Z3950::FOLIO object, configured according to
the JSON file C<$configFile.json> specified by the only argument.  The format of
this file is described in C<Net::Z3950::FOLIO::Config>.

=cut

sub new {
    my $class = shift();
    my($cfgbase) = @_;

    my $this = bless {
	cfgbase => $cfgbase || 'config',
	sessions => {}, # Maps database name to session object
    }, $class;

    $this->{server} = Net::Z3950::SimpleServer->new(
	GHANDLE => $this,
	INIT =>    \&_init_handler_wrapper,
	SEARCH =>  \&_search_handler_wrapper,
	FETCH =>   \&_fetch_handler_wrapper,
	DELETE =>  \&_delete_handler_wrapper,
	SORT   =>  \&_sort_handler_wrapper,
    );

    return $this;
}


sub getSession {
    my $this = shift();
    my($name) = @_;

    if (!$this->{sessions}->{$name}) {
	my $session = new Net::Z3950::FOLIO::Session($this, $name);
	$this->{sessions}->{$name} = $session;
	$session->reloadConfigFile();
	$session->login($this->{user}, $this->{pass}) if !$session->{cfg}->{nologin};
    }

    return $this->{sessions}->{$name};
}    


sub _init_handler_wrapper { _eval_wrapper(\&_init_handler, @_) }
sub _search_handler_wrapper { _eval_wrapper(\&_search_handler, @_) }
sub _fetch_handler_wrapper { _eval_wrapper(\&_fetch_handler, @_) }
sub _delete_handler_wrapper { _eval_wrapper(\&_delete_handler, @_) }
sub _sort_handler_wrapper { _eval_wrapper(\&_sort_handler, @_) }


sub _eval_wrapper {
    my $coderef = shift();
    my $args = shift();

    eval {
	&$coderef($args, @_);
    }; if (ref $@ && $@->isa('ZOOM::Exception')) {
	if ($@->diagset() eq 'Bib-1') {
	    $args->{ERR_CODE} = $@->code();
	    $args->{ERR_STR} = $@->addinfo();
	} else {
	    $args->{ERR_CODE} = 100;
	    $args->{ERR_STR} = $@->message() || $@->addinfo();
	}

	if ($@->isa('Net::Z3950::FOLIO::SurrogateDiagnostic')) {
	    $args->{SUR_FLAG} = 1;
	    $args->{RECORD} = ""; # To avoid an uninitialized value warning in SimpleServer.pm
	}

    } elsif ($@) {
	# Non-ZOOM exceptions may be generated by the Perl
	# interpreter, for example if we try to call a method that
	# does not exist in the relevant class.  These should be
	# considered fatal and not reported to the client.
	die $@;
    }
}


sub _init_handler {
    my($args) = @_;
    my $ghandle = $args->{GHANDLE};

    $args->{IMP_ID} = '81';
    $args->{IMP_VER} = $Net::Z3950::FOLIO::VERSION;
    $args->{IMP_NAME} = 'z2folio gateway';

    # Stash these for subsequent use in getSession when it invokes $session->login()
    $ghandle->{user} = $args->{USER};
    $ghandle->{pass} = $args->{PASS};

    # That's all we can do until we know the database name at search time
}


sub _search_handler {
    my($args) = @_;
    my $ghandle = $args->{GHANDLE};

    my $bases = $args->{DATABASES};
    _throw(111, 1) if @$bases != 1; # Too many databases specified
    my $base = $bases->[0];

    my $session = $ghandle->getSession($base);
    $args->{HANDLE} = $session;
    $session->maybeRefreshToken();

    if ($args->{CQL}) {
	$session->{cql} = $args->{CQL};
    } else {
	my $type1 = $args->{RPN}->{query};
	$session->{cql} = $type1->toCQL($session, $args->{RPN}->{attributeSet});
	warn "search: translated '" . $args->{QUERY} . "' to '" . $session->{cql} . "'\n";
    }

    $session->{sortspec} = undef;
    $args->{HITS} = $session->rerunSearch($args->{SETNAME});
}


sub _fetch_handler {
    my($args) = @_;
    my $session = $args->{HANDLE};
    _throw(30, $args->{SETNAME}) if !$session;

    $session->maybeRefreshToken();

    my $rs = $session->{resultsets}->{$args->{SETNAME}};
    _throw(30, $args->{SETNAME}) if !$rs; # Result set does not exist

    my $index1 = $args->{OFFSET};
    _throw(13, $index1) if $index1 < 1 || $index1 > $rs->totalCount();

    my $rec = $rs->record($index1-1);
    if (!defined $rec) {
	# We need to fetch a chunk of records that contains the
	# requested one. We'll do this by splitting the whole set into
	# chunks of the specified size, and fetching the one that
	# contains the requested record.
	# XXX Perhaps this should happen inside $rs->record
	my $index0 = $index1 - 1;
	my $chunkSize = $session->{cfg}->{chunkSize} || 10;
	my $chunk = int($index0 / $chunkSize);
	$session->doSearch($rs, $chunk * $chunkSize, $chunkSize);
	$rec = $rs->record($index1-1);
	_throw(1, "missing record") if !defined $rec;
    }

    my $comp = lc($args->{COMP} || '');
    my $format = $args->{REQ_FORM};
    # warn "REQ_FORM=$format, COMP=$comp\n";

    my $res;
    if ($format eq FORMAT_JSON) {
	$res = $rec->prettyJSON();

    } elsif ($format eq FORMAT_XML && $comp eq 'raw') {
	# Mechanical XML translitation of the JSON response
	$res = $rec->prettyXML();

    } elsif ($format eq FORMAT_XML && $comp eq 'usmarc') {
	# MARCXML made from SRS Marc record
	my $marc = $rec->marcRecord();
	$res = $marc->as_xml_record();
    } elsif ($format eq FORMAT_XML && $comp eq 'opac') {
	# OPAC-format XML
	$res = makeOPACXMLRecord($rec);
    } elsif ($format eq FORMAT_XML) {
	_throw(25, "XML records available in element-sets: raw, usmarc, opac");

    } elsif ($format eq FORMAT_USMARC && (!$comp || $comp eq 'f' || $comp eq 'b')) {
	# Static USMARC from SRS
	my $marc = $rec->marcRecord();
	$res = $marc->as_usmarc();
    } elsif ($format eq FORMAT_USMARC) {
	_throw(25, "USMARC records available in element-sets: f, b");

    } else {
	_throw(239, $format); # 239 = Record syntax not supported
    }

    $args->{RECORD} = $res;
    return;
}


sub _delete_handler {
    my($args) = @_;
    my $session = $args->{HANDLE};
    $session->maybeRefreshToken();

    my $setname = $args->{SETNAME};
    if ($session->{resultsets}->{$setname}) {
	$session->{resultsets}->{$setname} = undef;
    } else {
	$args->{STATUS} = 1; # failure-1: Result set did not exist
    }

    return;
}


sub _sort_handler {
    my($args) = @_;
    my $session = $args->{HANDLE};
    $session->maybeRefreshToken();

    my $setnames = $args->{INPUT};
    _throw(230, '1') if @$setnames > 1; # Sort: too many input results
    my $setname = $setnames->[0];
    my $rs = $session->{resultsets}->{$setname};
    _throw(30, $args->{SETNAME}) if !$rs; # Result set does not exist

    my $cqlSort = $session->sortSpecs2CQL($args->{SEQUENCE});
    _throw(207, Dumper($args->{SEQUENCE})) if !$cqlSort; # Cannot sort according to sequence

    $session->{sortspec} = $cqlSort;
    $session->rerunSearch($args->{OUTPUT});
}


=head2 launch_server($label, @ARGV)

 $s2z->launch_server("someServer", @ARGV);

Launches the Net::Z3950::FOLIO server: this method never returns.  The
C<$label> string is used in logging, and the C<@ARGV> vector of
command-line arguments is interpreted by the YAZ backend server as
described at
https://software.indexdata.com/yaz/doc/server.invocation.html

=cut

sub launch_server {
    my $this = shift();
    my($label, @argv) = @_;

    return $this->{server}->launch_server($label, @argv);
}


sub _throw {
    my($code, $addinfo, $diagset, $isSurrogate) = @_;
    $diagset ||= "Bib-1";

    # HTTP body for errors is sometimes a plain string, sometimes a JSON structure
    if ($addinfo =~ /^{/) {
	my $obj = decode_json($addinfo);
	$addinfo = $obj->{errors} ? $obj->{errors}->[0]->{message} : $obj->{errorMessage};
    }

    if ($isSurrogate) {
	die new Net::Z3950::FOLIO::SurrogateDiagnostic($code, undef, $addinfo, $diagset);
    } else {
	die new ZOOM::Exception($code, undef, $addinfo, $diagset);
    }
}


=head1 SEE ALSO

=over 4

=item The C<z2folio> script conveniently launches the server.

=item C<Net::Z3950::FOLIO::Config> describes the configuration-file format.

=item The C<Net::Z3950::SimpleServer> handles the Z39.50 service.

=back

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 The Open Library Foundation

This software is distributed under the terms of the Apache License,
Version 2.0. See the file "LICENSE" for more information.

=cut

