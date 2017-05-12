use strict;
use warnings;
use Test::More tests => 8;
use Sub::Become qw( become );

sub foo {
    become {
        return 99;
    };
    return 1;
}

is foo(), 1,  'foo: before';
is foo(), 99, 'foo: after';
is foo(), 99, 'foo: stable';

sub bar {
    return ( become { return 'grapes' } )->();
}

is bar(), 'grapes', 'bar: grapes';
is bar(), 'grapes', 'bar: still grapes';

sub blirk {
    my @args = @_;
    become {
        my @args = @_;
        return reverse @args;
    };
    return @args;
}

is_deeply [ blirk( 1, 2, 3 ) ], [ 1, 2, 3 ], 'blirk: before';
is_deeply [ blirk( 1, 2, 3 ) ], [ 3, 2, 1 ], 'blirk: after';
is_deeply [ blirk( 1, 2, 3, 4 ) ], [ 4, 3, 2, 1 ], 'blirk: stable';
