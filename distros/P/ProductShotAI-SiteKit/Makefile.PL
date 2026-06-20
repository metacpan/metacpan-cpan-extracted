use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'ProductShotAI::SiteKit',
    VERSION_FROM  => 'lib/ProductShotAI/SiteKit.pm',
    ABSTRACT      => 'URL helpers and metadata for ProductShot AI',
    AUTHOR        => 'ProductShot AI',
    LICENSE       => 'mit',
    MIN_PERL_VERSION => '5.010',
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage   => 'https://productshotai.app',
            repository => {
                type => 'git',
                url  => 'https://github.com/bbwdadfg/productshotai-site-kit.git',
                web  => 'https://github.com/bbwdadfg/productshotai-site-kit',
            },
            bugtracker => {
                web => 'https://github.com/bbwdadfg/productshotai-site-kit/issues',
            },
        },
    },
);
