#!/usr/bin/perl

use Nagios::Plugin::DieNicely;
use FakeModule;

my $obj = FakeModule->new();

$obj->eval_dontcroak();

print "OK";
exit 0;

1;
