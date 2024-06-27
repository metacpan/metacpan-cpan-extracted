#! /usr/bin/env perl

use v5.22;
use warnings;

use Multi::Dispatch;

package Iterator {
    multimethod new :common (%args) {
        bless {from=>0, step=>1, %args, next=>$args{from}}, $class;
    }

    multimethod next () {
        return if $self->{next} > $self->{to};
        (my $curr, $self->{next}) = ($self->{next}, $self->{next} + $self->{step});
        return $curr;
    }

    multimethod seq :common ($to) {
        $class->new(from=>0, to=>$to-1);
    }

    multimethod seq :common ($from, $to) {
        $class->new(from=>$from, to=>$to);
    }

    multimethod seq :common ($from, $then, $to) {
        $class->new(from=>$from, to=>$to, step=>$then-$from);
    }
}

my $iter;

$iter = Iterator->seq(10);
while (defined(my $next = $iter->next)) {
    print "$next, ";
}
say '<undef>';

$iter = Iterator->seq(1 => 10);
while (defined(my $next = $iter->next)) {
    print "$next, ";
}
say '<undef>';


$iter = Iterator->seq(1, 3 => 10);
while (defined(my $next = $iter->next)) {
    print "$next, ";
}
say '<undef>';

