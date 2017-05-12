use strict;
use warnings;

use 5.008000;
use Module::Build;

my $gsl_libs = $ENV{PERLGSL_LIBS} || qx! gsl-config --libs !;

unless ($gsl_libs) {
  print "PerlGSL::RootFinding::SingleDim requires the GSL library to be installed and available. Use PERLGSL_LIBS to specify the linker flags if needed.\n";
  exit( ! $ENV{AUTOMATED_TESTING} );
}

my $build = Module::Build->new(
  module_name       => 'PerlGSL::RootFinding::SingleDim',
  dist_author       => 'Joel Berger <joel.a.berger@gmail.com>',
  license           => 'perl',
  requires          => {
    'perl' => '5.008',
  },
  configure_requires => {
    'Module::Build' => 0.36,
  },
  build_requires    => {
    'ExtUtils::CBuilder' => 0,
  },
  extra_linker_flags => $gsl_libs,
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/PerlGSL-RootFinding-SingleDim",
      bugtracker => "http://github.com/jberger/PerlGSL-RootFinding-SingleDim/issues",
    },
    no_index => {
      file => [ 'README.pod' ],
    },
  },
);
$build->create_build_script;

