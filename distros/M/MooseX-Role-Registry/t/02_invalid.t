#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use lib 'lib';

package RegistryTest;
use Moose;
with 'MooseX::Role::Registry';

sub config_file {
    return 't/invalid.yml';
}

sub build_registry_object {
    return 1;
}

package main;
use Test::More;
use Test::Exception;

my $reg;

throws_ok { $reg = RegistryTest->new; } qr/Invalid entry/, 'Invalid entry';

done_testing();

