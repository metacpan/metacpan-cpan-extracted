use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'       => 'Trevor Ward (trw[at]trevor-ward.co.uk)',
    'NAME'	       => 'PDFREP',
    'VERSION_FROM' => 'PDFREP.pm', # finds $VERSION
    # other information
    PREREQ_PM      => {
        'GD'       => '0', # or a minimum workable version
    }
);
