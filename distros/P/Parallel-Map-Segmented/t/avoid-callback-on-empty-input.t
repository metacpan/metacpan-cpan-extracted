#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Parallel::Map::Segmented ();
use Path::Tiny qw/ path /;

{
    my $temp_d = Path::Tiny->tempdir;

    my @queue;
    my $proc = sub {
        my $fn = shift(@_)->[0];
        $temp_d->child($fn)->spew_utf8("Wrote $fn .\n");
        return;
    };
    Parallel::Map::Segmented->new->run(
        {
            WITH_PM      => 1,
            items        => \@queue,
            nproc        => 4,
            batch_size   => 8,
            process_item => $proc,
        }
    );

    # TEST
    pass("Did not err - success!");
}
