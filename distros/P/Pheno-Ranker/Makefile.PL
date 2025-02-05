use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;
use File::Find;

install_share dist => 'share';

my $GITHUB_URL = 'https://github.com/CNAG-Biomedical-Informatics/pheno-ranker';

WriteMakefile(
    NAME          => 'Pheno::Ranker',
    ABSTRACT_FROM => 'lib/Pheno/Ranker.pm',
    AUTHOR        => q{Manuel Rueda <mrueda@cpan.org>},
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Pheno/Ranker.pm',
    META_MERGE    => {
        'dynamic_config' => 0,
        'meta-spec' => { version   => 0 },
        'no_index'  => { directory => [qw(docs t)] },
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
        'Scalar::Util'                   => '1.50', # core
        'JSON::XS'                       => '4.03',
        'YAML::XS'                       => '0.88',
        'Path::Tiny'                     => '0.144',
        'Term::ANSIColor'                => '5.01',
        'Text::CSV_XS'                   => '1.50',
        'Sort::Naturally'                => '1.03',
        'File::ShareDir::ProjectDistDir' => '1.000009',
        'Moo'                            => '2.005005',
        'JSON::Validator'                => '5.14',
        'Types::Standard'                => '2.004000',
        'Statistics::Descriptive'        => 0,
        'Hash::Fold'                     => 0,
        'Math::CDF'                      => 0,
        'Data::Fake'                     => '0.006',
        'Graph'                          => '0.9727',
        'Inline::C'                      => '0.82'
    },
    EXE_FILES => [
        'bin/pheno-ranker',
        'utils/bff_pxf_simulator/bff-pxf-simulator',
        'utils/bff_pxf_simulator/Ontologies.pm',
        'utils/csv2pheno_ranker/csv2pheno-ranker'

    ],
    TEST_REQUIRES => {
        'Test::More'      => '1.30',
        'Test::Exception' => '0.43',
        'Path::Tiny'      => '0.144',
        'Data::Fake'      => '0.006',
        'JSON::XS'        => '4.03',
        'YAML::XS'        => '0.88',
        'Text::CSV_XS'    => '1.50',
        'List::MoreUtils' => '0.430'
    },
    test               => { TESTS => 't/*.t' },
    CONFIGURE_REQUIRES => {
        'File::ShareDir::Install' => '0.14',
        'ExtUtils::MakeMaker'     => '7.70'
    }
);

package MY;
use File::ShareDir::Install 'postamble';
