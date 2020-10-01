use strict;

use Module::Build;

my $build = Module::Build->new
      ( module_name    => 'Search::InvertedIndex',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'A manager for inverted index maps',
        license        => 'mit',
        requires       => {
            'perl'                    => '5.006',
            'warnings'                => 0,
	    'Carp'                    => 0,
            'Digest::SHA1'            => 0,                                                                                                                                                                                               'DB_File'                 => 0,                                                                                                                                                                                               'Class::ParmList'         => '1.03',                                                                                                                                                                                          'Class::NamedParms'       => '1.04',                                                                                                                                                                                          'Tie::FileLRUCache'       => '1.01',                                                                                                                                                                                          'Tie::DB_File::SplitHash' => '1.01',                                                                                                                                                                                          'Test::More'              => 0,   
        },
        build_requires => { },
        test_requires => {
            'perl'                    => '5.006',
            'warnings'                => 0,
	    'Carp'                    => 0,
            'Digest::SHA1'            => 0,                                                                                                                                                                                               'DB_File'                 => 0,                                                                                                                                                                                               'Class::ParmList'         => '1.03',                                                                                                                                                                                          'Class::NamedParms'       => '1.04',                                                                                                                                                                                          'Tie::FileLRUCache'       => '1.01',                                                                                                                                                                                          'Tie::DB_File::SplitHash' => '1.01',                                                                                                                                                                                          'Test::More'              => 0,   
        },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-Search-InvertedIndex/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-Search-InvertedIndex',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-Search-InvertedIndex.git',
                   web  => 'https://github.com/JerilynFranz/perl-Search-InvertedIndex',
               },
            },
        },
      )->create_build_script;
