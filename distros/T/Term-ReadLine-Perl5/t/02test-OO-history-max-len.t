#!/usr/bin/env perl
use strict; use warnings;
use lib '../lib' ;
use utf8;
use Test::More;
use Term::ReadLine::Perl5::OO;

my $c = Term::ReadLine::Perl5::OO->new(rl_MaxHistorySize => 5);
for (1..5) {
    $c->add_history($_);
}
is_deeply($c->history, [1,2,3,4,5], 'add_history five times');

done_testing;
