package SOAP::Transport::ActiveWorks::HTTP::Proxy;
use base qw(Exporter);

BEGIN
{
	use strict;
	use vars qw($VERSION @EXPORT_OK);
	$VERSION = '0.28';

	use SOAP::Defs;
	use SOAP::Parser;
	use SOAP::EnvelopeMaker;
	use SOAP::Transport::ActiveWorks::Defs;
	use Carp;
	use Cwd;

	require SOAP::Transport::ActiveWorks::Client;

	@EXPORT_OK = qw ( http_proxy );

}

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
        

    my $soap_on_aw = SOAP::Transport::ActiveWorks::Client->new();

    my $response_content = $soap_on_aw->send_receive (
       $AW_DEFAULT_HOST,
       $AW_DEFAULT_PORT,
       $AW_DEFAULT_BROKER,
       $AW_DEFAULT_CLIENT_GROUP,
       $request_class,
       $method_uri,
       $method_name,
       $request_content
    );


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



sub http_proxy
{
my ($request_class, $headers, $body, $envelopeMaker) = @_;


	my $method_name = $body->{soap_typename};

	#
	# reconstruct the envelope
	#
	my $soap_request = '';
	my $output_fcn = sub { $soap_request .= shift; };
	my $em = SOAP::EnvelopeMaker->new ( $output_fcn );


	$em->set_body( $AW_DEFAULT_METHOD_URI, $method_name, 0, $body );

	my $soap_on_http_on_aw = SOAP::Transport::ActiveWorks::Client->new();

	my $soap_response = $soap_on_http_on_aw->send_receive (
			$AW_DEFAULT_HOST,
			$AW_DEFAULT_PORT,
			$AW_DEFAULT_BROKER,
			$AW_DEFAULT_CLIENT_GROUP,
                        $request_class,
			$AW_DEFAULT_METHOD_URI,
                        $method_name,
                        $soap_request
	);

	my $soap_parser = SOAP::Parser->new();

	$soap_parser->parsestring($soap_response);

	$reply_body = $soap_parser->get_body;

	$envelopeMaker->set_body(undef, "$method_name.response", 0, $reply_body);

}


1;

__END__

=head1 NAME

SOAP::Transport::ActiveWorks::HTTP::Proxy - Forward SOAP requests from an HTTP server to an ActiveWorks broker

=head1 SYNOPSIS

    require SOAP::Transport::HTTP::Proxy;

    my $s = SOAP::Transport::ActiveWorks::HTTP::Proxy->new();

    $s->handle_request($http_method, $request_class,
			   $request_header_reader, 
			   $request_content_reader,
			   $response_header_writer,
			   $response_content_writer,
			   $optional_dispatcher);

=head1 DESCRIPTION

SOAP::Transport::ActiveWorks::HTTP::Proxy provides a handler for use by
SOAP::Transport::ActiveWorks::HTTP::Apache for forwarding requests to
an ActiveWorks broker received via Apache or other HTTP server.  The
relationship between packages is identical to that of
SOAP::Transport::::HTTP::Apache/Server.

See
SOAP::Transport::ActiveWorks::HTTP::Apache
for intended usage.  The package also provides a subroutine for optional
usage as dispatcher.



=head2 B<http_proxy>

B< >
The subroutine http_proxy may be imported from the package to use
with SOAP::Transport::HTTP::Apache directly as an optional_dispatcher.
Optional dispatcher usage as shown below is valid with the version
of SOAP::Transport::HTTP::Apache that comes with the SOAP-AutoInvoke
package:

 package Apache::SOAPServer;
 use strict;
 use Apache;
 use SOAP::Transport::HTTP::Apache;
 use SOAP::Transport::ActiveWorks::HTTP::Proxy qw( http_proxy );

 sub handler {

     my $safe_classes ={
         ClassA       => undef,
         ClassB       => undef,
         Calculator   => \&http_proxy,
     };

     SOAP::Transport::HTTP::Apache->handler($safe_classes);

}

=head1 DEPENDENCIES

 SOAP::Defs
 SOAP::Parser
 SOAP::EnvelopeMaker
 SOAP::Transport::ActiveWorks::Defs

=head1 AUTHOR

Daniel Yacob, L<yacob@rcn.com|mailto:yacob@rcn.com>

=head1 SEE ALSO

S<perl(1). SOAP(3). SOAP::Transport::ActiveWorks::HTTP::Apache(3).>
