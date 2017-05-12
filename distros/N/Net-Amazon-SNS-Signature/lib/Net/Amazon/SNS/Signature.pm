package Net::Amazon::SNS::Signature;
$Net::Amazon::SNS::Signature::VERSION = '0.006';
use strict; use warnings;

use Carp;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use MIME::Base64;
use LWP::UserAgent;

=head1 NAME

Net::Amazon::SNS::Signature

=head1 DESCRIPTION

For the verification of Amazon SNS messages

=head1 USAGE

    # Will download the signature certificate from SigningCertURL attribute of $message_ref
    # use LWP::UserAgent
    my $sns_signature = Net::Amazon::SNS::Signature->new();
    if ( $sns_signature->verify( $message_ref ) ){ ... }

    # Will automatically download the certificate using your own user_agent ( supports ->get returns HTTP::Response )
    my $sns_signature = Net::Amazon::SNS::Signature->new( user_agent => $my_user_agent );
    if ( $sns_signature->verify( $message_ref ) ){ ... }

    # Provide the certificate yourself
    my $sns_signature = Net::Amazon::SNS::Signature->new()
    if ( $sns_signature->verify( $message_ref, $x509_cert ) ) { ... }

=head2 verify

Call to verify the message, C<$message_ref> is required as first parameter and should be
a hash ref, C<$x509_cert> is optional and should be a raw x509 certificate as downloaded 
from Amazon.

See L<http://docs.aws.amazon.com/sns/latest/dg/SendMessageToHttp.verify.signature.html> for
information on the content of a message

Usage:

    my $is_verified = $this->verify({
        Message         => 'My Test Message',
        MessageId       => '4d4dc071-ddbf-465d-bba8-08f81c89da64',
        Subject         => 'My subject',
        Timestamp       => '2012-06-05T04:37:04.321Z',
        TopicArn        => 'arn:aws:sns:us-east-1:123456789012:s4-MySNSTopic-1G1WEFCOXTC0P',
        Type            => 'Notification',
        Signature       => 'EXAMPLElDMXvB8r9R83tGoNn0ecwd5UjllzsvSvbItzfaMpN2nk5HVSw7XnOn',
        SigningCertURL  => 'https://sns.us-west-2.amazonaws.com/SimpleNotificationService-f3e'
    });

=cut

sub verify {
    my ( $self, $message, $cert ) = @_;

    my $signature = MIME::Base64::decode_base64($message->{Signature})
        or carp( "Signature is a required attribute of message" );
    my $string = $self->build_sign_string( $message );
    my $public_key = $cert ? $self->_key_from_cert( $cert ) :
        $self->_public_key_from_url( $message->{SigningCertURL} );

    my $rsa = Crypt::OpenSSL::RSA->new_public_key( $public_key );
    return $rsa->verify($string, $signature);
}

=head2 build_sign_string

Given a C<$message_ref> will return a formatted string ready to be signed.

Usage:

    my $sign_string = $this->build_sign_string({
        Message     => 'Hello',
        MessageId   => '12345',
        Subject     => 'I am a message',
        Timestamp   => '2016-01-20T14:37:01Z',
        TopicArn    => 'xyz123',
        Type        => 'Notification'
    });

=cut

sub build_sign_string {
    my ( $self, $message ) = @_;

    my @keys = $self->_signature_keys( $message );
    defined($message->{$_}) or carp( sprintf( "%s is required", $_ ) ) for @keys;
    return join( "\n", ( map { ( $_, $message->{$_} ) } @keys ), "" );
}

sub new {
    my ( $class, $args_ref ) = @_;
    return bless {
        defined($args_ref->{user_agent}) ? ( user_agent => $args_ref->{user_agent} ) : ()
    }, $class;
}

sub _public_key_from_url {
    my ( $self, $url ) = @_;
    my $response = $self->user_agent->get( $url );
    my $content = $response->decoded_content;
    return $self->_key_from_cert( $content );
}

sub _key_from_cert {
    my ( $self, $cert ) = @_;
    my $x509 = Crypt::OpenSSL::X509->new_from_string(
        $cert, Crypt::OpenSSL::X509::FORMAT_PEM
    );
    return $x509->pubkey;
}

sub user_agent {
    my ( $self ) = @_;
    unless ( defined( $self->{user_agent} ) ){
        $self->{user_agent} = LWP::UserAgent->new();
    }
    return $self->{user_agent};
}

sub _signature_keys {
    my ( $self, $message ) = @_;
    my @keys = qw/Message MessageId/;

    if ( $message->{Type} && $message->{Type} =~ m/\A(?:Subscription|Unsubscribe)Confirmation\z/ ){
        push @keys, qw/SubscribeURL Timestamp Token/;
    }
    else {
        push @keys, ( defined ( $message->{Subject} ) ? qw/Subject Timestamp/ : 'Timestamp' );
    }

    return @keys, qw/TopicArn Type/;
}

1;
