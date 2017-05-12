use strict;
use warnings;
use Test::More 0.88;

use Sub::Sequence;

can_ok 'Sub::Sequence', qw/seq/;

#--- 1 step
{
    my $result = seq [qw/1 2 3/], 1, sub {
        my @list = @{ shift; };
        \@list;
    };
    is_deeply $result, [ [1], [2], [3] ], '1: first arg';
}
{
    my $result = seq [qw/1 2 3/], 1, sub { $_[1]; };
    is_deeply $result, [1, 2, 3], '1: second arg';
}
{
    my $result = seq [qw/1 2 3/], 1, sub { $_[2]; };
    is_deeply $result, [0, 1, 2], '1: third arg';
}

#--- 2 step
{
    my $result = seq [qw/1 2 3 4 5/], 2, sub {
        my @list = @{ shift; };
        \@list;
    };
    is_deeply $result, [ [1, 2], [3, 4], [5] ], '2: first arg';
}
{
    my $result = seq [qw/1 2 3 4 5/], 2, sub { $_[1]; };
    is_deeply $result, [1, 2, 3], '2: second arg';
}
{
    my $result = seq [qw/1 2 3 4 5/], 2, sub { $_[2]; };
    is_deeply $result, [0, 2, 4], '2: third arg';
}

#--- 3 step
{
    my $result = seq [qw/1 2 3 4 5/], 3, sub {
        my @list = @{ shift; };
        \@list;
    };
    is_deeply $result, [ [1, 2, 3], [4, 5] ], '3: first arg';
}
{
    my $result = seq [qw/1 2 3 4 5/], 3, sub { $_[1]; };
    is_deeply $result, [1, 2], '3: second arg';
}
{
    my $result = seq [qw/1 2 3 4 5/], 3, sub { $_[2]; };
    is_deeply $result, [0, 3], '3: third arg';
}

#--- over step
{
    my $result = seq [qw/1 2 3/], 5, sub {
        my @list = @{ shift; };
        \@list;
    };
    is_deeply $result, [ [1, 2, 3] ], 'over: first arg';
}
{
    my $result = seq [qw/1 2 3/], 5, sub { $_[1]; };
    is_deeply $result, [1], 'over: second arg';
}
{
    my $result = seq [qw/1 2 3/], 5, sub { $_[2]; };
    is_deeply $result, [0], 'over: third arg';
}

#--- wantarray result
{
    my @result = seq [qw/1 2 3 4 5/], 3, sub {
        my @list = @{ shift; };
        \@list;
    };
    is_deeply \@result, [ 1, 2, 3, 4, 5 ], 'wantarray';
}

done_testing;
