#!/usr/bin/env perl

use Test::More tests => 2;

use MojoX::Run;
use Scalar::Util qw(refaddr);

my $a = MojoX::Run->new();
my $b = MojoX::Run->new();

ok $a == $b, "Singleton test 1";
ok refaddr($a) eq refaddr($b), "Singleton test 2";
