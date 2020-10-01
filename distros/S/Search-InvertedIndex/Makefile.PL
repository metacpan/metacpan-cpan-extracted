use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
WriteMakefile(
    NAME             => 'Search::InvertedIndex',
    VERSION_FROM     => 'lib/Search/InvertedIndex.pm',
    MIN_PERL_VERSION => '5.006',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'mit', ) : ()),
    PREREQ_PM      => {
	                'Carp'                    => 0,
	                'Digest::SHA1'            => 0,
                        'DB_File'                 => 0,
                        'Class::ParmList'         => '1.03',
                        'Class::NamedParms'       => '1.04',
                        'Tie::FileLRUCache'       => '1.01',
                        'Tie::DB_File::SplitHash' => '1.01',
                        'Test::More'              => 0,
                      },
    'linkext'        => { },    # no link needed
    META_MERGE => {
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
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Search/InvertedIndex.pm', # retrieve abstract from module
       AUTHOR         => 'Jerilyn Franz <cpan@jerilyn.info>') : ()),

       PL_FILES       => {},
);
