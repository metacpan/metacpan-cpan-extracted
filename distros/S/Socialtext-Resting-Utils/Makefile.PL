use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Socialtext::Resting::Utils',
    AUTHOR              => 'Luke Closs <cpan@5thplane.com>',
    VERSION_FROM        => 'lib/Socialtext/Resting/Utils.pm',
    ABSTRACT_FROM       => 'lib/Socialtext/Resting/Utils.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting' => '0.27',
        'Test::More'          => 0,
        'Test::Mock::LWP'     => 0,
        'Getopt::Long'        => '2.36',
        'JSON::XS'            => '2.01',
        'YAML'                => 0,
        'Crypt::CBC'          => 0,
        'Crypt::DES'          => 0,
        },
    EXE_FILES           => [
        'bin/wikedit', 
        'bin/stu-save-pages',
        'bin/stu-most-wanted',
        'bin/stu-local-copy',
        'bin/stu-tagged-pages',
    ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Socialtext-Resting-Utils-*' },
);
