
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';
my $custom_build = 'Module::Build::Live';
eval("require $custom_build;");
unless($@) {
  warn "using custom build class:  '$custom_build'\n";
  $build_class = $custom_build;
}

my $builder = $build_class->new(
  module_name         => 'Package::Tent',
  license             => 'perl',
  dist_version_from   => 'lib/Package/Tent.pm',
  requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Package-Tent-* META.yml)],
  no_index            => {
    dir => [qw(t/samples)],
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
