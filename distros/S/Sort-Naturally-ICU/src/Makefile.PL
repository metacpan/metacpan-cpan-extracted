use strict;
use Config;
use ExtUtils::MakeMaker;

$Verbose = 1;

WriteMakefile(
	NAME  => 'Sort::Naturally::ICU::nsort',
	clean => {'FILES' => 'libnsort$(LIB_EXT)'},
	LIBS    => is_mac_os() ? '-L/usr/local/opt/icu4c/lib' : '',
	INC     => '-I. ' . (is_mac_os() ? '-I/usr/local/opt/icu4c/include' : ''),
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

sub is_mac_os {
	return $Config{osname} eq 'darwin';
}
