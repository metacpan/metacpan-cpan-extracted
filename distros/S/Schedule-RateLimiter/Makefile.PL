use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Schedule::RateLimiter',
    'VERSION_FROM'	=> 'RateLimiter.pm', # finds $VERSION
    'PREREQ_PM'		=> { Time::HiRes => undef,
                         Test::More  => undef },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'RateLimiter.pm', # retrieve abstract from module
       AUTHOR     => 'Daniel J. Wright <wright@pair.com>') : ()),
);
