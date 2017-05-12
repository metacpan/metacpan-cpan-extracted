use inc::Module::Install;
use Config;

name            'Module-Install-ReadmePodFromPod';
all_from        'lib/Module/Install/ReadmePodFromPod.pm';
readme_from     'lib/Module/Install/ReadmePodFromPod.pm';
readme_pod_from 'lib/Module/Install/ReadmePodFromPod.pm';

perl_version   '5.006';
requires       'Module::Install' => 0.85;
requires       'Pod::Perldoc';
build_requires 'Test::More'      => 0.47;
build_requires 'Capture::Tiny'   => 0.05;

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_include;

githubmeta;
auto_set_repository;

if ( $Config{make} and can_run( $Config{make} ) ) {
  print "I can run '", $Config{make}, "' good\n";
  open HAVEMAKE, '>have_make' or die "$!\n";
  print HAVEMAKE "meep\n";
  close HAVEMAKE;
}

WriteAll;
