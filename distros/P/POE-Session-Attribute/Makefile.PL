use 5.008 ;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Session::Attribute',
    VERSION_FROM      => 'lib/POE/Session/Attribute.pm', # finds $VERSION
    NO_META	      => 1,
    PREREQ_PM         => {
        POE => 0,
# do we really need these ones? they are in perl-core now
#	'Attribute::Handlers' => 0,
#	'Class::ISA' => 0,
#	'Carp' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Session/Attribute.pm', # retrieve abstract from module
       AUTHOR         => 'dmitry kim <dmitry.kim@gmail.com>') : ()),
);
