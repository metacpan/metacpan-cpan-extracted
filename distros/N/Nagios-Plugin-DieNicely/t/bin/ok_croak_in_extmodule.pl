#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/OK/;
use FakeModule;

my $obj = FakeModule->new();

$obj->mycroak();

1;
