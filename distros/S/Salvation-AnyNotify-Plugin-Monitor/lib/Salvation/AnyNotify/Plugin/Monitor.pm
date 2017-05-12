package Salvation::AnyNotify::Plugin::Monitor;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Plugin';

use Salvation::TC ();
use Salvation::Method::Signatures;

our $VERSION = 0.01;

method start() {

    my $core = $self -> core();
    my $monitor = $core -> config() -> get( 'monitor' );

    Salvation::TC -> assert( $monitor, 'HashRef[ArrayRef[HashRef|ArrayRef]]' );

    my $daemon = $core -> daemon();

    $daemon -> enqueue( 'server' );

    while( my ( $method, $args ) = each( %$monitor ) ) {

        my $plugin = $core -> $method();

        unless( $plugin -> can( 'monitor' ) ) {

            die( "Plugin ${plugin} could not be used for monitoring" );
        }

        foreach my $node ( @$args ) {

            my @args = ();

            if( ref( $node ) eq 'HASH' ) {

                @args = %$node;

            } else {

                @args = @$node;
            }

            $daemon -> enqueue( sub { $plugin -> monitor( @args ) } );
        }
    }

    $daemon -> run();
}

1;

__END__
