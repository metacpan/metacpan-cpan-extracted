use ExtUtils::MakeMaker;

$Verbose = 1;

WriteMakefile(
	NAME  => 'Sort::Naturally::XS::nsort',
	clean => {'FILES' => 'libnsort$(LIB_EXT)'},
);

sub MY::top_targets {
'
all :: static
pure_all :: static
static ::       libnsort$(LIB_EXT)
libnsort$(LIB_EXT): $(O_FILES)
		$(AR) cr libnsort$(LIB_EXT) $(O_FILES)
		$(RANLIB) libnsort$(LIB_EXT)
';
}
