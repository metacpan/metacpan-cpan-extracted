package Net::Z3950::UDDI;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.04';

use ZOOM; # Used only for ZOOM::Exception and related constants
use Data::Dumper;
$Data::Dumper::Indent = 1;

use Net::Z3950::SimpleServer;
use Net::Z3950::OID; # Provided by the SimpleServer package
use Net::Z3950::UDDI::Config;
use Net::Z3950::UDDI::Session;


=head1 NAME

Net::Z3950::UDDI - Perl extension for querying UDDI services using Z39.50

=head1 SYNOPSIS

  use Net::Z3950::UDDI;
  $handle = new Net::Z3950::UDDI($configFile);
  $handle->launch_server("myAppName", @yazOptions);

=head1 DESCRIPTION

This library provides all the guts of the Z39.50-to-UDDI gateway,
C<z2uddi> (which is supplied along with it).  In the same package
comes an underlying library, C<UDDI::HalfDecent>, which supports a
subset of UDDI but supports it really well, reliably, and with good
error-reporting -- unlike, to pick the module-name out of the thin
air, C<UDDI::Lite> for example.  Also included in the package are the
swarm of auxiliary modules which C<UDDI::HalfDecent> and
C<Net::Z3950::UDDI> use, and C<uddihd>, a simple command-line
test-harness to exercise the UDDI::HalfDecent library.

The gateway provides a server that understands not only ANSI/NISO
Z39.50 (aka. ISO 23950), but also the related web-service protocols
SRU (in both its GET and POST forms) and SRW (SRU over SOAP).

The API of the C<Net::Z3950::UDDI> module itself is trivial: the
synopsis above captures it in its entirely, and is essentially the
whole of the code of the C<z2uddi> script.  I'll document it anyway,
but the important stuff is elsewhere (see below).

=head1 METHODS

=head2 new()

  $handle = new Net::Z3950::UDDI($configFile);

Creates and returns a new Z39.50-to-UDDI gateway object, configured by
the file named as C<$configFile>.

=cut

sub new {
    my $class = shift();
    my($configFile) = @_;

    my $this = bless {
	configFile => $configFile,
	config => undef,
    }, $class;

    $this->_maybe_load_config(1);
    foreach my $db (sort keys %{ $this->{config}->{contents}->{databases} }) {
	warn "Found database: $db\n";
    }

    $this->{server} = new Net::Z3950::SimpleServer(
	GHANDLE => $this,
	INIT =>   \&_init_handler,
	SEARCH => \&_search_handler,
	FETCH =>  \&_fetch_handler,
    );

    return $this;
}


# Used only as read-only data for the configuration compiler
our %_const = (
    package => __PACKAGE__,
    version => $VERSION,
);

sub _maybe_load_config {
    my $this = shift();

    my $configFile = $this->{configFile};
    my $config = $this->{config};
    my @s = stat($configFile) or die "can't stat '$configFile': $!";
    my $mtime = $s[9];

    if (!defined $config || $mtime > $config->timestamp()) {
	warn "configuation file '$configFile' changed: reloading\n"
	    if defined $config;
	$this->{config} = new Net::Z3950::UDDI::Config($this, $configFile,
						       \%_const)
	    or die "can't compile configuration '$configFile'";
    }
}


=head2 launch_server()

  $handle->launch_server($label, @yazOptions);

Launches the gateway C<$handle>, using the C<$label> string in logging
output and running in accordance with the specified YAZ options.  The
implications of this are discussed in the C<z2uddi> documentation.

=cut

sub launch_server {
    my $this = shift();
    my($label, @argv) = @_;

    return $this->{server}->launch_server($label, @argv);
}


sub _init_handler { _eval_wrapper(\&_real_init_handler, @_) }
sub _search_handler { _eval_wrapper(\&_real_search_handler, @_) }
sub _fetch_handler { _eval_wrapper(\&_real_fetch_handler, @_) }


# This can be used by the _real_*_handler() callbacks to signal
# exceptions that will be caught by _eval_wrapper() and translated
# into BIB-1 diagnostics for the client
#
sub _throw {
    my $this = shift();
    if (!ref $this) {
	# Called as a function rather than a method: reinstate argument
	unshift @_, $this;
    }

    my($code, $addinfo, $diagset) = @_;
    $diagset ||= "Bib-1";
    die new ZOOM::Exception($code, undef, $addinfo, $diagset);
}


sub _eval_wrapper {
    my $coderef = shift();
    my $args = shift();
    my $warn = $ENV{EXCEPTION_DEBUG} || 0;

    $args->{GHANDLE}->_maybe_load_config();

    eval {
	&$coderef($args, @_);
    }; if (ref $@ && $@->isa('ZOOM::Exception')) {
	warn "ZOOM error $@" if $warn > 1;
	if ($@->diagset() eq 'Bib-1') {
	    warn "Bib-1 ZOOM error" if $warn > 0;
	    $args->{ERR_CODE} = $@->code();
	    $args->{ERR_STR} = $@->addinfo();
	} elsif ($@->diagset() eq 'info:srw/diagnostic/1') {
	    warn "SRU ZOOM error" if $warn > 0;
	    $args->{ERR_CODE} =
		Net::Z3950::SimpleServer::yaz_diag_srw_to_bib1($@->code());
	    $args->{ERR_STR} = $@->addinfo();
	} elsif ($@->diagset() eq 'ZOOM' &&
		 $@->code() eq ZOOM::Error::CONNECT) {
	    # Special case for when the host is down
	    warn "Special case: host unavailable" if $warn > 0;
	    $args->{ERR_CODE} = 109;
	    $args->{ERR_STR} = $@->addinfo();
	} else {
	    warn "Non-Bib-1, non-SRU ZOOM error" if $warn > 0;
	    $args->{ERR_CODE} = 100;
	    $args->{ERR_STR} = $@->message() || $@->addinfo();
	}
    } elsif ($@) {
	# Non-ZOOM exceptions may be generated by the Perl
	# interpreter, for example if we try to call a method that
	# does not exist in the relevant class.  These should be
	# considered fatal and not reported to the client.
	die $@;
    }
}


sub _real_init_handler {
    my($args) = @_;
    my $gh = $args->{GHANDLE};

    die "GHANDLE not defined: is your SimpleServer too old?  (Need 1.06)"
	if !defined $gh;

    $args->{HANDLE} = new Net::Z3950::UDDI::Session($gh,
						    $args->{USER},
						    $args->{PASS});

    my $zc = $gh->{config}->{contents}->{zparams};
    $args->{IMP_ID} = $zc->{"implementation-id"} ||
	81;
    $args->{IMP_NAME} = $zc->{"implementation-name"} ||
	"z2uddi Z39.50-to-UDDI Gateway";
    $args->{IMP_VER} = $zc->{"implementation-version"} ||
	$Net::Z3950::UDDI::VERSION;
}


sub _real_search_handler {
    my($args) = @_;
    my $gh = $args->{GHANDLE};
    my $session = $args->{HANDLE};

    # Too many databases
    _throw(111) if @{ $args->{DATABASES}} > 1;
    my $dbname = $args->{DATABASES}->[0];
    my $rs = $session->search($dbname, $gh->{config},
			      $args->{SETNAME}, $args->{RPN});
    $args->{HITS} = $rs->count();
}


sub _real_fetch_handler {
    my($args) = @_;
    my $gh = $args->{GHANDLE};
    my $session = $args->{HANDLE};

    my $setname = $args->{SETNAME};
    my $rs = $session->resultset_by_name($setname)
	or _throw(30, $setname);

    my $offset1 = $args->{OFFSET};
    my $xml = $rs->record_as_xml($offset1-1)
	or _throw(13, $offset1);

    $args->{REQ_FORM} eq Net::Z3950::OID::xml
	or _throw(238, "xml");

    $args->{RECORD} = $xml;
}


=head1 SEE ALSO

=head2 Documentation Roadmap

Apart from the C<Net::Z3950::UDDI> module itself, there are many other
components that go to make up the package that provides the
Z39.50-to-UDDI gateway.  Each is documented separately, but here is a
basic overview.

C<z2uddi> is the gateway program, and consists only of a trival
invocation of the C<Net::Z3950::UDDI> library.  That in turn uses four
worker classes: 
C<Net::Z3950::UDDI::Config>
parses the configuration file,
C<Net::Z3950::UDDI::Session>
represents a front-end session which may reference several databases
and result-sets,
C<Net::Z3950::UDDI::Database>
represents a connection to a back-end database
and
C<Net::Z3950::UDDI::ResultSet>
represents a set of records that result from a search.
The C<Config> documentation also describes the configuration file format.

Both the database and result-set classes are virtual: they are
not instantiated directly, but only as subclasses specific to
particular back-ends such as UDDI and SOAP, using modules such as
C<Net::Z3950::UDDI::plugins::uddi>
and
C<Net::Z3950::UDDI::plugins::soap>.
(These backend-specific modules are not individually documented.)

UDDI access is provided by a stand-alone module C<UDDI::HalfDecent>,
which may be useful in other applications.  This in turn uses two
worker classes,
C<UDDI::HalfDecent::ResultSet>
and
C<UDDI::HalfDecent::Record>.
Others may follow as its UDDI capabilities are extended and
generalised.  The program C<uddihd> provides a simple command-line
interface to the UDDI library.

=head2 Prerequsites

Apart from the modules included in the C<Net::Z3950::UDDI>
distribution, the following software is also required.

=over 4

=item *

The C<Net::Z3950::SimpleServer> module provides a Perl API to the YAZ
GFS (Generic Frontend Server) which provides server-side Z39.50, SRU
and SRW protocol capabilities.

=item *

Index Data's fine YAZ toolkit provides the underlying GFS itself.
http://indexdata.com/yaz/

=item *

The C<Exception::Class> module implements the exceptions used by
C<UDDI::HalfDecent>.

=item *

The C<Net::Z3950::ZOOM> module provides the C<ZOOM::Exception> class
used within the gateway: C<Exception::Class>-based exceptions are
translated into ZOOM exceptions as required.  Note that ZOOM is used
I<only> for C<ZOOM::Exception>, and not for any of its other
facilities: specifically, the gateway does not act as a Z39.50, SRU or
SRW client.

=item *

The C<YAML> module provides the parser for the gateway's configuration
file.  (Its error-messages are not very good: it might be possible to
improve matters by using C<YAML::Syck> or C<YAML::Tiny> instead.)

=item *

C<HTML::Entities> provides the much-needed C<encode_entities()>
function to quote funny characters such as less-than and greater-than
for insertion into XML.  It took me I<ages> to find a standard
library, available, as Debian package, that provided this simple but
indispensible function.

=item *

The C<LWP> module (Lib-WWW-Perl) is used to send and receive HTTP
requests and responses for the C<UDDI::HalfDecent> library.

=item *

C<XML::LibXML> is used to parse the XML-formatted UDDI responses.  In
order to use XPath on the parsed documents, it's necessary to have
C<XML::LibXML::XPathContext>: this is included in C<XML::LibXML> from
version 1.61 onwards, but will need to be downloaded and installed
separately if your LibXML is older than that.

=item *

The C<SOAP::Lite> module, which provides horrible, unreliable,
impossible-to-debug SOAP client facilities that may be used to enable
invocation of arbitrary SOAP services that, if you're very lucky,
might work, or at least produce a comprehensible diagnostic.  The
<Net::Z3950::UDDI> distribution includes most of the code to run a
Z39.50 gateway to arbitrary SOAP services, but since it relies on the
notoriously unreliable C<SOAP::Lite> as the back-end, this facility is
not as useful or robust as one might wish (and certainly not solid
enough to build the UDDI support on, as I had hoped).

=back

=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

I gratefully acknowledge the funding provided by the United States
Geological Survey (USGS) to create this software, and the sterling
efforts of Eliot Christian to forge the commercial arrangements.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Mike Taylor.

This library is distributed under the terms of GNU General Public
License, version 2.  A copy of the license is included in the file
"GPL-2" in this distribution.

=cut

1;
