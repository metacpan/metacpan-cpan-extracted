package SOAP::Transport::HTTP::Server;

use strict;
use vars qw($VERSION);
$VERSION = '0.28';

use SOAP::Defs;
use SOAP::Parser;
use SOAP::EnvelopeMaker;
use Carp;
use Cwd;

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub handle_request {
    my ($self, $http_method, 
               $request_class,
               $request_header_reader, 
               $request_content_reader, 
               $response_header_writer,
               $response_content_writer,
               $optional_dispatcher) = @_;

    my $request_content_type   = $request_header_reader->('Content-Type', 1);
    my $request_content_length = $request_header_reader->('Content-Length', 1);
    my $soap_method_name       = $request_header_reader->('SOAPAction', 0);
    my $debug_request          = $request_header_reader->('DebugRequest', 0);

    my $request_content;
    $request_content_reader->($request_content, $request_content_length);

    if ($debug_request) {
	$response_header_writer->('Content-type', 'text/xml');
	my $cwd = cwd();
	$response_content_writer->("<cwd>$cwd</cwd>");
	$response_content_writer->("<HttpMethod>$http_method</HttpMethod>");
	$response_content_writer->("<SOAPAction>$soap_method_name</SOAPAction>");
	$response_content_writer->("<RequestContentLength>$request_content_length</RequestContentLength>");
	$response_content_writer->("<ContentType>$request_content_type</ContentType>");
	$response_content_writer->("<EchoedRequest>$request_content</EchoedRequest>");
	return;
    }
    unless ('text/xml' eq $request_content_type) { 
    return $self->_output_soap_fault($soap_fc_client,
                     'Bad Request', 
                     'Content-Type must be text/xml.',
                     $response_header_writer, $response_content_writer);
    }
    unless ($soap_method_name) {
    return $self->_output_soap_fault($soap_fc_client,
                     'Bad Request',
                     'SOAPAction is required.',
                     $response_header_writer, $response_content_writer);
    }

    unless ($soap_method_name =~ /(^\S+)#(\S+$)/) {
        return $self->_output_soap_fault($soap_fc_client,
                     'Bad Request',
                     "Unrecognized SOAPAction header: $soap_method_name",
                     $response_header_writer, $response_content_writer);
    }
    my ($method_uri, $method_name) = ($1, $2);
        
    #
    # TBD: deal with content-length and cr/lf issues...
    # TBD: add M-POST support
    #

    #
    # Unmarshal the request object
    #
    # TBD: eventually I want to experiment with XML::Parser::ExpatNB to see
    #      if I can avoid buffering the entire request in a string.
    #      For now, I want to ship *something* that works correctly though.
    #      As another option, I wonder if there's a way I can call parsefile
    #      passing in a filehandle - if mod_perl would give me a file handle
    #      then there'd be no double-buffering at all!
    #
    my $headers;
    my $body;
    eval {
        my $soap_parser = SOAP::Parser->new();
        $soap_parser->parsestring($request_content);
        $headers = $soap_parser->get_headers();
        $body    = $soap_parser->get_body();
    };
    if ($@) {
        return $self->_output_soap_fault($soap_fc_server,
                     'Application Faulted',
                     "Failed while unmarshaling the request: $@",
                     $response_header_writer, $response_content_writer);
    }

    my $response_content = '';
    if ($optional_dispatcher) {
        #
        # call the custom dispatch routine
        #
        eval {
            my $em = SOAP::EnvelopeMaker->new(sub { $response_content .= shift });
            $optional_dispatcher->($request_class, $headers, $body, $em);
        };
        if ($@) {
            return $self->_output_soap_fault($soap_fc_server,
                                             'Application Faulted',
                                             "An exception fired while processing the request: $@",
                                             $response_header_writer, $response_content_writer);
        }
    }
    else {
        #
        # Load the requested class
        #
        eval "require $request_class";
        if ($@) {
            return $self->_output_soap_fault($soap_fc_server,
                                             'Application Faulted',
                                             "Failed to load Perl module $request_class: $@",
                                             $response_header_writer, $response_content_writer);
        }
        #
        # dispatch the request and marshal the response
        #
        eval {
            my $server_object = $request_class->new();
            my $em = SOAP::EnvelopeMaker->new(sub { $response_content .= shift });
            $server_object->handle_request($headers, $body, $em);
        };
        if ($@) {
            return $self->_output_soap_fault($soap_fc_server,
                                             'Application Faulted',
                                             "An exception fired while processing the request: $@",
                                             $response_header_writer, $response_content_writer);
        }
    }
    #
    # send the response
    #
    my $response_content_length = length($response_content);

    $response_header_writer->('Content-Type', 'text/xml');
    $response_header_writer->('Content-Length', $response_content_length);
    $response_content_writer->($response_content);
}

sub _output_soap_fault {
    my ($self, $faultcode, $faultstring, $result_desc,
        $response_header_writer, $response_content_writer) = @_;

    my $response_content = qq[<s:Envelope xmlns:s="$soap_namespace"><s:Body><s:Fault><faultcode>s:$faultcode</faultcode><faultstring>$faultstring</faultstring><detail>$result_desc</detail></s:Fault></s:Body></s:Envelope>];

    my $response_content_length = length $response_content;

    $response_header_writer->('Content-Type', 'text/xml');
    $response_header_writer->('Content-Length', $response_content_length);
    $response_content_writer->($response_content);
}

1;

__END__

=head1 NAME

SOAP::Transport::HTTP::Server - Server side HTTP support for SOAP/Perl

=head1 SYNOPSIS

    use SOAP::Transport::HTTP::Server;

=head1 DESCRIPTION

This class provides all the HTTP related smarts for a SOAP server,
independent of what web server it's attached to. It exposes
a single function (that you'll never call, unless you're adapting
SOAP/Perl to a new web server environment) that provides a set
of function pointers for doing various things, like getting
information about the request and sending response headers
and content.

What *is* important to know about this class is what it expects
of you if you want to handle SOAP requests. You must implement
your class such that it can be created via new() with no
arguments, and you must implement a single function:

=head2 handle_request(HeaderArray, Body, EnvelopeMaker)

The first two arguments are the input, an array of header objects
(which may be empty if no headers were sent), a single Body object,
and a third object to allow you to send a response.

See EnvelopeMaker to learn how to send a response (this is the
same class used by a client to send the request, so if you know
how to do that, you're cooking with gas).

HeaderArray and Body are today simply hash references, but in the
future, they may be blessed object references.

If you want to customize this call-dispatching mechanism, you
may pass a code reference for the OptionalDispatcher argument.

The OptionalDispatcher argument allows you to override the default
dispatching behavior with your own code. This should reference a
subroutine with the following signature:

=head2 custom_dispatcher(RequestedClass, HeaderArray, Body, EnvelopeMaker)

sub my_dispatcher {
    my ($requested_class, $headers, $body, $em) = @_;

    # here's a simple example that converts the request
    # into a method call (it doesn't deal with headers though)
    my $method_name = $body->{soap_typename};
    require $requested_class . '.pm';
    my $retval = $requested_class->$method_name(%$body);
    $em->set_body($body->{soap_typeuri}, $method_name . 'Response',
		  0, {return => $retval});
}

The above example handles each request by invoking a class-level method
on the requested class.

=head1 DEPENDENCIES

SOAP::Defs
SOAP::Parser
SOAP::EnvelopeMaker

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::Transport::HTTP::EnvelopeMaker
SOAP::Transport::HTTP::Apache

=cut
