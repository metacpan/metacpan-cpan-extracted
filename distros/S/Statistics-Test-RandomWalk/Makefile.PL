use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Statistics::Test::RandomWalk',
    VERSION_FROM      => 'lib/Statistics/Test/RandomWalk.pm', # finds $VERSION
    LICENSE => 'perl',
    PREREQ_PM         => {
      Params::Util => '0',
      Math::BigFloat => '0',
      Statistics::Test::Sequence => '0',
      Class::XSAccessor => '1.05',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Statistics/Test/RandomWalk.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
