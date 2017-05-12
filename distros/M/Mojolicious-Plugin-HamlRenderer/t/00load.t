#!/usr/bin/evn perl

use strict;
use warnings;

use Test::More;

my @modules = qw(
  MojoX::Renderer::Haml
  Mojolicious::Plugin::HamlRenderer
);

plan tests => scalar @modules;

use_ok($_) for @modules;
