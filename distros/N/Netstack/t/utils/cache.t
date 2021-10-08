#!/usr/bin/env perl

use strict;
use warnings;
use 5.016;
use Test::Simple tests => 5;
use Mojo::Util qw(dumper);

use Netstack::Utils::Cache;

my $cache;

ok(
  do {
    eval { $cache = new Netstack::Utils::Cache };
    warn $@ if $@;
    $cache->isa('Netstack::Utils::Cache');
  },
  ' 生成 Netstack::Utils::Cache 对象'
);

ok(
  do {
    eval { $cache = Netstack::Utils::Cache->new( cache => {lala => {lele => {lili => {lolo => 'lulu'}}}} ); };
    warn $@ if $@;
    $cache->locate(qw/lala lele lili/)->{lolo} eq 'lulu';
  },
  ' locate'
);

ok(
  do {
    eval { $cache = Netstack::Utils::Cache->new( cache => {lala => {lele => {lili => {lolo => 'lulu'}}}} ); };
    warn $@ if $@;
    $cache->get(qw/lala lele lili/)->{lolo} eq 'lulu';
  },
  ' get'
);

ok(
  do {
    eval { $cache = Netstack::Utils::Cache->new( cache => {lala => {lele => {lili => {lolo => 'lulu'}}}} ); };
    warn $@ if $@;
    $cache->clear(qw/lala lele lili lolo/);
    my $ref = $cache->get(qw/lala lele lili/);
    defined $ref and not exists $ref->{lolo};
  },
  ' locate'
);

ok(
  do {
    eval { $cache = Netstack::Utils::Cache->new( cache => {lala => {lele => {lili => {lolo => 'lulu'}}}} ); };
    warn $@ if $@;
    $cache->set(qw/lala lele lili 2/);
    $cache->get(qw/lala lele lili/) eq '2';
    say dumper $cache;
  },
  ' set'
);
