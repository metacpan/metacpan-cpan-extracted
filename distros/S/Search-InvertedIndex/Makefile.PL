use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'           => 'Search::InvertedIndex',
    'VERSION_FROM'   => 'lib/Search/InvertedIndex.pm',
    'PREREQ_PM'      => { 'Digest::SHA1'            => 0,
                          'DB_File'                 => 0,
                          'Class::ParmList'         => '1.03',
                          'Class::NamedParms'       => '1.04',
                          'Tie::FileLRUCache'       => '1.01',
                          'Tie::DB_File::SplitHash' => '1.01',
                          'Test::More'              => 0,
                        },
    'linkext'        => { LINKTYPE=>'' },    # no link needed
    'dist'           => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
    'ZIP'            => '/usr/bin/zip','ZIPFLAGS'=>'-rl'}
);
