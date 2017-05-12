#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name       => 'SNMP::Agent',
  license           => 'perl',
  dist_author       => 'Alexander Else <aelse@else.id.au>',
  dist_version_from => 'lib/SNMP/Agent.pm',
  build_requires    => {
    'Test::More'     => 0,
    'NetSNMP::agent' => 0,
    'NetSNMP::ASN'   => 0,
  },
  requires          => {
    'NetSNMP::agent' => 0,
    'NetSNMP::ASN'   => 0,
  },
  add_to_cleanup => ['SNMP-Agent-*'],
);

$builder->create_build_script;
