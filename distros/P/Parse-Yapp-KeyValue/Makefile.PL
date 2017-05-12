use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Parse::Yapp::KeyValue',
    VERSION_FROM      => 'lib/Parse/Yapp/KeyValue.pm', # finds $VERSION
    PREREQ_PM         => { Parse::Lex => 0, Parse::Yapp => 0 }, # e.g., Module::Name => 1.1
	NO_META           => 1,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Parse/Yapp/KeyValue.pm', # retrieve abstract from module
       AUTHOR         => 'diz <diz@>') : ()),
);
