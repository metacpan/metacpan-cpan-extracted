#
#
# vim: syntax=perl

use warnings;
use strict;

use Test::More tests => 5;

BEGIN {
    use_ok 'POE';
    use_ok 'Sprocket';
}

POE::Session->create( inline_states => {
    _start => sub {
        $poe_kernel->delay( shutdown => 5 => 1 );
        $poe_kernel->alias_set( 'test' );
        my $cb = $_[HEAP]->{cb} = [];
        push( @$cb, $sprocket->callback( $_[SESSION] => test => 1 ) );
        push( @$cb, $sprocket->callback( $_[SESSION]->ID() => test => 1 ) );
        push( @$cb, $sprocket->callback( test => test => 1 ) );
        $poe_kernel->yield( 'do_callback' );
    },
    do_callback => sub {
        my $cb = shift @{$_[HEAP]->{cb}};
        return unless $cb;
        $cb->( 2 );
        $poe_kernel->yield( 'do_callback' );
    },
    test => sub {
        my ( $h, $one, $two ) = @_[ HEAP, ARG0, ARG1 ];
        $h->{t}++;
        if ( $one == 1 && $two == 2 ) {
            Test::More::pass("callback params are ok for callback $h->{t}");
        } else {
            Test::More::fail("callback params are wrong for callback $h->{t}");
        }
        $poe_kernel->yield( 'shutdown' )
            if ( $h->{t} == 3 );
    },
    shutdown => sub {
        my $failed = $_[ ARG0 ];
        Test::More::fail("test failed")
            if ( $failed );
        $poe_kernel->alias_remove( 'test' );
        $poe_kernel->alarm_remove_all();
        delete $_[HEAP]->{cb};
        return;
    },
} );

$poe_kernel->run();

