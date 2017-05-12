use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
    NAME      => 'SWISH::Stemmer::lib',
    SKIP      => [qw(all static dynamic)],
    clean     => {'FILES' => 'libmylib$(LIB_EXT)'},
);

sub MY::top_targets {
        '
all :: static

pure_all :: static

static ::       libmylib$(LIB_EXT)

libmylib$(LIB_EXT): $(O_FILES)
	$(AR) cr libmylib$(LIB_EXT) $(O_FILES)
	$(RANLIB) libmylib$(LIB_EXT)

';
}

