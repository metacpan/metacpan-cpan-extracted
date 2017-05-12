#!/usr/bin/perl

use Nagios::Plugin::DieNicely;
use FakeModule;

my $obj = FakeModule->new();

$obj->myconfess();

1;
