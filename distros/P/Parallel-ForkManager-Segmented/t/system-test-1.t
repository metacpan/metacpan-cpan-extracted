#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 30;
use Parallel::ForkManager::Segmented ();
use Path::Tiny qw/ path /;

{
    my $NUM    = 30;
    my $temp_d = Path::Tiny->tempdir;

    my @queue = map { [$_] } 1 .. $NUM;
    my $proc = sub {
        my $fn = shift(@_)->[0];
        $temp_d->child($fn)->spew_utf8("Wrote $fn .\n");
        return;
    };
    Parallel::ForkManager::Segmented->new->run(
        {
            WITH_PM      => 1,
            items        => \@queue,
            nproc        => 3,
            batch_size   => 8,
            process_item => $proc,
        }
    );
    foreach my $i ( 1 .. $NUM )
    {
        # TEST*30
        is( $temp_d->child($i)->slurp_utf8, "Wrote $i .\n", "file $i", );
    }
}
