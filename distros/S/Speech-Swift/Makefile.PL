use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Speech::Swift',
    VERSION_FROM      => 'lib/Speech/Swift.pm', # finds $VERSION
    INC 	      => q[-I. -I/opt/swift/include],
    LIBS              => [q[-L/opt/swift/lib -lswift -lceplang_en -lceplex_us]],
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Speech/Swift.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Pultz <mike@mikepultz.com>') : ()),
);
