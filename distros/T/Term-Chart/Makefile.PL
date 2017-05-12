use 5.010000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Term::Chart',
    VERSION_FROM => 'lib/Term/Chart.pm',    # finds $VERSION
    PREREQ_PM    => {
        'Term::ReadKey' => 0,
        'Readonly'      => 0,
        'Carp'          => 0,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Term/Chart.pod',    # retrieve abstract from module
            AUTHOR => 'Dylan Doxey <dylan@cpan.org>'
          )
        : ()
    ),
);
