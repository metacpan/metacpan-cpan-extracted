
use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
	NAME => 'Net::NfDump::libnf',
    VERSION_FROM => '../lib/Net/NfDump.pm',
#	SKIP => [qw(all static static_lib dynamic dynamic_lib)],
	INC  => '-I ../libnf/include',
	C => [ 
		'libnf_perl.c',
		],	
#	SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	SKIP   => [qw(all static pure_all )],
#	CCFLAGS => '-DNSEL=1 -D__SUNPRO_C=1 ', # see note 
#	CCFLAGS => '-D__SUNPRO_C=1', # see note 
	clean => { 'FILES' => '*$(LIB_EXT) *$(OBJ_EXT) $(O_FILES)' },
);

# NOTE: in nfdump source code function format_number is defined as inline.
# With compiler with defined __SUNPRO_C it also adds extern.
# However some platforms (OSX, FreeBSD 9.x) requires extern inline 
# to make function available in the dinamic library, howevet it 
# produces some warnings on some platforms (Linux) 

sub MY::post_constants {
'
VERSION_MACRO = LIBNF_VERSION
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
';
}


sub MY::top_targets {
'
.NOTPARALLEL:

#NFOBJS = nffile grammar nfx minilzo nftree scanner util ipconv first

all :: static
pure_all :: static
static :: libnf_perl$(LIB_EXT)

libnf_perl$(LIB_EXT): $(O_FILES) libnf_perl.c 
		../libnf/src/libnf-info | ./info2fields.pl > ../lib/Net/NfDump/Fields.pm 
#		$(AR) x ../libnf/src/.libs/libnf.a
		$(CP) ../libnf/src/.libs/*.o .
		$(CP) ../libnf/src/ffilter/.libs/*.o .
		$(CP) ../libnf/bzip2/.libs/*.o .
		$(AR) cr libnf_perl$(LIB_EXT) *.o
		$(RANLIB) libnf_perl$(LIB_EXT)
';
}


