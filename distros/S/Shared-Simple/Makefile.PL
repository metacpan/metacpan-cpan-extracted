use 5.010;
use ExtUtils::MakeMaker;

package MY;
sub postamble {
    return <<'RULES';
src/shared$(OBJ_EXT): src/shared.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(PASTHRU_DEFINE) $(DEFINE) $(INC) src/shared.c -o src/shared$(OBJ_EXT)

src/oa_hash$(OBJ_EXT): src/oa_hash.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(PASTHRU_DEFINE) $(DEFINE) $(INC) src/oa_hash.c -o src/oa_hash$(OBJ_EXT)

README: lib/Shared/Simple.pm
	$(PERL) -MPod::Text -e "pod2text(q(lib/Shared/Simple.pm))" > README
RULES
}

package main;

my ($libs, $define);
if ($^O eq 'darwin') {
    $libs   = '-lpthread';
    $define = '-D_DARWIN_C_SOURCE';
} else {
    $libs   = '-lrt -lpthread';
    $define = '-D_POSIX_C_SOURCE=200809L';
}

WriteMakefile(
    NAME              => 'Shared::Simple',
    VERSION_FROM      => 'lib/Shared/Simple.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/Shared/Simple.pm',
    AUTHOR            => 'Denys Fisher <shmakins@gmail.com>',
    LICENSE           => 'perl',
    LIBS              => [$libs],
    DEFINE            => $define,
    INC               => '-I. -Isrc',
    OBJECT            => 'Simple$(OBJ_EXT) src/shared$(OBJ_EXT) src/oa_hash$(OBJ_EXT)',
    dist              => { PREOP => '$(PERL) -MPod::Text -e "pod2text(q(lib/Shared/Simple.pm))" > README' },
);
