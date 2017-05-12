
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME         => 'Perlipse',
    VERSION_FROM => 'lib/Perlipse.pm', # finds \$VERSION
    AUTHOR       => 'Jae Gangemi (jgangemi@gmail.com)',
    ABSTRACT     => 'Perlipse',
    PREREQ_PM    => {
        'Class::Accessor'   => 0.31,
        'Module::Pluggable' => 3.8,
        'PPI'               => 1.204_01,
        'XML::Writer'       => 0.604,
        'Test::Simple'      => 0.80,
    },
);
