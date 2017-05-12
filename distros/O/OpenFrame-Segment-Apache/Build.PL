use strict;
use warnings;
use Module::Build;

Module::Build->new(
  module_name => 'OpenFrame::Segment::Apache',
  license     => 'perl',
  requires => {
    'Apache'         => '1.27',
    'OpenFrame'      => '3.04',
    'LWP::UserAgent' => '2.001',
    'HTTP::Cookies'  => '1.25',
    'URI'            => '1.21',
    'Test::More'     => '0.01',
  },
  create_makefile_pl => 'traditional',
)->create_build_script;
