# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::Simple tests => 11;

use Perl6::Contexts;

use strict;
use warnings;

# 1

ok(1); # If we made it this far, we're ok.

# 2

my @bar = (1 .. 5); 
my %baz = (foo => 'bar', baz => 'quux');

my $foo;
my $t1; my $t2; my $t3;

$foo = @bar;
ok($foo->[1] == $bar[1], 'reference context - arrays part 1');

# 3

$bar[6] = @bar;
ok($bar[6]->[3] == $bar[3], 'reference context - arrays part 2');

# 4

$foo = %baz;
die unless $foo;
die unless ref $foo;
die unless keys %baz;
die unless exists $baz{baz};
ok($foo->{baz} eq $baz{baz}, 'reference context - hashes');

# 5 

@bar = (1 .. 5);
$foo = 0 + @bar;
ok($foo == 5, 'numeric context - math ops');

# 6

ok(scalar(@bar) == 5, 'numeric context - scalar keyword');

# X

# use autobox;
# use autobox::Core;
# ok(@foo->size, '5');

# 7

$foo = bjork(10, 20, @bar);
ok($foo eq "numargs 3\n", 'subroutine arguments');

# 8

$foo = blurgh->bjork(30, 40, @bar);
ok($foo eq "numargs 4\n", 'method arguments');

# 9

local $" = ' ';
# same as this, by the way: print 'foo' . join(${'"'}, @arr) . "\n";
$foo = 'foo' . @bar . "\n";
ok($foo eq "foo1 2 3 4 5\n", 'scalar context - arrays');

# 10, 11

ok(gnrash(\@bar, \@bar), 'multiple arrays as args control');
ok(gnrash(@bar, @bar), 'multiple arrays as args test');


#
# end of tests
#

sub bjork {
    return join '', "numargs ", scalar @_, "\n";
}

sub gnrash {
    ref $_[0] eq 'ARRAY' and ref $_[1] eq 'ARRAY';
}

package blurgh;

sub bjork {
    return join '', "numargs ", scalar @_, "\n";
}


