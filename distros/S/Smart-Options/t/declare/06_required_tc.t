use strict;
use warnings;
use Smart::Options::Declare;
use Test::More;
use Test::Exception;

{
    package Foo;
    use Smart::Options::Declare;
    sub new {
        my $class = shift;
        return bless {}, $class;
    }

    sub bar{
        opts my $self, my $x, my $y => 'Int'; # omit to set the type of $x
        return($x, $y);
    }
}

my $foo = Foo->new;

lives_and{
    @ARGV = qw(--x --y=20);
    my($x, $y) = $foo->bar;

    is $x, 1;
    is $y, 20;

    @ARGV = qw(--y=20 --x);
    ($x, $y) = $foo->bar;

    is $x, 1;
    is $y, 20;

    @ARGV = qw(--y=10);
    ($x, $y) = $foo->bar;

    ok !$x; # x is undefined
    is $y, 10;
};

throws_ok{
    @ARGV = qw(--x --y=3.14);
    $foo->bar;
} qr/Value '3\.14' invalid for option y\(Int\)/;

done_testing;
