require 5.005;
use ExtUtils::MakeMaker;

# Parasoft's Insure++!
@Safe = (
	 OPTIMIZE => '-g',
	 CC => 'insure',
	 LD => 'insure',
	)
    if 0;

WriteMakefile(
	      @Safe,
	      NAME => 'Rc',
	      VERSION_FROM => './lib/Rc.pm',
	      OBJECT => join(' ', qw(footobar.o lex.o input.o nalloc.o heredoc.o
				     y.tab.o print.o tree.o Rc.o)),
	      EXE_FILES => ['pl/rcconvert'],
	      macro => { YACC => 'yacc' }, #XXX
);

sub MY::postamble {
'
y.tab.c y.tab.h :: parse.y rc.h
	$(YACC) -d parse.y

lex.c :: y.tab.h

'
}
