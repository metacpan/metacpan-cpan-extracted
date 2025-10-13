use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'NetBox::Client',
    AUTHOR       => 'Volodymyr Pidgornyi <vp@dtel-ix.net>',
    VERSION      => '0.1.5',
    ABSTRACT     => 'perl interface to NetBox API',
    LICENSE      => 'apache_2_0',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            'repository' => {
                'type' => 'git',
                'url'  => 'https://github.com/kornix/perl-NetBox-Client.git',
                'web'  => 'https://github.com/kornix/perl-NetBox-Client',
            }
        }
    },
    PL_FILES     => {},
    PREREQ_PM    => {
        'Test::More' => 0,
    },
    test         => { TESTS => 't/*.t' },
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean        => { FILES => 'NetBox-Client-*' },
);

