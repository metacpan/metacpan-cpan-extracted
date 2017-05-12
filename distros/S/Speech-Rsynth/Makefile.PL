# -*- Mode: Perl -*-
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME		=> 'Speech::Rsynth',
	      VERSION_FROM	=> 'Rsynth.pm.in', # finds $VERSION
	      ABSTRACT          => 'Perl interface to librsynth speech synthesizer C library',
	      PREREQ_PM	        => {}, # e.g., Module::Name => 1.1

	      # XS black magic from XS-cookbook
	      XSPROTOARG        => '-noprototypes',
	      TYPEMAPS          => ['perlobject.map'],

	      AUTHOR            => 'Bryan Jurish <moocow@ling.uni-potsdam.de>',
	      'LIBS'		=> ['-lrsynth -lgdbm -lm'], # e.g., '-lm'
	      'DEFINE'		=> '-DHAVE_STRCHR -DSTRCHR_IS_MACRO', # e.g., '-DHAVE_SOMETHING'

	      # Insert -I. if you add *.h files later:
	      'INC'		=> '', # e.g., '-I/usr/include/other'

	      # Un-comment this if you add C files to link with later:
	      # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
	     );


#---------------------------------------------------------------
# Extensions
#---------------------------------------------------------------

sub MY::postamble {
  (''
   # how to format the README file
   .qq(README : README.pod\n)
   .qq(\t pod2text README.pod > README\n\n)

   # auto-generation variables
   .qq(CREATE_AXS = util/create-xs-accessors.perl\n)
   .qq(AXS_SPEC = util/rsynth-accessor-specs.pl\n)
   .qq(AXS_FLAGS = -prefix='rsxs_' -spex=\$(AXS_SPEC)\n)

   # auto-generate xs file (w/ accessors)
   .qq(Rsynth.xs : Rsynth.xs.in \$(CREATE_AXS) \$(AXS_SPEC)\n)
   .qq(\t \$\(FULLPERL\) \$(CREATE_AXS) \$(AXS_FLAGS) -xsin=\$^ -xsout=\$\@)
   .qq(\n)

   # auto-generate pm file (w/ accessors)
   .qq(Rsynth.pm : Rsynth.pm.in \$(CREATE_AXS) \$(AXS_SPEC)\n)
   .qq(\t \$\(FULLPERL\) \$(CREATE_AXS) \$(AXS_FLAGS) -pmin=\$^ -pmout=\$\@)
   .qq(\n)

   # make some noise
   .qq(noise : t/06_audio.t\n)
   .qq(\t PERL_DL_NONLAZY=1 \$(FULLPERL) \\\n)
   .qq(\t   -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB)\\\n)
   .qq(\t   \$\<\n)
   .qq(\n)
  )
}

sub MY::realclean {
  package MY;
  my $inherited = shift->SUPER::realclean(@_);
  $inherited .= qq(\t \$\(RM_F\) Rsynth.xs\n);
  $inherited;
}

sub MY::dist_core {
  package MY;
  my $inherited = shift->SUPER::dist_core(@_);

  # distribution requirements:
  # current README file
  #$inherited =~ s/^dist\s*:/dist\ : README/m;

  # -> current Rsynth.xs file
  $inherited =~ s/^dist\s*:/dist\ : Rsynth.xs/m;

  # -> current Rsynth.pm file
  $inherited =~ s/^dist\s*:/dist\ : Rsynth.pm/m;

  $inherited;
}
