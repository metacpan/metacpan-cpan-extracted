use ExtUtils::MakeMaker qw( prompt WriteMakefile );
use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    	'NAME'		=> 'Simulation::Automate',
	'VERSION_FROM'	=> 'Automate.pm', # finds $VERSION
	'INST_BIN' => './bin',
	'INSTALLSITEBIN' => '/usr/local/bin',
   ($] >= 5.005 ?   ## Add these new keywords supported since 5.005
    ('ABSTRACT' => 'Simulation Automation Tool', 
    'AUTHOR'   => "Wim Vanderbauwhede <wim\x40motherearth.org>") : ()),

);

sub MY::postamble {
  return "setup :\n\t\@\$(PERL)".' "-I$(INST_LIB)" -e "use Automate;use Simulation::Automate; &Simulation::Automate::setup();"'."\n\n"."localinstall:\n\t\@\$(PERL)".' "-I$(INST_LIB)" -e "use Automate;use Simulation::Automate; &Simulation::Automate::localinstall();"'."\n";
}
