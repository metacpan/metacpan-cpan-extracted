use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
          NAME	   => 'Net::ICQV5',
          VERSION_FROM => 'lib/Net/ICQV5.pm',
          PREREQ_PM    => { Net::ICQV5CD => 1.02 },
);
