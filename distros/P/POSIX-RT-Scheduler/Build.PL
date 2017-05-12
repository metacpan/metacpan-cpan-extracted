use strict;
use warnings;
use Devel::CheckLib;
use Module::Build;

my @extra_linker_flags = map { "-l$_" } grep { check_lib(lib => $_) } qw/rt/;

my $builder = Module::Build->new(
  module_name         => 'POSIX::RT::Scheduler',
    'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Devel::CheckLib' => '0',
    'Module::Build' => '0.3601'
  },
  'requires' => {
    'XSLoader' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'warnings' => '0'
  },
  
  extra_linker_flags  => \@extra_linker_flags,
);

$builder->create_build_script();
