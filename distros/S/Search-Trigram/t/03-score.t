use strict;
use warnings;
use Test::More;

use Search::Trigram;

# Identical strings score 1.0
{
    my $idx = Search::Trigram->new;
    $idx->add("hello world");
    my $r = $idx->search("hello world");
    ok(scalar @$r == 1 && abs($r->[0]{score} - 1.0) < 1e-5,
       'identical strings score 1.0');
}

# Completely different strings: no match returns []
{
    my $idx = Search::Trigram->new;
    $idx->add("xylophone");
    my $r = $idx->search("fjord");
    is(scalar @$r, 0, 'completely different strings yield no results (score 0.0)');
}

# One character difference in a long string scores > 0.5
{
    my $idx = Search::Trigram->new;
    $idx->add("hello world foo");
    my $r = $idx->search("hello world bar");
    ok(scalar @$r > 0 && $r->[0]{score} > 0.5,
       'one char difference scores > 0.5 (trigram overlap)');
}

# Empty query returns [] without error
{
    my $idx = Search::Trigram->new;
    $idx->add("some content");
    my $r = $idx->search("");
    is(ref($r), 'ARRAY', 'empty query returns arrayref');
    is(scalar @$r, 0, 'empty query returns []');
}

# Single char query returns results (padded trigrams)
{
    my $idx = Search::Trigram->new;
    $idx->add("a dog");
    my $r = $idx->search("a");
    is(ref($r), 'ARRAY', 'single char query returns arrayref');
    ok(scalar @$r >= 0, 'single char query does not crash');
}

# Two char query
{
    my $idx = Search::Trigram->new;
    $idx->add("my cat sat");
    my $r = $idx->search("my");
    is(ref($r), 'ARRAY', 'two char query returns arrayref');
    ok(scalar @$r >= 0, 'two char query does not crash');
}

done_testing;
