package SMS::Send::Orange::ContactEveryone;

use strict;
use warnings;
use Carp;
use XML::Simple qw(XMLout);
use LWP::UserAgent;
use HTTP::Request::Common;

our $VERSION = '0.01';
use base 'SMS::Send::Driver';

use constant {
    SERVICE => 'https://www.api-contact-everyone.fr.orange-business.com/ContactEveryone/services/MultiDiffusionWS',
    SOAPACTION => 'MultiDiffusionWS'
};

=head1 NAME

SMS::Send::Orange::ContactEveryone - SMS::Send driver to send messages
via ContactEveryone (www.orange-business.com/fr/produits/contact-everyone).

=head1 SYNOPSIS

  use SMS::Send;

  # Create a sender
  my $sender = SMS::Send->new('SMS::Send::Orange::ContactEveryone',
      ssl_opts => {
          verify_hostname => 0,
          SSL_verify_mode => 1,
          SSL_cert_file => "/path/to/cert.pem",
          SSL_key_file => "/path/to/cert.key"
      }
  );

  # Send a message
  my $sent = $sender->send_sms(
      text => 'This is a test message',
      to   => '+61*****20'
  );

=head1
DESCRIPTION

SMS::Send::Orange::ContactEveryone - SMS::Send driver to send messages
via ContactEveryone (www.orange-business.com/fr/produits/contact-everyone).

This is not intended to be used directly, but instead called by SMS::Send
(see synopsis above for a basic illustration, and see SMS::Send's documentation
for further information).


=head1 METHODS

=over 4

=item new

Constructor, takes argument pairs passed by SMS::Send.

=cut

sub new {
    my ($class, %args) = @_;

    #use Data::Dumper;
    #warn Data::Dumper::Dumper(\@_);
    my $userAgent = LWP::UserAgent->new(
        ssl_opts => $args{_ssl_opts}
    );

    my $self = bless { %args }, $class;
    $self->{ua} = $userAgent;

    return $self;
}

=item send_sms

Send the message - see SMS::Send for details.

=cut

sub send_sms {
    my ($self, %args) = @_;

    my $message = $self->xml_message(%args);

    my $request = HTTP::Request->new(POST => SERVICE);
    $request->header(SOAPAction => SOAPACTION);
    $request->content_type("text/xml; charset=utf-8");
    $request->content($message);
    my $response = $self->{ua}->request($request);

    if($response->code == 200) {
        return 1;
    }
    else {
        Carp::croak($response->decoded_content);
        return 0;
    }
}

=item xml_message

Build XML message to be sent to ContactEveryone.

=cut

sub xml_message {
    my ($self, %args) = @_;

    my $envelope = {
        "xmlns:SOAP-ENV" => "http://schemas.xmlsoap.org/soap/envelope/",
        "xmlns:apachesoap" => "http://xml.apache.org/xml-soap",
        "xmlns:impl" => "MultiDiffusionWS",
        "xmlns:intf" => "MultiDiffusionWS",
        "xmlns:wsdl" => "http://schemas.xmlsoap.org/wsdl/",
        "xmlns:wsdlsoap" => "http://schemas.xmlsoap.org/wsdl/soap/",
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "SOAP-ENV:Body" => [
        ]
    };

    $args{dest_name} ||= 'Unknown';
    $args{dest_forname} ||= '';

    my $profile = '<?xml version="1.0" encoding="iso-8859-1"?>
        <PROFILE_LIST>
            <PROFILE>
                <DEST_NAME>' . $args{dest_name} .'</DEST_NAME>
                <DEST_FORENAME>' . $args{dest_forname} . '</DEST_FORENAME>
                <TERMINAL_GROUP>
                    <TERMINAL>
                        <TERMINAL_NAME>personnal_mobile</TERMINAL_NAME>
                        <TERMINAL_ADDR>' . $args{to} . '</TERMINAL_ADDR>
                        <MEDIA_TYPE_GROUP>
                            <MEDIA_TYPE>sms</MEDIA_TYPE>
                        </MEDIA_TYPE_GROUP>
                    </TERMINAL>
                </TERMINAL_GROUP>
            </PROFILE>
        </PROFILE_LIST>';

    my $body = {
        "intf:sendMessage" => [
            {
                "xmlns:intf" => "MultiDiffusionWS",
                "intf:wsMessage" => [
                    {
                        "intf:resumeContent" => [ $args{text} ],
                        "intf:custId" => [ 'mediatheque_de_digne' ],
                        "intf:sendProfiles" => [ $profile ],
                        "intf:strategy" => [ 'sms' ]
                    }
                ]
            }
        ]
    };

    push @{ $envelope->{"SOAP-ENV:Body"} }, $body;

    return XMLout($envelope, RootName => "SOAP-ENV:Envelope" );
}

=back

=head1 AUTHOR

Alex Arnaud, E<lt>gg.alexarnaud@gmail.comE<gt>
