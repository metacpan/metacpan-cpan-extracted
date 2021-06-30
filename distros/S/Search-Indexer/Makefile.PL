use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Search::Indexer',
    VERSION_FROM      => 'lib/Search/Indexer.pm',
    PREREQ_PM         => {'Search::QueryParser'            => '0.91',
			  'BerkeleyDB'                     => '0.22',
                          'List::Util'                     => 0,
                          'List::MoreUtils'                => 0,
                          'Text::Transliterator::Unaccent' => 0,
                        },
    TEST_REQUIRES     => { 'Test2::V0'                     => 0,
                           'FindBin'                       => 0,
                         },
    ABSTRACT_FROM  => 'lib/Search/Indexer.pm',
    AUTHOR         => 'Laurent Dami <dami@cpan.org>',
    META_MERGE => {
      resources => {
        homepage   => 'https://metacpan.org/author/DAMI',
        license    => 'http://www.perlfoundation.org/artistic_license_2_0',
        repository => 'https://github.com/damil/Search-Indexer.git',
      },
   },

);
