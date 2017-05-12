#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
plan skip_all => 'JSON::XS is required for this test'
  unless eval { require JSON::XS; 1 };
plan tests => 1;

my $bak = $ENV{MOJO_JSON};
$ENV{MOJO_JSON} = 1;
require Mojo::JSON::Any;
my $json = Mojo::JSON::Any->new;
isa_ok($json, 'Mojo::JSON');
$ENV{MOJO_JSON} = $bak;
