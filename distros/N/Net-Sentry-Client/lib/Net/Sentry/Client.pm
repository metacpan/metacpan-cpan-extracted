package Net::Sentry::Client;


use strict;
use warnings;

use HTTP::Request::Common;
use LWP::UserAgent;
use JSON ();
use Data::UUID::MT ();
use MIME::Base64 'encode_base64';
use Compress::Zlib;
use Time::HiRes (qw(gettimeofday));
use DateTime;
use Digest::HMAC_SHA1 qw( hmac_sha1_hex );

use Carp;
use Sys::Hostname;

# Constructor 
sub new {
    my ( $class, %options ) = @_;
 
    if (! exists $options{sentry_key}) {
        die "Mandatory paramter 'sentry_key' not defined";
    }
    
    if (! exists $options{remote_url}) {
        die "Mandatory paramter 'remote_url' not defined";
    }

    my $self = {
        sentry_version      => 0,
        ua                  => LWP::UserAgent->new(),
        %options,
    };

    bless $self, $class;
}

# Send our message to the sentry server/servers
sub send {
    my ( $self, $params ) = @_;
    
    my $ua = $self->{ua};
    my $uri = $self->{remote_url};
    my $message = $self->_getMessage( $params );
    my $stamp = gettimeofday();
    $stamp = sprintf ( "%.12g", $stamp );
    my %header = $self->_getAuthHeader( $stamp, $message );
    my $request = $ua->post( $uri, %header, Content => $message );
    return $request;
}

# From outside message, we make a json message for server.
sub _getMessage {
    my ( $self, $params ) = @_;
 
    my $data = { 
                    message             => $params->{message}, 
                    timestamp           => time(), 
                    level               => $params->{level}||20,
                    message_id          => Data::UUID::MT->new->create_hex(),
                    logger              => $params->{logger}||'root',
                    view                => $params->{view}||undef,
                    server_name         => $params->{server_name}||hostname,
                    url                 => $params->{url}||undef,
                    site                => $params->{site}||undef,
                    data                => $params->{data}||undef,
                    traceback           => $params->{traceback}||undef,
    };
    my $json = JSON->new->utf8(1)->pretty(1)->allow_nonref(1)->encode( $data );
    
    return encode_base64(compress( $json ));
}

# Make signature which is required for the sentry server
sub _getSignature {
    my ( $self, $stamp, $message ) = @_;
    return hmac_sha1_hex( "$stamp $message", $self->{sentry_key} );
}

# Make the specific header
sub _getAuthHeader {
    my ( $self, $stamp, $message ) = @_;
    my $header_format = sprintf ( 
            "Sentry sentry_signature=%s ,sentry_timestamp=%s ,sentry_client=%s",
            $self->_getSignature( $stamp, $message ),
            $stamp,
            $self->{sentry_version}
        );
    my %header = ( 'Authorization' => $header_format, 'Content-Type' => 'application/octet-stream' );
    
    return %header;
}

1;

__END__

=pod

=head1 NAME

Net::Sentry::Client

=head1 VERSION

version 0.001

=head1 NAME

Net::Sentry::Client - a client for a Sentry server.

=head1 VERSION

version 0.001

=head1 SEE ALSO

http://sentry.readthedocs.org/en/latest/index.html

=head1 AUTHOR

Fran Rodriguez <kio@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Fran Rodriguez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
