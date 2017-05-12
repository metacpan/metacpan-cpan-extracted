use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ShipIt::Step::JenkinsCheck',
    VERSION_FROM      => 'lib/ShipIt/Step/JenkinsCheck.pm', # finds $VERSION
    PREREQ_PM         => {
        'LWP::UserAgent'    => 0,
        'JSON'              => 0,
        'Term::ReadLine'    => 0,
        'Try::Tiny'         => 0,
        'ShipIt::Step'      => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'        => 0,
    },
    ABSTRACT_FROM  => 'lib/ShipIt/Step/JenkinsCheck.pm', # retrieve abstract from module
    AUTHOR         => 'Dave Lambley <davel@state51.co.uk>',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/davel/ShipIt-Step-JenkinsCheck',
        }
    },
);
