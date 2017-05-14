use ExtUtils::MakeMaker;
use Carp;

my $mm_version = $ExtUtils::MakeMaker::VERSION || $ExtUtils::MakeMaker::Version;
if( $mm_version < 3.5 ) {
	croak("Sorry, but MakeMaker 3.5 or better is needed to build this package.");
}

WriteMakefile(
  NAME => "Term::Info",  
  LINKTYPE => "\$(INST_PM)",
  VERSION => "1.1",
  );

