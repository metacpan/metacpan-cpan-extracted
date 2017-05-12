use strict;
use ExtUtils::MakeMaker;
use File::Spec;

WriteMakefile(
    NAME                => 'RTF::Lexer',
    VERSION_FROM        => 'Lexer.pm.PL',
    INC                 => ' -I. ',
    PM                  => { 
              'Lexer.pm' => File::Spec->catfile('$(INST_LIBDIR)', 'Lexer.pm'),
                           },
    OBJECT              => '$(O_FILES)',
    clean               => { FILES => '$(DO_LEX)rtfparser.c Lexer.pm' },
    macro               => { DO_LEX => 'no'},
);

# To rebuild flex-generated scanner run
#   make DO_LEX=
sub MY::postamble {
  <<'EOF';
$(DO_LEX)rtfparser.c: rtfparser.l
	flex -ortfparser.c rtfparser.l || lex -ortfparser.c rtfparser.l

EOF
}

