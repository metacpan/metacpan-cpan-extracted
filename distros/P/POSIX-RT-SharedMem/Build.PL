use strict;
use warnings;
use Devel::CheckLib;
use Module::Build;

my @extra_linker_flags = map { "-l$_" } grep { check_lib(lib => $_) } qw/rt/;

my $builder = Module::Build->new(
  module_name         => 'POSIX::RT::SharedMem',
    'build_requires' => {
    'File::Spec' => '0',
    'IO::Handle' => '0',
    'IPC::Open3' => '0',
    'Module::Build' => '0.3601',
    'POSIX' => '0',
    'Test::Fatal' => '0',
    'Test::More' => '0.88',
    'perl' => '5.006'
  },
  'configure_requires' => {
    'Devel::CheckLib' => '0',
    'Module::Build' => '0.3601'
  },
  'requires' => {
    'Carp' => '0',
    'Exporter' => '5.57',
    'Fcntl' => '0',
    'File::Map' => '0',
    'XSLoader' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'warnings' => '0'
  },
  
  extra_linker_flags  => \@extra_linker_flags,
);

$builder->create_build_script();
