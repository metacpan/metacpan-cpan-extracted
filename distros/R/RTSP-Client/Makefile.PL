use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'RTSP::Client',
    VERSION_FROM      => 'lib/RTSP/Client.pm', # finds $VERSION
    PREREQ_PM         => {
        'RTSP::Lite' => 0.1,
        'Moose' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RTSP/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Mischa Spiegelmock <revmischa@cpan.org>') : ()),

    META_ADD => { resources => { repository => 'git://github.com/revmischa/rtsp-client.git' } },

);
