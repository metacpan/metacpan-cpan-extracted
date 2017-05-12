package SOAP::Client;
use base qw ( Aw::Client );


BEGIN
{
	use SOAP::Transport::ActiveWorks::Defs;
}

sub publish
{
my ($self, $request) = @_ ;


    my $event = undef;
    $event = ( $self->SUPER::publish ( $request ) )
              ? undef
              : $self->getEvent ( $AW_REQUEST_TIMEOUT );

    return ( {errorText => "NullReply"} ) if ( !$event || $event->isNullReply );

    my %hash = $event->toHash;
    $event->delete;
    $event = undef;

    \%hash;
}



package SOAP::Transport::ActiveWorks::Client;


BEGIN
{
	use strict;
	use vars qw($VERSION $ua $post);
	$VERSION = '0.10';

	use SOAP::Defs;
	use Carp;

	require Aw::Event;
}


sub new {
    my ($class) = @_;

    my $self = {
        debug_request => 0,
    };
    bless $self, $class;

    $self;
}

sub debug_request {
    my ($self) = @_;
    $self->{debug_request} = 1;
}


#
#   keep args in sync with HTTP for now
#
sub send_receive {
    my ($self, $host, $port, $broker, $client_group, $request_class, $method_uri, $method_name, $soap_request) = @_;

    $port = 6849 unless(defined($port) and $port);
	
    $ua   ||= new SOAP::Client ( "$host:$port", $broker, "", $client_group, "SOAP::Client" );
    $post ||= new Aw::Event ( $ua, "SOAP::Request");
    $post->setField ( envelope => $soap_request );

    #
    # NOTE NOTE NOTE
    # CLR prefers a semicolon here
    # clearly this needs some fixing - maybe allow client to specify SOAPAction directly?
    #
    $post->setField ( SOAPClass  => $request_class );
    $post->setField ( SOAPAction => $method_uri . '#' . $method_name );

    if ($self->{debug_request}) {
        $post->setField('DebugRequest' => '1');
    }

    #
    # TBD: content-length isn't taking into consideration CRLF translation
    #
    $post->setField (Content_Type   => 'text/xml');
    $post->setField (Content_Length => length($soap_request));
    
    my $aw_response = $ua->publish ( $post );

    # my $code    = $http_response->code();
    my $content;


    #
    # Check for Aw Errors
    #
    if ( $aw_response->{errorText} ) {
    	$content = $self->_output_soap_fault(0,
                                             'Application Faulted',
                                             "An exception fired while processing the request: $aw_response->{errorText}",
                                             # $response_header_writer, $response_content_writer);
                                             );
    }
    else {
    	$content = $aw_response->{envelope};
    }


    $content;
}



sub _output_soap_fault {
    my ($self, $faultcode, $faultstring, $result_desc,
        $response_header_writer, $response_content_writer) = @_;

    my $response_content = qq[<s:Envelope xmlns:s="$soap_namespace"><s:Body><s:Fault><faultcode>s:$faultcode</faultcode><faultstring>$faultstring</faultstring><detail>$result_desc</detail></s:Fault></s:Body></s:Envelope>];

    #
    # skip these for now
    #
    # my $response_content_length = length $response_content;

    # $response_header_writer->('Content-Type', 'text/xml');
    # $response_header_writer->('Content-Length', $response_content_length);
    # $response_content_writer->($response_content);
}


1;
__END__

=head1 NAME

SOAP::Transport::ActiveWorks::Client - Client side ActiveWorks support for SOAP/Perl

=head1 SYNOPSIS

    use SOAP::Transport::ActiveWorks::Client;

    my $soap_on_aw = SOAP::Transport::ActiveWorks::Client->new();

    my $soap_response = $soap_on_aw->send_receive (
                        $self->{_soap_host},
                        $self->{_soap_port},
                        $self->{_soap_broker},
                        $self->{_soap_client_group},
			$self->{_soap_class},
                        $self->{_soap_method_uri},
                        $method_name,
                        $soap_request
    );

=head1 DESCRIPTION

SOAP::Transport::ActiveWorks::Client provides a client class with the single
method "send_receive" to deliver a SOAP formatted request to a SOAP adapter
connected to an ActiveWorks broker.

The ActiveWorks SOAP client is the direct analog to the HTTP Client.  The
primary difference is that the "endpoint" is split into fields specifying
the "broker" and "client_group" to connect to.  These attributes may be
set when the client object is instantiated or at any time afterwards.  Not
specifiying a values defaults to the settings in SOAP::Transport::ActiveWorks::Defs.


=head1 DEPENDENCIES

 Aw::Client
 SOAP-0.28
 SOAP::Defs
 SOAP::Transport::ActiveWorks::Defs;

=head1 AUTHOR

Daniel Yacob, L<yacob@rcn.com|mailto:yacob@rcn.com>

=head1 SEE ALSO

S<perl(1). SOAP(3). SOAP::Transport::ActiveWorks::Server(3).>
