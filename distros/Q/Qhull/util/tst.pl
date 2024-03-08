#! perl

use v5.10;
use strict;
use warnings;

use Log::Any::Adapter 'Stderr', log_level => 'trace';

use Qhull 'qhull';
use Path::Tiny;

my @lines = path( 'util', 'qhull.in' )->lines( { chomp => 1 } );
shift @lines for 1 .. 2;

my ( @x, @y );
for ( @lines ) {
    my ( $x, $y ) = split;
    push @x, $x;
    push @y, $y;
}

my @results = qhull(
    \@x,
    \@y,
    {
        # raw => !!1,
        trace      => !!1,
        save_input => 'qhull.in',
        qh_opts    => [
            # TI => 'util/qhull.in',
            TO => 'qhull.out',
            # 'Fx',
            # 'f',
            # 'p',
            # 'i',
            # 'o',
        ],
    },
);

use JSON::MaybeXS;
path( 'qhull.json' )->spew( JSON::MaybeXS->new( pretty => 1 )->encode( \@results ) );

