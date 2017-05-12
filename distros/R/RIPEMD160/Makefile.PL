use ExtUtils::MakeMaker;
use Config;

if ($Config{'byteorder'} eq '1234') {
	$ENDIAN = 'LITTLE_ENDIAN';
} else {
	$ENDIAN = 'BIG_ENDIAN';
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
    'NAME'		=>	'RIPEMD160',
    'VERSION_FROM'	=>	'RIPEMD160.pm',
    'OBJECT'		=>	q[RIPEMD160$(OBJ_EXT) rmd160$(OBJ_EXT) wrap_160$(OBJ_EXT)],
    'CONFIG'	=> ['byteorder'],	# Used to determine 64-bitness
    'DEFINE'	=> '-DPERL_BYTEORDER=$(BYTEORDER)',
);
