use strict;
use warnings;
use ExtUtils::MakeMaker;

my $makemakerversion = ($ExtUtils::MakeMaker::VERSION =~ s/_//g);
$makemakerversion =~ s/_//g;

WriteMakefile(
    NAME         => 'NetBox::API',
    AUTHOR       => 'Volodymyr Pidgornyi <vp@dtel-ix.net>',
    VERSION      => '0.1.3',
    ABSTRACT     => 'perl interface to NetBox API',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            'repository' => {
                'type' => 'git',
                'url'  => 'https://github.com/kornix/perl-NetBox-API.git',
                'web'  => 'https://github.com/kornix/perl-NetBox-API',
            }
        }
    },
    ($makemakerversion >= 6.3002 ? ('LICENSE' => 'perl') : ()),
    PL_FILES     => {},
    PREREQ_PM    => {
        'Test::More' => 0,
    },
    test         => { TESTS => 't/*.t' },
    dist	 => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean        => { FILES => 'NetBox-API-*' },
);

