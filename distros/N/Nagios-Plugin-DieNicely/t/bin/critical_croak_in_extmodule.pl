#!/usr/bin/perl

use Nagios::Plugin::DieNicely;
use FakeModule;

my $obj = FakeModule->new();

$obj->mycroak();

1;
