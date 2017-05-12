use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use Moose::Autobox;

# we need a control in the experiment
sub fact {
    my $n = shift;
    return 1 if $n < 2;
    return $n * fact($n - 1);
}

*fact2 = sub {
    my $f = shift;
    sub {
        my $n = shift;
        return 1 if $n < 2;
        return $n * $f->($n - 1);
    }
}->y;

*fact3 = sub {
    my $f = shift;
    sub {
        my $n = shift;
        return 1 if $n < 2;
        return $n * ($f->($f))->($n - 1);
    }
}->u;

is(fact(10), fact2(10), '... our factorials match');
is(fact(10), fact3()->(10), '... our factorials match');

