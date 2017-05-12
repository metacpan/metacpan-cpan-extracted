#!/usr/bin/env perl -w
use strict;
use Test::More tests => 6;
use Perl6ish::Syntax::state;

sub counter {
    state $n = 0;

    $n++;
    return $n;
}

is counter(), 1;
is counter(), 2;
is counter(), 3;

sub counter2 {
    state $n = 10;

    $n++;
    return $n;
}
is counter2(), 11;
is counter2(), 12;
is counter2(), 13;

# XXX: make this work...
# sub popu {
#     state @q = ();
#     # state2(my @q, ());
#     my $op = shift || 'push';
#     if ($op eq 'pop') { return pop @q; }
#     else { push @q, @_; }
# }
# popu(push => "O");
# popu(push => "HAI");
# popu(push => "BRO");
# is popu('pop'), "BRO";
# is popu('pop'), "HAI";
# is popu('pop'), "O";
