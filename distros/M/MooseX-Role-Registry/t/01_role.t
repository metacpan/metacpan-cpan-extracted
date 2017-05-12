#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use lib 'lib';

package RegistryTest;
use Moose;
with 'MooseX::Role::Registry';

sub config_file {
    return 't/pokemon.yml';
}

sub build_registry_object {
    return 1;
}

package main;
use Test::More;

my $reg = RegistryTest->new;
ok $reg->does('MooseX::Role::Registry'), 'RegistryTest does a MooseX::Role::Registry';

my @keys = $reg->keys;
is scalar(@keys), 3, 'there are 3 objects';

my @all = $reg->all;
is scalar(@all), 3, 'there are 3 objects';

my $pokemon = $reg->get('ivysaur');
ok $pokemon, 'get() works';

ok !defined($reg->get()), 'get without arg returns undef';

done_testing();

