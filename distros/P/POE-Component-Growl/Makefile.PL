# $Id: Makefile.PL,v 1.0 2005/07/31 17:31 $

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'AUTHOR'		=> 'Alessandro Ranellucci <aar@cpan.org>',
    'NAME'			=> 'POE::Component::Growl',
    'ABSTRACT'		=> 'Growl notification dispatcher for POE',
    'VERSION_FROM' 	=> 'Growl.pm', # finds $VERSION
    'PM'     		=> { 'Growl.pm' => '$(INST_LIBDIR)/Growl.pm' },
    'PREREQ_PM'		=> {
    	POE				=> 0.31,
    	Mac::Growl 		=> 0.65,
    	Test::More		=> 0
    },
    'dist'         	=> { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
