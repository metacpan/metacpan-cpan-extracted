use if ! ( grep { $_ eq '.' } @INC ), qw[lib .];
use strict;
use inc::Module::Install;
use Config;
name 'Module-Install-AutoLicense';
author 'Chris Williams <chris@bingosnet.co.uk>';
version_from 'lib/Module/Install/AutoLicense.pm';
abstract_from 'lib/Module/Install/AutoLicense.pm';
license 'perl';
perl_version '5.006';
build_requires 'Test::More' => 0.47;
build_requires 'File::Temp' => 0;
build_requires 'Capture::Tiny' => 0.05;
requires 'Module::Install' => 0.85;
requires 'Software::License' => 0.010;
clean_files 'dist have_make';
if ( $Config{make} and can_run( $Config{make} ) ) {
  print "I can run '", $Config{make}, "' good\n";
  open HAVEMAKE, '>have_make' or die "$!\n";
  print HAVEMAKE "meep\n";
  close HAVEMAKE;
}
auto_provides;
auto_license;
githubmeta;
WriteAll();
