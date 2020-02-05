use strict;
use warnings;
use Module::Build;

my %win_build_requires = ();
if ($^O eq 'MSWin32') {
    print <<"_WARN2WINDOWS_";

===============================================
  *** WARN for Windows ***
  Mostly, this software can work on Windows.
  But the 'fork' option in 'all_ok' method is
  NOT SUPPORTED.
  All tests will skip.
===============================================

_WARN2WINDOWS_
    %win_build_requires = (
        'Win32' => 0
    );
}

my $builder = Module::Build->new(
    module_name         => 'Test::AllModules',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Test/AllModules.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'FindBin' => 0,
        'File::Spec' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Module::Pluggable::Object' => 0,
        'Test::More' => 0.88,
        'Test::SharedFork' => 0,
        %win_build_requires,
    },
    add_to_cleanup      => [ 'Test-AllModules-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Test-AllModules'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
