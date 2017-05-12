use 5.008008;
use ExtUtils::MakeMaker;

eval { require liberty };
exit 0 if $@;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Parse::Liberty',
    VERSION_FROM      => 'lib/Parse/Liberty.pm', # finds $VERSION
    PREREQ_PM         => {'liberty' => '0'}, # e.g., Module::Name => 1.1
    LICENSE           => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Parse/Liberty.pm', # retrieve abstract from module
       AUTHOR         => 'Eugene Gagarin <mosfet07@ya.ru>') : ()),
);
