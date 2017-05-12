use ExtUtils::MakeMaker;

use 5.6.0;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Statistics::GaussHelmert',
    'ABSTRACT_FROM'     => "GaussHelmert.pm",
    'VERSION_FROM'	=> 'GaussHelmert.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
			    'ExtUtils::F77'    => 1.13,
			    'Math::Random' => 0.61,	# this is needed for
                                                        # testing
			    'PDL'          => "2.3.1"
			    },
    'AUTHOR'           => 'Stephan Heuel <perl@heuel.org>'
);
