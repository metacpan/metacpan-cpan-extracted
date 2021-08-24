use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Regexp::Common::Markdown',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Regexp/Common/Markdown.pm',
    ABSTRACT_FROM       => 'lib/Regexp/Common/Markdown.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'strict'        => 0,
        'warnings'      => 0,
        'parent'        => 0,
        'Regexp::Common'=> '2017060201',
        'Regexp::Common::Email::Address' => '1.01',
        'Regexp::Common::URI' => '2017060201',
        'URI::tel'      => 'v0.800.1',
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    ## Need version 5.30.0 minimum for support for variable look-behind
    MIN_PERL_VERSION    => 'v5.30.0',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Common-Markdown-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Regexp-Common-Markdown.git',
                web         => 'https://git.deguest.jp/jack/Regexp-Common-Markdown',
                type        => 'git',
            },
            bugtracker => {
                # web         => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=Regexp::Common::Markdown',
                web         => 'https://git.deguest.jp/jack/Regexp-Common-Markdown/issues',
            },
            license => [ 'http://dev.perl.org/licenses/' ],
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
