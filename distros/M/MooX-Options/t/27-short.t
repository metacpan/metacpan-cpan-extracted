#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;
use Test::Trap;

{

    package TestSeveralMultipleShort;
    use Moo;
    use MooX::Options;

    option 'lololo' => ( is => 'ro', format => 'i', short => 'l|lolo' );
    option 'rororo' => ( is => 'ro', format => 'i', short => 'r|roro' );
    option 'lorimi' => ( is => 'ro', format => 'i', short => 'm|lori' );
    1;
}

SCOPE:
{
    local @ARGV = ( '--r', '1', '--l', '2', '--m', 4 );
    my $opt = TestSeveralMultipleShort->new_with_options;

    is $opt->rororo, 1, 'rororo got shortened correctly';
    is $opt->lololo, 2, 'lololo got shortened correctly';
    is $opt->lorimi, 4, 'lorimi got shortened correctly';
}

SCOPE:
{
    local @ARGV = ( '--lolo', '2', '--roro', '3', '--lori', '5' );
    my $opt = TestSeveralMultipleShort->new_with_options;

    is $opt->lololo, 2, 'lololo got shortened correctly';
    is $opt->rororo, 3, 'rororo got shortened correctly';
    is $opt->lorimi, 5, 'lorimi got shortened correctly';
}

trap {
    local @ARGV = ( '--ro', '1', '--lo', '1', '--lo', 2 );
    TestSeveralMultipleShort->new_with_options;
};

like $trap->stderr, qr/Option lo is ambiguous/,
    "Unable to abbreviate and not argv fix";

done_testing;
