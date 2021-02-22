use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Regexp::Common::Apache2',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Regexp/Common/Apache2.pm',
    ABSTRACT_FROM       => 'lib/Regexp/Common/Apache2.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'strict'        => 0,
        'warnings'      => 0,
        'parent'        => 0,
        'Regexp::Common'=> '2017060201',
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.22.1',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Common-Apache2-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Regexp-Common-Apache2.git',
                web         => 'https://git.deguest.jp/jack/Regexp-Common-Apache2',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://git.deguest.jp/jack/Regexp-Common-Apache2/issues',
            },
            license => [ 'http://dev.perl.org/licenses/' ],
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
