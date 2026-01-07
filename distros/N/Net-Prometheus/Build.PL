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

print STDERR "Building optional XS module\n" if $build_xs;

my $build = Module::Build->new(
   module_name => 'Net::Prometheus',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'perl' => '5.020',
      'meta' => '0.009',

      'List::Util' => '1.33',
      'Ref::Util' => 0,
      'Struct::Dumb' => 0,
      'URI' => 0,  # for parsing query string in ->psgi_app
   },
   test_requires => {
      'List::Util'  => '1.29', # pairgrep
      'HTTP::Request' => 0,
      'Test2::V0' => 0,
   },
   test_recommends => {
      'Future::IO::Impl::UV' => '0.03',
   },
   ( $build_xs ? () : ( xs_files => {} ) ),
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
