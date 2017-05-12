use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Component::Rendezvous::Publish',
    VERSION_FROM      => 'lib/POE/Component/Rendezvous/Publish.pm', # finds $VERSION
    PREREQ_PM         => {
      'Net::Rendezvous::Publish' => '0.03',
      'POE' => '0.3009',
      'Test::More' => '0.54',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Component/Rendezvous/Publish.pm', # retrieve abstract from module
       AUTHOR         => 'Pedro Melo <melo@cpan.org>') : ()),
);
