#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 30;
use Parallel::Map::Segmented ();
use Path::Tiny               qw/ path /;

{
    my $NUM    = 30;
    my $temp_d = Path::Tiny->tempdir;

    my $queue     = 1;
    my $stream_cb = sub {
        my ($args) = @_;
        my $size = $args->{size};
        return +{ items => undef(), } if $queue > $NUM;
        my $first = $queue;
        my $last  = $first + $size - 1;
        if ( $last >= $NUM )
        {
            $last = $NUM;
        }
        $queue = $last + 1;
        return +{ items => [ $first .. $last ], };
    };
    my $proc = sub {
        foreach my $fn ( @{ shift(@_) } )
        {
            $temp_d->child($fn)->spew_utf8("Wrote $fn .\n");
        }
        return;
    };
    Parallel::Map::Segmented->new->run(
        {
            WITH_PM       => 1,
            nproc         => 3,
            batch_size    => 8,
            process_batch => $proc,
            stream_cb     => $stream_cb,
        }
    );
    foreach my $i ( 1 .. $NUM )
    {
        # TEST*30
        is( $temp_d->child($i)->slurp_utf8, "Wrote $i .\n", "file $i", );
    }
}
