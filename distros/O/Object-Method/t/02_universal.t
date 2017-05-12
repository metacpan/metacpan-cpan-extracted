#-*- cperl -*-
use strict;
use Test::More;
use UNIVERSAL::Object::Method;

my $o = bless {}, "Paper";
my $p = bless {}, "Scissor";
my $q = bless {}, "Rock";

ok $o->can("method");
ok $p->can("method");
ok $q->can("method");

$o->method("t", sub { pass('$o->t') });
$p->method("t", sub { pass('$p->t') });
$q->method("t", sub { pass('$q->t') });

$o->t;
$p->t;
$q->t;

done_testing;
