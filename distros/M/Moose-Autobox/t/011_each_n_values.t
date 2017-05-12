use strict;
use warnings;
use Test::More;

use Moose::Autobox;

{
    my @array = ('a' .. 'z');

    my $aref = [ @array ];

    {
        my @vals;
        @array->each_n_values(2, sub { push @vals, [@_] });
        is(scalar @vals, 13);
        is(scalar @$_, 2) for @vals;
        is_deeply(@vals->map(sub { @{ $_ } }), [@array]);
    }

    {
        my @vals;
        $aref->each_n_values(2, sub { push @vals, [@_] });
        is(scalar @vals, 13);
        is(scalar @$_, 2) for @vals;
        is_deeply(@vals->map(sub { @{ $_ } }), $aref);
    }
}

{
    my %hash = (a => 1, b => 2, c => 3, d => 4);

    my $href = { %hash };

    {
        my @vals;
        %hash->each_n_values(2, sub { push @vals, [@_] });
        my %seen;
        is(@vals, 2);
        for my $pair (@vals) { $seen{$_}++ for @$pair }
        is_deeply(\%seen, { 1,1,2,1,3,1,4,1 });
    }

    {
        my @vals;
        $href->each_n_values(2, sub { push @vals, [@_] });
        my %seen;
        is(@vals, 2);
        for my $pair (@vals) { $seen{$_}++ for @$pair }
        is_deeply(\%seen, { 1,1,2,1,3,1,4,1 });
    }
}

done_testing;
