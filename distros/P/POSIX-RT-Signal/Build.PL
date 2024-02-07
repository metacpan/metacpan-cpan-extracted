use strict;
use warnings;
use Devel::CheckLib;
use Module::Build;

my @extra_linker_flags = map { "-l$_" } grep { check_lib(lib => $_) } qw/rt/;

my $builder = Module::Build->new(
  module_name         => 'POSIX::RT::Signal',
  'build_requires' => {
    'Module::Build' => '0.28',
    'Test::Exception' => '0',
    'Test::More' => '0.88',
    'Time::HiRes' => '0'
  },
  'configure_requires' => {
    'Devel::CheckLib' => '0',
    'Module::Build' => '0.28'
  },
  'requires' => {
    'Carp' => '0',
    'POSIX' => '0',
    'Sub::Exporter::Progressive' => '0',
    'XSLoader' => '0',
    'strict' => '0',
    'threads::shared' => '0',
    'warnings' => '0'
  },
  extra_linker_flags  => \@extra_linker_flags,
);

$builder->create_build_script();
