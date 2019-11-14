package Plack::Auth::SSO::ResponseParser::ORCID;

use strict;
use utf8;
use Data::Util qw(:check);
use JSON;
use Moo;
use Clone qw();

our $VERSION = "0.0137";

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

sub dig {

    my( $hash, @keys ) = @_;

    while( my $key = shift(@keys) ){
        return unless exists $hash->{$key};
        return $hash->{$key} if scalar(@keys) == 0;
        $hash = $hash->{$key};
        return unless is_hash_ref($hash);
    }

    return;
}

sub parse {

    my ( $self, $obj, $obj2 ) = @_;

    if ( is_string( $obj ) ) {

        $obj = $self->json()->decode( $obj );

    }
    else {

        $obj = Clone::clone( $obj );

    }

    if ( is_string( $obj2 ) ) {

        $obj2 = $self->json()->decode( $obj2 );

    }
    else {

        $obj2 = Clone::clone( $obj2 );

    }

    my $uid  = delete $obj->{orcid};
    my $name = delete $obj->{name};

    my $info = +{ name => $name };
    $info->{first_name} = dig( $obj2, "name","given-names","value" );
    $info->{last_name} = dig( $obj2, "name", "family-name", "value" );
    $info->{other_names} = [ grep { defined($_) } map { dig( $_, "content" ); } @{ dig( $obj2, "other-names", "other-name" ) || [] } ];
    $info->{description} = dig( $obj2, "biography", "content" );
    $info->{location} = [ grep { defined($_) } map { dig($_,"country","value") } @{ dig( $obj2, "addresses", "address" ) || [] } ]->[0];
    $info->{email} = [ map { $_->{email} } grep { $_->{verified} && $_->{primary} } @{ dig( $obj2, "emails", "email" ) || [] } ]->[0];
    $info->{urls} = [ map { +{ $_->{"url-name"} => dig($_,"url","value") }  } @{ dig( $obj2, "researcher-urls", "researcher-url" ) || [] } ];
    $info->{external_identifiers} = [ map { +{
        type => $_->{"external-id-type"},
        value => $_->{"external-id-value"},
        url => dig($_,"external-id-url","value")
    } } @{ dig( $obj2, "external-identifiers", "external-identifier" ) || [] } ];

    +{
        uid => $uid,
        info => $info,
        extra => { %$obj2, %$obj }
    };

}

1;
