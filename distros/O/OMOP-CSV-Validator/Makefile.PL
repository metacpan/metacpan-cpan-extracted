use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker;

my $GITHUB_URL = 'https://github.com/mrueda/omop-csv-validator';

WriteMakefile(
    NAME          => 'OMOP::CSV::Validator',
    ABSTRACT_FROM => 'lib/OMOP/CSV/Validator.pm',
    AUTHOR        => q{Manuel Rueda <mrueda@cpan.org>},
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/OMOP/CSV/Validator.pm',
    META_MERGE    => {
        'dynamic_config' => 0,
        'meta-spec' => { version   => 0 },
        'no_index'  => { directory => [qw(t)] },
        'prereqs'   => { runtime   => { requires => { perl => '5.026000' } } },
        'resources' => {
            bugtracker => { web => "$GITHUB_URL/issues" },
            homepage   => $GITHUB_URL,
            license    =>
              ['http://www.opensource.org/licenses/artistic-license-2.0'],
            repository =>
              { type => 'git', url => "$GITHUB_URL.git", web => $GITHUB_URL },
        },
        'x_contributors' => [],
    },
    PREREQ_PM => {
        'JSON::XS'                       => '4.03',
        'Path::Tiny'                     => '0.144',
        'Text::CSV_XS'                   => '1.50',
        'JSON::Validator'                => '5.14',
        'Term::ANSIColor'                => '5.01'
    },
    EXE_FILES     => ['bin/omop-csv-validator','utils/reorder-csv.pl'],
    TEST_REQUIRES => {
        'Test::More'      => '1.30'
    },
    test               => { TESTS => 't/*.t' },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => '7.70',
    }
);
