package Salvation::AnyNotify::Plugin::Bus;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Plugin';

use Salvation::Method::Signatures;

method notify( Str{1,} channel, Str{1,} data ) {

    my $core = $self -> core();
    my $bus = $core -> config() -> get( 'bus' );

    return $core -> $bus() -> bus_notify( $channel, $data );
}

1;

__END__
