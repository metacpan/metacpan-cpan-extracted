use 5.008001;
use strict;
use warnings;
use Devel::CheckLib;
use Module::Build;

my @extra_linker_flags = map { "-l$_" } grep { check_lib(lib => $_) } qw/rt/;

if ($^O eq 'MSWin32') {
  print STDERR "OS not supported\n";
  exit 0;
}

my $builder = Module::Build->new(
  module_name         => 'POSIX::RT::Timer',
  'build_requires' => {
    'File::Spec' => '0',
    'IO::Handle' => '0',
    'IPC::Open3' => '0',
    'Module::Build' => '0.3601',
    'POSIX' => '0',
    'Test::Fatal' => '0',
    'Test::More' => '0',
    'Time::HiRes' => '0'
  },
  'configure_requires' => {
    'Devel::CheckLib' => '0',
    'Module::Build' => '0.3601'
  },
  'requires' => {
    'XSLoader' => '0',
    'perl' => '5.008001',
    'strict' => '0',
    'warnings' => '0'
  },
  extra_linker_flags  => \@extra_linker_flags,
);

$builder->create_build_script();
