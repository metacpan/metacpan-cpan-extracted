use ExtUtils::MakeMaker;
$Verbose = 1;

WriteMakefile(
    'NAME'	=> 'Net::Z3950::yazwrap',
    'SKIP'	=> [qw(all static dynamic test)],
    'clean'	=> {'FILES' => 'libyazwrap$(LIB_EXT)'},
	      'OPTIMIZE' => '-g',	### temporary
#	Some systems like to be told:  'DEFINE' => '-D_GNU_SOURCE'
);


sub MY::top_targets {
	'
all :: static

static :: libyazwrap$(LIB_EXT)

libyazwrap$(LIB_EXT): $(O_FILES)
	$(AR) cr libyazwrap$(LIB_EXT) $(O_FILES)
	$(RANLIB) libyazwrap$(LIB_EXT)

# nothing to test

test:

';
}
