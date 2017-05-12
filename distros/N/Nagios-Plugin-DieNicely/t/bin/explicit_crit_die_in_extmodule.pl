#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/CRITICAL/;
use FakeModule;

my $obj = FakeModule->new();

$obj->mydie();

1;
