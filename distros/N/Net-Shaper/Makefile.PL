use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Shaper',
    'VERSION_FROM'	=> 'Shaper.pm', # finds $VERSION
    'PREREQ_PM'		=> {IO::Select => 0, Time::HiRes => 0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Shaper.pm', # retrieve abstract from module
       AUTHOR     => 'Benjamin Holzman <bholzman@earthlink.net>') : ()),
);
