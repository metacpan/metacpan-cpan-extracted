package Salvation::AnyNotify::Plugin::Graphite::Reader;

use strict;
use warnings;

use MIME::Base64 'encode_base64';
use HTTP::Headers ();
use LWP::UserAgent ();

use Moose;

extends 'Net::Graphite::Reader';


has 'furl' => (
  is      => 'ro',
  isa     => 'LWP::UserAgent',
  lazy    => 1,
  builder => '_build_furl',
);

sub _build_furl {

    my ( $self ) = @_;
    my %parms = ( timeout => 120 );

    if( $self -> _has_username() || $self -> _has_password() ) {

        $parms{ 'default_headers' } = [
            Authorization => sprintf( 'Basic %s', encode_base64( join( ':',
                ( $self -> _has_username() ? $self -> username() : '' ),
                ( $self -> _has_password() ? $self -> password() : '' ),
            ) ) ),
        ];
    }

    if( exists $parms{ 'default_headers' } ) {

        $parms{ 'default_headers' } = HTTP::Headers -> new(
            @{ $parms{ 'default_headers' } },
        );
    }

    return LWP::UserAgent -> new( %parms );
}


no Moose;

1;

__END__
