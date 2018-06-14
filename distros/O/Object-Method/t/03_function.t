#-*- cperl -*-
use strict;
use Test::More;
use Object::Method;

my $o = bless {}, "Paper";
my $p = bless {}, "Scissor";
my $q = bless {}, "Rock";

method($o, "t", sub { pass('$o->t') });
method($p, "t", sub { pass('$p->t') });
method($q, "t", sub { pass('$q->t') });

$o->t;
$p->t;
$q->t;

done_testing;
