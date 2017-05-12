#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Stream::Buffered;

{
    my $b = Stream::Buffered->new(-1);
    $b->print("foo");
    is $b->size, 3;
    my $fh = $b->rewind;
    is do { local $/; <$fh> }, 'foo';
    $fh->seek(0, 0);
}

{
    local $Stream::Buffered::MaxMemoryBufferSize = 12;
    my $b = Stream::Buffered->new;
    is $b->size, 0;
    $b->print("foo") for 1..5;
    is $b->size, 15;
    my $fh = $b->rewind;
    isa_ok $fh, 'IO::File';
    is do { local $/; <$fh> }, ('foo' x 5);
}

{
    local $Stream::Buffered::MaxMemoryBufferSize = 0;
    my $b = Stream::Buffered->new(3);
    $b->print("foo\n");
    is $b->size, 4;
    my $fh = $b->rewind;
    isa_ok $fh, 'IO::File';
    is do { local $/; <$fh> }, "foo\n";
}

done_testing;
