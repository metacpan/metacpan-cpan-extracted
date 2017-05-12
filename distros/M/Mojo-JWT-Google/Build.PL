#! /usr/bin/env perl
#

use utf8;
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Mojo::JWT::Google',
  configure_requires => { 'Module::Build' => 0.42 },
  requires      => { 'Mojo::JWT'   => '>= 0.03', },
  dist_name     => 'Mojo-JWT-Google',
  dist_version  => '0.06',
  dist_author   => 'Richard Elberger riche@cpan.org',
  dist_abstract => 'Easily create Google JWT for Service Account operations',
);

$build->create_build_script;
