use strict;
use lib 'lib';
use inc::Module::Install;
use Config;

name     'Module-Install-PodFromEuclid';
all_from 'lib/Module/Install/PodFromEuclid.pm';

resources
   homepage   'http://search.cpan.org/search?query=module-install-podfromeuclid';
   bugtracker 'https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Install-PodFromEuclid';
   repository 'git://github.com/fangly/module-install-podfromeuclid.git';

build_requires 'Test::More'    => 0.47; # in Perl 5.6.2
build_requires 'File::Temp'    => 0;    # in Perl 5.6.1

requires 'Module::Install'  => 1.00;
requires 'Getopt::Euclid'   => '0.3.4';

###readme_from;

clean_files 'have_make';

if ( $Config{make} and can_run( $Config{make} ) ) {
  print "Which make program is available? ", $Config{make}, "\n";
  open my $out, '>', 'have_make' or die "$!\n";
  print $out "meep\n";
  close $out;
}

WriteAll();
