#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/WARNING/;
use FakeModule;

my $obj = FakeModule->new();

$obj->mydie();

1;
