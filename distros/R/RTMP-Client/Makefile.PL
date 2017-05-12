use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'RTMP::Client',
    VERSION_FROM      => 'lib/RTMP/Client.pm',
    PREREQ_PM         => { 'Time::HiRes' => 0 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/RTMP/Client.pm',
       AUTHOR         => 'ChenGang <yikuyiku.com@gmail.com>') : ()),
);
