use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Component::Omegle',
    VERSION_FROM      => 'lib/POE/Component/Omegle.pm', # finds $VERSION
    PREREQ_PM         => {
        POE => '',
        'WWW::Omegle' => '0.02',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Component/Omegle.pm', # retrieve abstract from module
       AUTHOR         => 'Mischa Spiegelmock <revmischa@cpan.org>') : ()),
);
