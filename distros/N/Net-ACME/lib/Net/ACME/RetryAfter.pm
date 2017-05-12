package Net::ACME::RetryAfter;

#----------------------------------------------------------------------
# A base class for modules that handle the 202 status with Retry-After
# header, as described in the ACME protocol spec.
#----------------------------------------------------------------------

use strict;
use warnings;

use Net::ACME::HTTP ();

sub new {
    my ( $class, %opts ) = @_;

    my $uri = $opts{'uri'} or do {
        die( sprintf "“%s” requires a “uri”!", __PACKAGE__ );
    };

    my $self = bless { _uri => $uri }, $class;

    if ( $opts{'retry_after'} ) {
        $self->_consume_retry_after_value( $opts{'retry_after'} );
    }

    return $self;
}

sub uri { return (shift)->{'_uri'}; }

sub is_time_to_poll {
    my ($self) = @_;

    my $earliest_time = $self->{'_next_retry_time'};

    return 1 if !$earliest_time || ( time >= $earliest_time );

    return 0;
}

sub poll {
    my ($self) = @_;

    my $resp = $self->_http_get( $self->{'_uri'} );

    if ( $resp->status() == 202 ) {
        $self->_consume_retry_after_value( $resp->header('retry-after') );
        return undef;
    }

    return scalar $self->_handle_non_202_poll($resp);
}

#https://ietf-wg-acme.github.io/acme/#certificate-issuance
sub _consume_retry_after_value {
    my ( $self, $val ) = @_;

    $self->{'_next_retry_time'} = $val && ( time + $val );

    return;
}

sub _http_get {
    my ( $self, $uri ) = @_;

    $self->{'_http'} ||= Net::ACME::HTTP->new();

    return $self->{'_http'}->get($uri);
}

1;
