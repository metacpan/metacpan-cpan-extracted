use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'            => 'MojoX::AIO',
    'VERSION_FROM'    => 'lib/MojoX/AIO.pm', # finds $VERSION
    'PREREQ_PM'        => {
        'Carp'        => undef,
        'IO::AIO'     => 2,
        'Mojolicious' => 1.65,
    },
    'dist'         => {
        'SUFFIX'       => ".gz",
        'DIST_DEFAULT' => 'all tardist',
        'COMPRESS'     => "gzip -9vf",
    },
);
