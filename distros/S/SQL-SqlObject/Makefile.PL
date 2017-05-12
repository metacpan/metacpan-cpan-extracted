use ExtUtils::MakeMaker;
use ExtUtils::Manifest qw(maniread);
WriteMakefile(
    'NAME'		=> 'SqlObject',
    'VERSION_FROM'	=> 'SQL/SqlObject.pm',
    'PREREQ_PM'		=> {DBI => 1},
    'PMLIBDIRS'         => [ qw(SQL SQL/SqlObject) ],
    'dist'              => { COMPRESS=>"gzip", SUFFIX=>"gz" },
    'DISTNAME'          => 'SQL-SqlObject',
    ($] >= 5.005 ?
      (ABSTRACT => 'Wrapper module for DBI', 
       AUTHOR     => 'Jeff Goff, Corwin Brust <corwin@mpls.cx>') : ()),
);
