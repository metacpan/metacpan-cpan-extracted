use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Stomp::Receipt',
    VERSION_FROM      => 'lib/Net/Stomp/Receipt.pm',
    PREREQ_PM         => { Net::Stomp => 0.34 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Stomp/Receipt.pm',
       AUTHOR         => 'Hugo Salgado <huguei@cpan.org>') : ()),
);

