use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Redis::AOF::Tail::File',
    VERSION_FROM      => 'lib/Redis/AOF/Tail/File.pm',
    PREREQ_PM         => { 'File::Tail::Lite' => '0.02' }, 
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Redis/AOF/Tail/File.pm',
       AUTHOR         => 'Chen Gang <yikuyiku.com@gmail.com>') : ()),
);
