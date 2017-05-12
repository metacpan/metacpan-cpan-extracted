use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME              => 'Peptide::Pubmed',
	      VERSION_FROM      => 'lib/Peptide/Pubmed.pm', # finds $VERSION
	      PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	      depend => { Makefile => '$(VERSION_FROM)' }, # finds $VERSION correctly when VERSION_FROM file has a changed $VERSION
);
