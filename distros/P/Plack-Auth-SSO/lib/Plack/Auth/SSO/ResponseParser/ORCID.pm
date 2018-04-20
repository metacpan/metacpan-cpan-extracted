package Plack::Auth::SSO::ResponseParser::ORCID;

use strict;
use utf8;
use Data::Util qw(:check);
use JSON;
use Moo;
use Clone qw();

our $VERSION = "0.0134";

with "Plack::Auth::SSO::ResponseParser";

has json => (
    is => "ro",
    lazy => 1,
    builder => "_build_json",
    init_arg => undef
);

sub _build_json {
    JSON->new();
}

sub parse {

    my ( $self, $obj ) = @_;

    if ( is_string( $obj ) ) {

        $obj = $self->json()->decode( $obj );

    }
    else {

        $obj = Clone::clone( $obj );

    }

    my $uid  = delete $obj->{orcid};
    my $name = delete $obj->{name};

    +{
        uid => $uid,
        info => {
            name => $name
        },
        extra => $obj
    };

}

1;
