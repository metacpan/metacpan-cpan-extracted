use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
  NAME   => 'lib::cidr-compare',
  SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
  clean  => {'FILES' => 'libcidr-compare$(LIB_EXT)'},
);


sub MY::top_targets {
  '
  all :: static

  pure_all :: static

  static ::       libcidr-compare$(LIB_EXT)

  libcidr-compare$(LIB_EXT): $(O_FILES)
	$(AR) cr libcidr-compare$(LIB_EXT) $(O_FILES)
	$(RANLIB) libcidr-compare$(LIB_EXT)

  ';
}
