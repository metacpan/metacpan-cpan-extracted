use v5;
use strict;
use warnings;

use Module::Build;

my $build_xs = 1;

# Skip XS and build pureperl only if @ARGV says so
grep { $_ eq "--pp" } @ARGV and $build_xs = 0;

# ... or if we don't have a C compiler
$build_xs and eval { require ExtUtils::CBuilder } or $build_xs = 0;
$build_xs and ExtUtils::CBuilder->new->have_compiler or $build_xs = 0;

printf STDERR "Building for %s implementation\n", $build_xs ? "XS" : "PP";

my $build = Module::Build->new(
   module_name => 'Sentinel',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      perl => '5.014',
   },
   test_requires => {
      'Test2::V0' => '0.000148',
   },
   ( $build_xs ? () : ( xs_files => {} ) ),
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
