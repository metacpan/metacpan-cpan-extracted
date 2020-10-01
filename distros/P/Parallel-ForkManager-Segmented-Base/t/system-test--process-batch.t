#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 30;
use Path::Tiny qw/ path /;

package Serial;

use parent 'Parallel::ForkManager::Segmented::Base';

sub run
{
    my ( $self, $args ) = @_;
    return $self->serial_run( scalar( $self->process_args($args) ) );
}

package main;

{
    my $NUM    = 30;
    my $temp_d = Path::Tiny->tempdir;

    my @queue = ( 1 .. $NUM );
    my $proc  = sub {
        foreach my $fn ( @{ shift(@_) } )
        {
            $temp_d->child($fn)->spew_utf8("Wrote $fn .\n");
        }
        return;
    };
    Serial->new->run(
        {
            WITH_PM       => 0,
            items         => \@queue,
            nproc         => 3,
            batch_size    => 8,
            process_batch => $proc,
        }
    );
    foreach my $i ( 1 .. $NUM )
    {
        # TEST*30
        is( $temp_d->child($i)->slurp_utf8, "Wrote $i .\n", "file $i", );
    }
}
