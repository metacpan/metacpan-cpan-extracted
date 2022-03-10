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
        'Module::Generic' => 'v0.21.9',
        'Module::Generic::SharedMem' => 'v0.2.2',
        'Nice::Try'     => 'v1.1.2',
        'PPI'           => '1.270',
        'POSIX'         => 0,
        'Scalar::Util'  => '1.50',
        'Storable'      => '3.15',
        'Want'          => '0.29',
    },
    TEST_REQUIRES =>
    {
        'Module::Generic::File' => 'v0.3.2',
        'Test2::IPC'    => '1.302190',
        'Test2::V0'     => '0.000145',
        'Test::Pod'     => '1.52',
        'Time::HiRes'   => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.14.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
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

