#!/usr/bin/perl

use lib 't/lib';

use Test::Mite;

tests "strict_contructor" => sub {
    mite_load <<'CODE';
package MyTest;
use Mite::Shim;
has foo =>
    is => 'rw',
    init_arg => 'bar',
    default => 99;
has bar =>
    is => 'rw',
    init_arg => undef;
1;
CODE

    my $o = MyTest->new;
    is $o->foo, 99;

    my $o2 = MyTest->new( bar => 66 );
    is $o2->foo, 66;
    is $o2->bar, undef;
};

done_testing;
