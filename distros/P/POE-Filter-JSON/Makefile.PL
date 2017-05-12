#use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'          => 'POE::Filter::JSON',
    'VERSION_FROM'  => 'lib/POE/Filter/JSON.pm', # finds $VERSION
    'PREREQ_PM'     => {
        'Carp'      => undef,
        'JSON::Any' => 1.04,
    },
    'dist'         => {
        'SUFFIX'       => ".gz",
        'DIST_DEFAULT' => 'all tardist',
        'COMPRESS'     => "gzip -9vf",
    },
    AUTHOR          => 'David Davis <xantus@cpan.org>',
);
