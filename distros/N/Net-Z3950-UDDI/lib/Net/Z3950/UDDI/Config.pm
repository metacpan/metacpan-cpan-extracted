package Net::Z3950::UDDI::Config;
use strict;
use warnings;

use YAML;

=head1 NAME

Net::Z3950::UDDI::Config - Configuration for z2uddi

=head1 SYNOPSIS

 use Net::Z3950::UDDI::Config;
 $config = new Net::Z3950::UDDI::Config($uddi, $configFile, $constHash);

=head1 DESCRIPTION

This module parses configuration files for the C<Net::Z3950::UDDI>
module that implements the guts of C<z2uddi>, the Z39.50-to-UDDI
gateway.

=head1 METHODS

=head2 new()

 $config = new Net::Z3950::UDDI::Config($uddi, $configFile, $constHash);
 use Data::Dumper; print Dumper($config);

Reads the configuration file named by C<$configFile> and parses it on
behalf of the UDDI object C<$uddi>, returning a
Net::Z3950::UDDI::Config object representing its contents.  Constants
referred to in the configuration file are substituted with their
values as specifed in the hash referenced by C<$constHash>.

The returned object is a pretty-much self-documenting rendition of the
configuration file, as you will see if you print it out using
C<Data::Dumper>.

Throws an exception if an error occurs.

=cut

sub new {
    my $class = shift();
    my($uddi, $file, $const) = @_;

    my $yaml = YAML::LoadFile($file);
    my $this = bless {
	uddi => $uddi,
	file => $file,
	contents => $yaml,
	timestamp => time(),
    }, $class;

    $this->_substitute_constants($yaml, $const);
    $this->_annotate_content($yaml);
    $this->_validate_config($yaml);

    return $this;
}


# PRIVATE to new()
sub _substitute_constants {
    my $this = shift();
    my($val, $const) = @_;

    my $ref = ref $val;
    if (!$ref) {
	my $res = "";
	while ($val =~ s/(.*?)\$\((.*?)\)//) {
	    my $s = $const->{$2};
	    $this->_throw(100, "no such parameter '$2'") if !defined $s;
	    $res .= $1 . $s;
	}
	$_[0] = $res . $val;
    } elsif ($ref eq "HASH") {
	foreach my $key (keys %$val) {
	    $this->_substitute_constants($val->{$key}, $const);
	}
    } else {
	$this->_throw(100, "non-hash reference '$ref'");
    }
}


# PRIVATE to new()
sub _annotate_content {
    my $this = shift();
    my($yaml) = @_;

    bless $yaml, "Net::Z3950::UDDI::Config::Content";
    _maybe_bless($yaml->{zparams}, "ZParams");
    my $params = $yaml->{params};
    _maybe_bless($params, "Params");
    my $dbs = $yaml->{databases};
    _maybe_bless($dbs, "Databases");

    foreach my $dbname (keys %$dbs) {
	my $db = $dbs->{$dbname};
	bless $db, "Net::Z3950::UDDI::Config::Database";
	my $dbparams = $db->{params};
	$dbparams = $db->{params} = {} if !defined $dbparams;
	bless $dbparams, "Net::Z3950::UDDI::Config::Params";
	$dbparams->{"*parent"} = $params;

	my $inherit = $db->{"inherit-from"};
	if (defined $inherit) {
	    $db->{"*parent"} = $dbs->{$inherit}
		or $this->_throw(100,
		"database '$dbname' inherits from non-existent '$inherit'");
	}
    }
}


# PRIVATE to _annotate_content()
sub _maybe_bless {
    my($thing, $class) = @_;
    bless $thing, "Net::Z3950::UDDI::Config::$class" if defined $thing;
}    


# PRIVATE to new()
sub _validate_config {
    my $this = shift();
    my($yaml) = @_;

    ### To be done when necessary.  This could be done
    #   programmatically but it would be nicer to find a way to apply
    #   a Relax-NG schema to a YAML document.  That's a non-trivial
    #   job in itself, though, and not urgent.
}


# Delegate
sub _throw {
    my $this = shift();
    return $this->{uddi}->_throw(@_);
}


=head2 file(), timestamp()

 $fileName = $config->file()
 $time = $config->timestamp()

Accessor methods: C<file()> returns the name of the file that was
parsed to generate the configuration object; C<timestamp()> returns
the time (in seconds since the epoch) that the configuration was
compiled.

=cut

sub file { shift()->{name} }
sub timestamp { shift()->{timestamp} }


=head2 Fetching Database and Parameter-Block Properties

The configuration information returned from the contructor is a
self-describing structure reflecting the contents of the configuration
file, which can mostly be traversed by simple hash-accessing.  Two of
the substructures are special, however: database blocks and parameter
blocks.  Both of these may have parents, from which they inherit
values that they do not define themselves.  All database-specific
parameter blocks (of type C<Net::Z3950::UDDI::Config::Params>) inherit
values from the top-level parameter block; and each database block (of
type C<Net::Z3950::UDDI::Config::Database>) may nominate a parent to
inherit from using the C<inherit-from> property.

In order to ensure that this inheritance works, it is necessary
B<always to use the C<property()> method when accessing properties
of these blocks>.  For example:

 $url = $database->property("endpoint");
 $handler = $params->property("soap-fault");

=cut

package Net::Z3950::UDDI::Config::Database;
our @ISA = qw(Net::Z3950::UDDI::Config::Inheritor);

package Net::Z3950::UDDI::Config::Params;
our @ISA = qw(Net::Z3950::UDDI::Config::Inheritor);


package Net::Z3950::UDDI::Config::Inheritor;


# Returns the value of the property called $key in $this or an ancestor
sub property {
    my $this = shift();
    my($key) = @_;

    my $val = $this->{$key};
    return $val if defined $val;
    my $parent = $this->{"*parent"};
    return $parent->property($key) if defined $parent;
    return undef;
}


# Returns a hash of all key/value pairs in $this and ancestors
sub properties {
    my $this = shift();
    
    my %data;
    my $parent = $this->{"*parent"}; 
    %data = $parent->properties() if defined $parent;
    foreach my $key (keys %$this) {
	$data{$key} = $this->{$key} if $key !~ /^\*/;
    }

    return %data;
}


=head1 CONFIGURATION FILE FORMAT

C<z2uddi> is configured primarily by a single file (although see the
SRU and SRW documentation below).  The file is expressed using the
metaformat YAML, which is a structured data language conceptually
somewhat similar to XML but very much easier for humans to read and
write.  YAML is described in detail at http://yaml.org/ but very
briefly:

=over 4

=item *

Comment lines have hash (C<#>) as their first non-whitespace
character, and are ignored.

=item *

Blank lines are ignored.

=item *

Data lines are of the form I<key>C<:> I<value>

=item *

Substructures are introduced by a line of the form I<key>C<:>.  All
lines of a substructure are indented to the same level, which must be
a deeper level than the label that introduces it.

=back

(There is much more to YAML, but the rest of it is not needed for
 C<z2uddi> configuration.)

As usual, an ounce of example is worth a ton of explanation, so here
is a brief bibliography expressed in YAML:

  bibliography:
    TaylorNaish2005:
      authors: Michael P. Taylor, Darren Naish
      year: 2005
      title: The phylogenetic taxonomy of Diplodocoidea (Dinosauria: Sauropoda)

    Wilson2002:
      authors: Jeffrey A. Wilson
      year: 2002
      title: Sauropod dinosaur phylogeny: critique and cladistic analysis

In the C<z2uddi> configuration file, the YAML has three top-level
elements: C<zparams> contains Z39.50 parameters, C<params> contains
parameters that configure the UDDI and SOAP back-ends, and
C<databases> contains the configurations for individual databases.

C<zparams> may contain three elements, all of them  providing
information to be returned to Z39.50 client in the Init Response:
C<implementation-id>,
C<implementation-name>
and
C<implementation-version>.

C<params> may contain any of the following:

=over 4

=item soap-fault

Specifies how the C<SOAP::Lite> library should respond when it detects
a fault.  Acceptable values are C<die> (the default), C<warn> and
C<ignore>.

=item soap-debug

Specifies what logging the C<SOAP::Lite> module should perform.  he
value is a list of C<SOAP::Lite> tracing levels, separated by spaces
or commas.  Recognised levels include but are not limited to:
C<method>,
C<parameters>,
C<fault>,
C<trace>,
C<debug>
and
C<all>

=back

The C<databases> element contains the databases, each named by a
key that is the name they will be known as in Z39.50/SRU/SRW.

Each database may contain a human-readable C<description>; a C<params>
block specific to that database, whose values will override those in
the global C<params>; and an C<inherit-from>, which is the name of
another database in the same configuration.  This last is useful
primarily for setting up debugging versions of databases, which
inherit all functional parameters from their parent but add more
verbose logging.

Every database must specify a C<type>, which indicates the name of a
back-end plugin to use in fulfulling search requests on this
database.  At present, the supported values are C<uddi> and C<soap>.
The interpretation of other values is dependent on the type:

=over 4

=item uddi

C<endpoint> is mandatory, and specifies the URL of the UDDI endpoint
(duh).  C<qualifier> is options, and if provided is a list of UDDI
find-qualifiers to attach to searches, separated by spaces or commas.
Any element whose name begins with C<option-> is interpreted as a UDDI
option, and is set into the C<UDDI::HalfDecent> object before any
searching or retrieval is done.  Recognised options include
C<http-version>, C<uddi-version>, C<proxy> and C<loglabel>.  Finally,
C<log> specifies what types of logging to use, and may contain one or
more logging types separated by spaces or commas.  See
C<UDDI::HalfDecent> for details.

=item soap

C<proxy>, C<uri> and C<service> correspond to the same-named
C<SOAP::Lite> parameters and specify where the SOAP connection is made
to.  (Maybe the names C<endpoint>, C<namespace> and C<wsdl> would be
better, but we'll keep it as it is in honour of C<SOAP::Lite>.
C<indexmap> contains one or more Z39.50 attribute-set names, each of
which contains the number values of one or more access points (use
attributes) from that attribute sets.  These access points are mapped
onto SOAP method names: searches on the specified access points are
translated into the corresponding method calls.

=back

Anywhere in the configuration, implementation constants may be
referenced using the syntax C<$(>I<name>C<)>, and will be substituted
by their implementation-defined values.  A small number of names are
supported, including C<$(package)>, the name of the Perl module that
implements the gateway, and C<$(version)>, the current version of that
module.

An example configuration is provided in the file C<etc/config.yaml> in
the C<z2uddi> distribution: if in doubt, copy and massage this file.

=head1 XML

The configuration file format is based on YAML rather than XML, since
YAML's syntax is much cleaner, more concise and more human-readable.
If, however, it is considered necessary to configure C<z2uddi> using
XML rather than YAML, then the facilities exist to do so: an XSLT
stylesheet is described and provided at
http://yaml.org/xml.html
by which an XML-based configuration file can be automatically
transformed into the YAML version that the gateway uses.  If the
configuration file is maintained in XML (and transformed using simple
C<Makefile>, perhaps,) then facilities such as XInclude may be used to
break the congfiguration across multiple files.

But the YAML version is much nicer.

=head1 SRU AND SRW

The configuration of C<z2uddi> is expressed in terms of incoming
ANSI/NISO Z39.50 connections from the client.  Support for the related
protocols SRU and SRW (which are REST-like and SOAP-based web-services
respectively) is provided by the GFS (Generic Front-end Server) of the
YAZ toolkit, which in turn is made available to Perl via the
C<Net::Z3950::SimpleServer> module.

The GFS translates incoming SRU and SRW requests and reformulates them
as Z39.50 before passing them through the the specific server
implementation, in particular translating SRU's and SRW's query
language into Z39.50's Type-1 query.  Configuration of the GFS is done
using an XML file, often called C<yazgfs.xml>, which is specified on
in the command-line invocation using the C<-f> option.  This file in
turn nominates a CQL-to-PQF translation file which provides the
mappings of specific CQL indexes, relations, etc. to PQF (Prefix Query
Format), from which the Z39.50 Type-1 query is made.  The format of
the GFS configuration file is described at
http://indexdata.com/yaz/doc/server.vhosts.tkl

So to run C<z2uddi> in such a way that Z39.50, SRU and SRW are all
supported, you will need to invoke it as

 z2uddi config.yaml -f yazgfs.xml

Where C<etc/yazgfs.xml> includes the line:

 <cql2rpn>pqf.properties</cql2rpn>

And ensure that the three files C<config.yaml>, C<yazgfs.xml> and
C<pqf.properties> are all in the working directory.  (There are
examples of all three files in the distribution's C<etc> directory.)
Then the server can be interrogated using SRU URLs such as
http://localhost:8019/gbif?version=1.1&operation=searchRetrieve&query=dc.title=geo%25&maximumRecords=1
http://localhost:8019/gbif?version=1.1&operation=searchRetrieve&query=dc.title=/service%20geo%25&maximumRecords=2

=head1 SEE ALSO

C<Net::Z3950::UDDI>
is the module that uses this, and the only one that would ever want
to, I'm sure.

C<z2uddi> is the gateway program, built on C<Net::Z3950::UDDI>, that
is driven by configuration files in this format.

http://yaml.org/ is the web-site of the YAML data-serialisation
language.

=head1 AUTHOR, COPYRIGHT AND LICENSE

As for C<Net::Z3950::UDDI>.

=cut

1;
