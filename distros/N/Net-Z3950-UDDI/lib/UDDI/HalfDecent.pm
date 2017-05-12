package UDDI::HalfDecent;
use strict;
use warnings;

use HTML::Entities;
use LWP::UserAgent;
use HTTP::Request::Common qw();
use XML::LibXML;
use XML::LibXML::XPathContext; # Included separately for pre-1.61 XML::LibXML
use Data::Dumper; $Data::Dumper::Indent = 1;

use Exception::Class (UDDIException => { fields => [ 'detail' ],
					 alias => 'oops' });
UDDIException->Trace(1) if $ENV{UDDI_TRACE};

package UDDIException;
sub full_message {
    my $this = shift();
    return __PACKAGE__ . ": " . $this->message . " (" . $this->detail . ")";
}
package UDDI::HalfDecent;

use UDDI::HalfDecent::ResultSet;


=head1 NAME

UDDI::HalfDecent - a half-decent implementation of UDDI

=head1 SYNOPSIS

 use UDDI::HalfDecent;
 $endpoint = "http://uddi.csiss.gmu.edu:6060/soar/uddi/inquire";
 $uddi = new UDDI::HalfDecent($endpoint);
 $rs = $uddi->find_business(name => 'frog');
 $n = $rs->count();
 foreach $i (0 .. $n-1) {
     $rec = $rs->record($i);
     $key = $rec->xpath('@businessKey');
     $rs2 = $uddi->find_service(businessKey => $key);
 }

=head1 DESCRIPTION

I have tried to use and love C<UDDI::Lite>, honestly I have.  I have
tried to use the underlying C<SOAP::Lite>, which package C<UDDI::Lite>
is part of, and ploughed countless futile man-hours into the effort.
There is no doubt that that suite of modules is a I<tour de force> of
intellectual effort, startling in its strange, crystalline beauty and
innovative to a degree one hardly thought possible.  All of this is,
however, marred by the one tiny flaw that it doesn't work.  And worse,
it doesn't diagnose its failures: error-handling callbacks don't get
invoked, global error-indication objects don't get set, and SOAP
faults perfectly visible in the protocol XML go unreported.

So the obvious thing to do is go into that code and fix it, right?
Except you can't because the code is so obviously a work of genius
that no mortal being can understand it.  (I am not just being feeble
here: this is the overwhelming feeling of the broader community).  The
C<SOAP::Lite> code, including C<UDDI::Lite>, is a fantastic
illustration of Kernighan and Pike's observation: "Everyone knows that
debugging is twice as hard at writing a program in the first place.
So if you're as clever as you can be be when you write it, how will
you ever debug it?" (from I<The Elements of Programming Style>, 1978 -
very nearly thirty years old as I write this, but as fresh and
relevant as ever.  And very funny, which is not something you can say
about most programming books.)

So the C<SOAP::Lite> package is a write-off, and my attempts to
interact with its community underline that: the email address of the
package maintainer no longer works, and the mailing list consists
entirely of forlorn souls such as myself asking "has anyone got I<x>
to work?" and never receiving replies.

And the only other UDDI package on CPAN is one just called C<UDDI>,
the most recent release of which is 0.03 from the year 2000, and which
fails its test-suite.

So that leaves only one option, which is to start from the ground and
roll my own.  At least that way I'll be ablet to debug it.

The number one design principle with this module (and anyone who's
used C<SOAP::Lite> will understand why I make a big deal of this) is
that B<all errors are reported immediately>, through the throwing of a
C<Exception::Class::UDDI> object.  If something goes wrong, you
will know it; and you will know it immediately; and you will know
I<what> went wrong.  Just imagine!

On the downside, this module has no pretention to the flexibility and
generality that C<SOAP::Lite> and C<UDDI::Lite> would offer, if only
they worked.  Those modules set out to encompass RPC-style and
document-style SOAP, XML-RPC, UDDI versions 1, 2 and 3 (although not
really 3) and of course a hundred different ways of expressing
everything.  This module will offer only those facilities required to
access actual UDDI servers - and, more precisely, those facilities
needed by C<z2uddi>.

=head1 METHODS

=head2 new()

 $uddi = new UDDI::HalfDecent($endpoint);

Creates and returns a new UDDI object for communicating with the
specified endpoint.

=cut

sub new {
    my $class = shift();
    my($endpoint) = @_;

    my $this = bless {
	endpoint => $endpoint,
	options => {
	    "http-version" => 1.1,
	    "uddi-version" => 3,
	},
	loglevels => {},
	ua => undef,
	parser => undef,
    }, $class;

    my $levels = $ENV{UDDI_LOG};
    $this->loglevel(split /[,\s]+/, $levels)
	if defined $levels;

    return $this;
}


=head2 option()

 $val = $uddi->option($key);
 $oldval = $uddi->option($key, $newval);
 do_some_stuff($uddi);
 $uddi->option($key, $oldval);

Gets and gets the values of named options in the UDDI object.  When
called with a single argument, the current value of the specified
option is returned; when called with two arguments the option named by
the first is set to the value specified by the second, and the I<old>
value of the named option is returned.

Options affect the functioning of the UDDI object as follows:

=over 4

=item http-version

Specifies the version of HTTP to use.  Valid values are C<1.0> and
C<1.1>; if not specified, HTTP 1.1 is used.

=item uddi-version

Specifies the version of UDDI to use.  Valid values are C<1>, C<2> and
C<3>; if not specified, UDDI version 3 is used.  Note that C<some
servers are arses> when it comes to this: for example, if you send a
v3 request to C<http://uddi.microsoft.com/inquire>, it will send a v2
response whose fault information will therefore not be readable.  So
if you get funny results from a server, try playing with this.

=item proxy

If this is set then it is the URL of a proxy which will be used for
all HTTP transactions.  Not set by default.

=item loglabel

If set to a true value, the all log messages emitted will have a
.prefix of the form C<_log(>I<level>C<)> and the messages themselves
will be enclosed in square brackets.  This makes the logging more
explicit, and in particular makes it possible to see zero-length log
messages such as empty C<response>s.  Not set by default.

=back

=cut

sub option {
    my $this = shift();
    my($key, $value) = @_;

    my $oldval = $this->{options}->{$key};
    $this->{options}->{$key} = $value
	if defined $value;

    return $oldval;
}


=head2 loglevel()

 $uddi->loglevel(qw(-- request response));

Sets the logging level of the UDDI object, controlling what logging
information is emitted on the standard error stream.  Zero or more
levels may be specified, each as a separate argument: each specified
level is added to the current set unless it is prefixed with a minus
sign in which case it is removed from the current set.  The special
option C<--> clears all currently set levels.

Supported logging levels include:

=over 4

=item request

The XML of UDDI requests is emitted.

=item response

The XML of UDDI responses is emitted.

=item requestheaders

The headers associated with the requests sent

=item responseheaders

The headers associated with the requests sent

=back 4

=cut

sub loglevel {
    my $this = shift();

    foreach my $level (@_) {
	if ($level eq "--") {
	    $this->{loglevels} = {};
	} elsif ($level =~ s/^-//) {
	    $this->{loglevels}->{$level} = 0;
	} else {
	    $this->{loglevels}->{$level} = 1;
	}
    }
}


# Logs the specified data to stderr if the relevant level is set
sub _log {
    my $this = shift();
    my($level, @message) = @_;

    my $message = join('', @message);
    $message =~ s/\n$//s;
    return if !$this->{loglevels}->{$level};

    if ($this->option("loglabel")) {
	print STDERR "_log($level) [$message]\n";
    } else {
	print STDERR "$message\n";
    }
}


# Returns a Web user-agent to be used by the UDDI object
sub _ua {
    my $this = shift();

    my $ua = $this->{ua};
    if (!defined $ua) {
	$this->{ua} = $ua = new LWP::UserAgent();
	my $proxy = $this->option("proxy");
	$ua->proxy(http => $proxy)
	    if defined $proxy;
    }

    return $ua;
}


# Returns an XML parser to be used by the UDDI object
sub _parser {
    my $this = shift();

    my $parser = $this->{parser};
    if (!defined $parser) {
	$this->{parser} = $parser = new XML::LibXML();
    }

    return $parser;
}


# If feel horrible about how this protocol selection is done, but LWP
# leaves me with no choice.  Selection is done modally via the
# installation of global protocol handlers, in code in LWP::UserAgent
# (very near the top).  That code I have copied, as it was in version
# 2.033 , into _select_http_10(); I have made the obvious derivative
# for _select_http_11().  The rest of this code invokes one or other
# of these are required before each operation, crosses its fingers and
# hopes like hell that it doesn't get called re-entrantly.

sub _select_http_10 {
    require LWP::Protocol::http10;
    LWP::Protocol::implementor('http', 'LWP::Protocol::http10');
    eval {
        require LWP::Protocol::https10;
        LWP::Protocol::implementor('https', 'LWP::Protocol::https10');
    };
}

sub _select_http_11 {
    require LWP::Protocol::http;
    LWP::Protocol::implementor('http', 'LWP::Protocol::http');
    eval {
        require LWP::Protocol::https;
        LWP::Protocol::implementor('https', 'LWP::Protocol::https');
    };
}


=head2 find_business(), find_service(), find_binding(), find_tModel()

 $rs = $uddi->find_business(name => 'frog');
 $rs = $uddi->find_business(name => 'fish',
     qualifiers => [ qw(sortByNameAsc caseSensitiveMatch) ]);
 $rs = $uddi->find_service(businessKey => "0123456789abcdef");
 $rs = $uddi->find_binding(serviceKey => "0123456789abcdef");
 $rs = $uddi->find_tModel(name => 'uddi');

These four similar methods search in the UDDI repository indicated by
C<$uddi> for businesses, services, bindings and tModels matching the
specified criteria.  These criteria consist of key-value pairs, in
which the key may be any of the following (though not all keys are
valid for all four kinds of search):

=over 4

=item name

The name, or partial name, of the business or businesses to search
for.  It exactly interpretation is specified by the qualifiers.  By
default, the name is searched for case-sensitively and for an exact
match.

=item qualifiers

A set of zero or more qualifier tokens which modify the interpretation
of C<name>, separated by spaces or commas.  The acceptable qualifiers
are:
C<andAllKeys>,
C<approximateMatch>,
C<binarySort>,
C<bindingSubset>,
C<caseInsensitiveSort>,
C<caseInsensitiveMatch>,
C<caseSensitiveSort>,
C<caseSensitiveMatch>,
C<combineCategoryBags>,
C<diacriticInsensitiveMatch>,
C<diacriticSensitiveMatch>,
C<exactMatch>,
C<signaturePresent>,
C<orAllKeys>,
C<orLikeKeys>,
C<serviceSubset>,
C<sortByNameAsc>,
C<sortByNameDesc>,
C<sortByDateAsc>,
C<sortByDateDesc>,
C<suppressProjectedServices>
and
C<UTS-10>.
The meanings of these are defined in section 5.1.4.3 of the UDDI
specification.

=item businessKey

The unique key of a business whose services are sought.  This may be
obtained from the result of an earlier C<find_business()> call using
C<$record-E<gt>xpath('@businessKey')>.

=item serviceKey

The unique key of a service whose bindings are sought.  This may be
obtained from the result of an earlier C<find_service()> call using
C<$record-E<gt>xpath('@serviceKey')>.

=item tModelBag

A bag of tModels, separated by spaces or commas.

=item identifierBag

A bag of identifiers, separated by spaces or commas.

=item categoryBag

A bag of categories, separated by spaces or commas.

=back

On success, these methods return a C<UDDI::HalfDecent::ResultSet>
object which may be further interrogated.  On failure, they throw an
exception of type C<UDDIException> describing what went wrong.

=cut

sub find_business {
    my $this = shift();
    return $this->_find('find_business', 'uddi:businessList', 'business', @_);
}


sub find_service {
    my $this = shift();
    return $this->_find('find_service', 'uddi:serviceList', 'service', @_);
}


sub find_binding {
    my $this = shift();
    return $this->_find('find_binding', 'uddi:bindingDetail', 'binding', @_);
}


sub find_tModel {
    my $this = shift();
    return $this->_find('find_tModel', 'uddi:tModelList', 'tModel', @_);
}


sub _find {
    my $this = shift();
    my($method, $wrapper, $class, @criteria) = @_;

    my $elements = "";
    my %attrs;
    while (@criteria) {
	my $key = shift @criteria;
	my $value = shift @criteria;
	oops error => "missing value", detail => $key
	    if !defined $value;

	if ($key eq "businessKey") {
	    $attrs{businessKey} = $value;
	} elsif ($key eq "serviceKey") {
	    $attrs{serviceKey} = $value;
	} elsif ($key eq "name") {
	    $elements .= "<name>" . encode_entities($value) . "</name>\n";
	} elsif ($key eq "qualifiers") {
	    $elements .= $this->_bag("findQualifiers", "findQualifier",
				     $value);
	} elsif ($key eq "tModelBag") {
	    $elements .= $this->_bag("tModelBag", "tModelKey", $value);
	} elsif ($key eq "identifierBag") {
	    $elements .= $this->_bag("identifierBag", "keyedReference", $value);
	} elsif ($key eq "categoryBag") {
	    $elements .= $this->_bag("categoryBag", "keyedReference", $value);
	} else {
	    oops error => "unknown key", detail => $key
	}
    }

    my $attrs = join('', map { " $_='" . $attrs{$_} . "'" } sort keys %attrs);
    my $namespace = $this->_uddi_namespace();
    my $xml = qq[<soap:Envelope xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'>
  <soap:Body>
    <$method xmlns='$namespace' maxRows="20" generic="2.0"$attrs>
];
    $elements =~ s/^/      /gm;
    $xml .= $elements;
    $xml .= qq[    </$method>
  </soap:Body>
</soap:Envelope>
];

    my $xpc = $this->_send_and_receive($xml);
    my($list) = $xpc->findnodes("/env:Envelope/env:Body/$wrapper");
    oops error => "no result list" if !defined $list;

    return new UDDI::HalfDecent::ResultSet($this, $xpc, $list, $class);
}


sub _bag {
    my $this = shift();
    my($outer, $inner, $value) = @_;

    oops error => "non-arrayref $outer", detail => $value
	if !ref $value || ref $value ne "ARRAY";
    my $res = "<$outer>\n";
    foreach my $entry (@$value) {
	$res .= "  <$inner>" . encode_entities($entry) . "</$inner>\n";
    }
    $res .= "</$outer>\n";
    return $res;
}


sub _send_and_receive {
    my $this = shift();
    my($postData) = @_;

    my $url = $this->{endpoint};
    my $request;
    if (defined $postData) {
	$request = HTTP::Request::Common::POST($url, Content => $postData);
    } else {
	$request = HTTP::Request::Common::GET($url);
    }
    $request->header('Content-Type' => 'text/xml; charset="utf-8"');
    $request->header(SOAPAction => '""');
    $this->_log("requestheaders", $request->headers_as_string());
    $this->_log("request", $postData);

    # Choose HTTP protocol variant in accordance with option
    my $httpver = $this->option("http-version");
    if ($httpver eq "1.1") {
	$this->_select_http_11();
    } elsif ($httpver eq "1.0") {
	$this->_select_http_10();
    } else {
	oops error => "bad http version", detail =>
	    defined $httpver ? $httpver : "[undefined]";
    }

    my $response = $this->_ua()->request($request);
    $this->_log("responseheaders", $response->status_line(), "\n",
		$response->headers_as_string());
    my $content = $response->content();
    $this->_log("response", $content);

    # We would like to fail if there is an HTTP-level message, but we
    # get HTTP 500 when there is a SOAP error, which of course
    # contains more detail that we won't see if we just refer to the
    # HTTP header.  It's not wholly clear what heuristic we should be
    # using here, but the best we can do is probably to proceed with
    # parsing if the content of the response is XML.

    my $ctype = $response->header("Content-type");
    oops error => "HTTP", detail => $response->message()
	if (!$response->is_success() &&
	    ($response->code() != 500 ||
	     $ctype !~ /^text\/xml/i ||
	     $content eq ""));

    oops error => "non-XML", detail => $ctype
	if $ctype !~ /^text\/xml/i;

    # So if we got here, we have a good XML response that is either
    # part of a "successful" response or accompanied a 500 in which
    # case it's probably a SOAP error.
    my $doc;
    eval {
	$doc = $this->_parser()->parse_string($content);
    }; if ($@) {
	oops error => "XML", detail => $@;
    }

    my %namespaces = (
	xsi => 'http://www.w3.org/2001/XMLSchema-instance',
	enc => 'http://schemas.xmlsoap.org/soap/encoding/',
	env => 'http://schemas.xmlsoap.org/soap/envelope/',
	xsd => 'http://www.w3.org/2001/XMLSchema',
	uddi => $this->_uddi_namespace(),
    );
    
    my $xpc = new XML::LibXML::XPathContext($doc->getDocumentElement());
    foreach my $prefix (keys %namespaces) {
	$xpc->registerNs($prefix, $namespaces{$prefix});
    }

    if (!$response->is_success()) {
	my($fault) = $xpc->findnodes('/env:Envelope/env:Body/env:Fault');
	my($code, $string);
	my($detail) = $xpc->findnodes('env:detail', $fault);

	# Some naughty servers omit the SOAP envelope namespace from
	# the detail of their error reports, so we need to allow for
	# them.  For example, while Microsoft's server correctly
	# namespaces faults pertaining to validation, it does not do
	# so for errors such as "unsupported find qualifier".  Nice
	# work, Microsoft!
	#warn "before: fault=$fault, detail=$detail";
	($detail) = $xpc->findnodes('detail', $fault) if !defined $detail;
	#warn "after: fault=$fault, detail=$detail";

	if (defined $detail) {
	    $code = $xpc->findvalue('//uddi:result/@errno', $detail);
	    $string = $xpc->findvalue('//uddi:errInfo', $detail);
	}

	if (!defined $code || $code eq "") {
	    $code = $fault->findvalue('faultcode');
	    $string = $fault->findvalue('faultstring');
	}

	$code ||= "UNKNOWN";	# last ditch
	oops error => $code, detail => $string;
    }

    return $xpc;
}


sub _uddi_namespace {
    my $this = shift();

    my $uddiver = $this->option("uddi-version");
    if ($uddiver eq "3") {
	return 'urn:uddi-org:api_v3';
    } elsif ($uddiver eq "2") {
	return 'urn:uddi-org:api_v2';
    } else {
	oops error => "bad uddi version", detail =>
	    defined $uddiver ? $uddiver : "[undefined]";
    }
}


=head1 ENVIRONMENT

The functioning of this module is affected by several environment
variables, all of having names beginning with C<UDDI_>:

=over 4

=item UDDI_LOG

If this is set, then it is a comma- or space-separated list of levels
to be be included in the logging output on standard error.  See the
description of the C<loglevel()> method for details.

=item UDDI_TRACE

If this is set to a true value, then when uncaught exceptions are
displayed, a full stack-trace will be included.  That is helpful for
debugging, but a bit ugly for production.

=back

=head1 SEE ALSO

C<Exception::Class>
provides the exception objects thrown by this package.

C<Net::Z3950::UDDI>
is the module that uses this, and for which it was written.

C<z2uddi> is the gateway program, built on C<Net::Z3950::UDDI>, that
is the I<raison d'etre> of this code.

C<UDDI::Lite> is supposedly a UDDI library that is part of the
C<SOAP::Lite> distribution, although I can't testify to that since I
have never seen it actually do any UDDI.

=head1 AUTHOR, COPYRIGHT AND LICENSE

As for C<Net::Z3950::UDDI>.

=cut

1;
