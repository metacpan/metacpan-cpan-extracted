use ExtUtils::MakeMaker;

##-- put 'realclean_files' in a variable: avoid MakeMaker puking with:
##     ERROR from evaluation of .../ccsutils/Makefile.PL:
##     Modification of a read-only value attempted at /usr/share/perl/5.8/Carp/Heavy.pm line 45.
our $realclean_files = '*~ *.tmp README.txt';
our $has_readme_pod  = grep {-e $_ } (<README.pod>, <README.POD>, <README.rpod>);
our $has_pdlpp       = grep {-e $_ } (<*.pd>);
WriteMakefile(
	      NAME=>'PDL::VectorValued::Dev',
	      VERSION_FROM => '../VectorValued.pm',
	      LICENSE => 'perl',
	      #PM => { (map {$_=>"\$(INST_LIBDIR)/CCS/$_"} <*.pm>), },
	      realclean=>{ FILES=>$realclean_files, },
	      DIR =>[
		     #'my_subdir',
		    ],
	     );

##-- overrides
sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  if ($::has_readme_pod) {
    $inherited .= (
		   "\n\n"
		   ."dist: README.txt\n"
		   ."\n"
		   ."create_distdir: README.txt\n"
		   ."\n"
		   ."distcheck: README.txt\n"
		   ."\n"
		   ."manicheck: README.txt\n"
		   ."\n"
		  );
  }
  return $inherited;
}

sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  #$inherited =~ s/^(\.SUFFIXES\s*:.*)$/$1 .pod .pm .man .txt .html;/
  $inherited .=
"
.SUFFIXES: .pm .pod .rpod .man .txt .html

.pm.html:
\tpod2html --outfile \$@ \$<

.pm.txt:
\tpod2text \$< \$@

.pod.html:
\tpod2html --outfile \$@ \$<

.pod.txt:
\tpod2text \$< \$@

.rpod.html:
\tpod2html --outfile \$@ \$<

.rpod.txt:
\tpod2text \$< \$@

";
  return $inherited;
}


sub MY::top_targets {
  package MY;
  my $inherited = shift->SUPER::top_targets(@_);
  return $inherited;
}

sub MY::postamble {
  if ($::has_pdlpp) {
    return pdlpp_postamble($package); ##-- for PDL::PP (sub-)modules
  }
  return '';
}
