#!/usr/bin/perl

use Nagios::Plugin::DieNicely;
use FakeModule;

my $obj = FakeModule->new();

$obj->eval_dontdie();

print "OK";
exit 0;

1;
