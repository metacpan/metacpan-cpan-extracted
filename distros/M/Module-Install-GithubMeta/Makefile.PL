use strict;
use inc::Module::Install;
use Config;
name 'Module-Install-GithubMeta';
author 'Chris Williams <chris@bingosnet.co.uk>';
version_from 'lib/Module/Install/GithubMeta.pm';
abstract_from 'lib/Module/Install/GithubMeta.pm';
readme_from 'lib/Module/Install/GithubMeta.pm';
license 'perl';
auto_license holder => 'Chris Williams and Tatsuhiko Miyagawa';
perl_version '5.006';
build_requires 'Test::More' => 0.47;
build_requires 'Capture::Tiny' => 0.05;
requires 'Module::Install' => 0.85;
auto_provides;
githubmeta;
clean_files 'dist have_make';
if ( $Config{make} and can_run( $Config{make} ) ) {
  print "I can run '", $Config{make}, "' good\n";
  open HAVEMAKE, '>have_make' or die "$!\n";
  print HAVEMAKE "meep\n";
  close HAVEMAKE;
}
makemaker_args(dist => { PREOP => "$^X ./tools/git-log.pl > ./Changes" });
WriteAll();
