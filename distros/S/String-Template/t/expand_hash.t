use strict;
use warnings;
use Test::More;
use String::Template qw(expand_hash);
use Data::Dumper;

my @TestCases =
(
    {
        Hash => 
        {
            X => '<Y>',
            Y => 1
        },
        Correct =>
        {
            X => 1,
            Y => 1
        },
        Status => 1
    },
    {
        Hash => 
        {
            X => '<Y>',
            Y => '<Z>',
            Z => 1
        },
        Correct =>
        {
            X => 1,
            Y => 1,
            Z => 1
        },
        Status => 1
    },
    {
        Hash => 
        {
            X => '<Y>',
            Y => '<Z>',
            Z => 1
        },
        Correct =>
        {
            X => '<Z>',
            Y => 1,
            Z => 1
        },
        Status => undef,
        MaxDepth => 1   
    },
    {
        Hash => 
        {
            X => '<Y>',
        },
        Correct =>
        {
            X => '<Y>'
        },
        Status => undef
    },
);

plan tests => 2 * scalar @TestCases;

foreach my $t (@TestCases)
{
    my $status = expand_hash($t->{Hash}, $t->{MaxDepth});

    is_deeply($t->{Hash}, $t->{Correct});
    is($status, $t->{Status});
}
