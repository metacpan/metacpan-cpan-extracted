use strict;
use warnings;
use ExtUtils::MakeMaker;

# For the lazy people
undef &MY::postamble; # suppress warning
*MY::postamble = sub {
PDLA::Core::Dev::postamble().
q~

test_tjl :
	PERL_DL_NONLAZY=1 $(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use Test::Harness qw(&runtests $$verbose); $$verbose=$(TEST_VERBOSE); runtests @ARGV;' *.pl

~
};

# NOTE:
#   we hijack m51.fits from the parent directory and 
#   install that into the demos directory
WriteMakefile(
     'NAME'	=> 'PDLA::Demos',
     'VERSION_FROM' => '../Basic/Core/Version.pm',
     'PM'       => {'General.pm'     => '$(INST_LIBDIR)/Demos/General.pm',
                    'Screen.pm'    => '$(INST_LIBDIR)/Demos/Screen.pm',
                    'BAD_demo.pm'       => '$(INST_LIBDIR)/Demos/BAD_demo.pm',
                    'BAD2_demo.pm'      => '$(INST_LIBDIR)/Demos/BAD2_demo.pm',
                    'Transform_demo.pm' => '$(INST_LIBDIR)/Demos/Transform_demo.pm',
                    'Cartography_demo.pm' => '$(INST_LIBDIR)/Demos/Cartography_demo.pm',
		    'Gnuplot_demo.pm'   =>  '$(INST_LIBDIR)/Demos/Gnuplot_demo.pm',
                    '../m51.fits'       => '$(INST_LIBDIR)/Demos/m51.fits',
                    'Prima.pm' => '$(INST_LIBDIR)/Demos/Prima.pm',
		   },
     'clean' => { 'FILES' => 'BAD_demo.pm BAD2_demo.pm' },
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
