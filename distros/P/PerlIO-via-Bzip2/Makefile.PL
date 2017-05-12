use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'PerlIO::via::Bzip2',
    VERSION_FROM      => 'lib/PerlIO/via/Bzip2.pm',
    PREREQ_PM         => {
        'Compress::Bzip2' => 1.03
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PerlIO/via/Bzip2.pm',
       AUTHOR         => 'Arjen Laarhoven <arjen@cpan.org>') : ()),
);
