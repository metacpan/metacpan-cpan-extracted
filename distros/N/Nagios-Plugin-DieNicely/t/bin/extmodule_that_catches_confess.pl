#!/usr/bin/perl

use Nagios::Plugin::DieNicely;
use FakeModule;

my $obj = FakeModule->new();

$obj->eval_dontconfess();

print "OK";
exit 0;

1;
