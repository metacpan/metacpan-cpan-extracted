use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Promise::Me',
    VERSION_FROM        => 'lib/Promise/Me.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT_FROM       => 'lib/Promise/Me.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'parent'        => 0,
        'strict'        => 0,
        'warnings'      => 0,
        'Clone'         => '0.45',
        'Config'        => 0,
    	'Filter::Util::Call' => '1.59',
        'Module::Generic' => 'v0.15.0',
        'Module::Generic::SharedMem' => 'v0.1.0',
        'Nice::Try'     => 'v1.1.2',
        'POSIX'         => 0,
        'Scalar::Util'  => '1.50',
        'Storable'      => '3.15',
        'Want'          => '0.29',
    },
    TEST_REQUIRES =>
    {
        'File::Spec'    => 0,
        'IO::File'      => 0,
        'Module::Generic::File' => 0,
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
        'Time::HiRes'   => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.14.0',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Promise-Me-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Promise-Me.git',
                web         => 'https://git.deguest.jp/jack/Promise-Me',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://git.deguest.jp/jack/Promise-Me/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

