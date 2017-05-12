#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 1;

use Data::Dumper;

chdir 'lib';
use_ok 'Template::Plugin::deJSON';

my @strings = (
  '{"hello":"there","more":{"id":"20","inside":"yes","nested":{"id":"21","here":"there"}},"outside":"noone","id":"10","separate":{"id":"234","us":"alone"}}',
  '{"hello":"there","more":{"id":"20","inside":"yes","nested":{"id":"21","reallynested":{"id":"4444","deep":"well"},"here":"there"}},"outside":"noone","id":"10","separate":{"id":"234","us":"alone"}}',
  '{"hello":"goodbye","id":"99","info":{"id":"30","some":"thing"},"last":"first"}',
  '{"hello":"goodbye","id":"100"}',
#  '{"hello":"\{escaped\}","goodbye":"wave","id","399"}',
#  '{"hello":"there","more":{"id":"20","inside":"yes","nested":{"id":"21","here":"\{there\}"}},"outside":"noone","id":"10","separate":{"id":"234","us":"alone"}}',
#  '{"hello":"there","more":{"id":"20","inside":"yes","nested":{"id":"21","reallynested":{"id":"4444","deep":"\{well\}"},"here":"\{there\}"}},"outside":"noone","id":"10","separate":{"id":"234","us":"alone"}}',
);

for my $string (@strings) {
  my $hash = Template::Plugin::deJSON->deJSON($string);
  warn $string, "\n", Dumper($hash), '-'x72, "\n";
}
