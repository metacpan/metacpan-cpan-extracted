#!/usr/bin/perl -w

use Test;

BEGIN { plan tests => 5 }

use Quantum::Usrn;

ok(Usrn(Usrn(0)), 0xffffffff, "not zero");
ok(Usrn(Usrn(1)), 0xfffffffe, "not one");
ok(Usrn(Usrn(0xfffffffe)), 1, "one");
ok(Usrn(Usrn(0xffffffff)), 0, "zero");

my $txt = "Just another Perl Hacker";
ok(Usrn(Usrn($txt)), ~$txt, "not text");
