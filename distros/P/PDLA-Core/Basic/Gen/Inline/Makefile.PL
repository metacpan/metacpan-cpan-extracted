use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Inline',
	      VERSION_FROM => 'Pdlapp.pm',
	      PREREQ_PM => {'Inline' => 0.43},
	      PM => { map {($_ => '$(INST_LIBDIR)/Inline/'.$_)} <*.pm> },
);
