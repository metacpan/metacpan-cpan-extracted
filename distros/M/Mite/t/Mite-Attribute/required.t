#!/usr/bin/perl

use lib 't/lib';

use Test::Mite;

tests "required" => sub {
    mite_load <<'CODE';
package MyTest;
use Mite::Shim;
has foo =>
    is => 'rw',
    required => 1;
has bar =>
    is => 'rw',
    required => 0;
1;
CODE

    my $o = MyTest->new( foo => 99, bar => 66 );
    is $o->foo, 99;
    is $o->bar, 66;

    local $@;
    my $o2 = eval { MyTest->new( bar => 66 ); };
    my $e = $@;
    like $e, qr/^Missing key in constructor: foo/;

    my $o3 = MyTest->new( foo => 42 );
    is $o3->foo, 42;
};

done_testing;
