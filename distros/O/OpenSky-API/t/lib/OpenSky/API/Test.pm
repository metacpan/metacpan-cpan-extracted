package OpenSky::API::Test;

use strict;
use warnings;
use Carp 'confess';
use experimental qw(signatures);
no warnings 'redefine';
use OpenSky::API;
use parent 'Exporter';
our @EXPORT_OK = qw( set_response );

BEGIN {
    $ENV{OPENSKY_USERNAME} = 'test';
    $ENV{OPENSKY_PASSWORD} = 'hunter2';
}

sub OpenSky::API::_GET ( $self, $url ) {
    my $res           = Mojo::Message::Response->new;
    my $next_response = _get_response();
    $res->parse($next_response);
    return $res;
}

my $RESPONSE;

sub set_response ($response) {
    $RESPONSE = $response;
}

sub _get_response {
    if ($RESPONSE) {
        my $response = $RESPONSE;
        $RESPONSE = undef;
        return $response;
    }
    confess "No more responses";
}

1;
