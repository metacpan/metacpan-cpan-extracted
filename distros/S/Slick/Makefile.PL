use 5.036;

use utf8;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Slick',
    VERSION_FROM => 'lib/Slick.pm',
    ABSTRACT     => qq{A PSGI framework for building REST api's in Perl.},
    license      => 'artistic_2',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => { version   => 2 },
        no_index       => { directory => [ 'examples', 't' ] },
        prereqs        => { runtime   => { requires => { perl => '5.036' } } },
        resources      => {
            bugtracker =>
              { web => 'https://github.com/rawleyfowler/Slick/issues' },
            license =>
              [qq{http://www.opensource.org/licenses/artistic-license-2.0}],
            repository =>
              { type => 'git', url => 'https://github.com/rawleyfowler/Slick' }
        },
    },
    PREREQ_PM => {
        'Moo'             => '2.005005',
        'Plack'           => '1.0050',
        'JSON'            => '4.10',
        'Type::Tiny'      => '2.004000',
        'Module::Runtime' => '0.016',
        'Carp'            => '0',
        'URI'             => '5.19',
        'DBI'             => '1.643',
        'JSON::Tiny'      => '0.58',
        'URI::Query'      => '0.16',
        'Try::Tiny'       => '0',
        'YAML::Tiny'      => '1.74',
        'URL::Encode'     => '0.03',
    },
    EXE_FILES => ['bin/slick'],
    test      => { TESTS => 't/*.t t/*/*.t it/*.t it/*/*.t' }
);
