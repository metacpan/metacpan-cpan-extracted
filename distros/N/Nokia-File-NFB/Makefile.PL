use 5.00503;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Nokia::File::NFB',
    VERSION_FROM      => 'lib/Nokia/File/NFB.pm', # finds $VERSION
    PREREQ_PM         => {Carp => 0, Compress::Zlib => 0, Encode => 0, Fcntl => 0, FileHandle => 0, Test::More => 0},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Nokia/File/NFB.pm', # retrieve abstract from module
       AUTHOR         => 'Robert Price <RPRICE@cpan.org>') : ()),
);
