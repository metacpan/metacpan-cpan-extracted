use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::CPAGateway',
    VERSION_FROM      => 'lib/SMS/CPAGateway.pm', # finds $VERSION
    PREREQ_PM         => {
		Any::Moose => 0,
		LWP::UserAgent => 0,
		URI::Encode => 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SMS/CPAGateway.pm', # retrieve abstract from module
       AUTHOR         => 'Eskild Hustvedt <zerodogg@cpan.org>') : ()),
);
