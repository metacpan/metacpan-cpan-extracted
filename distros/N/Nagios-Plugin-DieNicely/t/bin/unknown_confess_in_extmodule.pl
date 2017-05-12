#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/UNKNOWN/;
use FakeModule;

my $obj = FakeModule->new();

$obj->myconfess();

1;
