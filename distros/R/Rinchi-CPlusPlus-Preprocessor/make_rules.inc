include_path.o: include_path.c include_path.h

option.o: option.c option.def tree.h

parser_routines.o: parser_routines.c parser_routines.h lexer.h tree.h include_path.h

Preprocessor.o: Preprocessor.c Preprocessor.h

rinchi_string.o: rinchi_string.c rinchi_string.h

toperl.o: toperl.c lexer.h Preprocessor.h parser_routines.h parser.tab.h

tree.o: tree.c tree.h parser.tab.h lexer.h node.def token.def

.PHONY: parser
parser: parser.tab.o lexer.o

lexer.c: lexer.l parser.tab.h tree.h
	flex -o$@ -Pyypp_ $<

lexer.o: lexer.c parser.tab.h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $<

parser.tab.c: parser.y
	bison -d -k -t $<

parser.tab.h: parser.y
	bison -d -k -t $<

parser.tab.o: parser.tab.c parser.tab.h parser_routines.h tree.h lexer.h parser_routines.h lexer.h include_path.h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $<

blib/arch/auto/Rinchi/CPlusPlus/Preprocessor/Preprocessor.so: \
  Preprocessor.o\
  include_path.o\
  option.o\
  parser.tab.o\
  parser_routines.o\
  lexer.o\
  toperl.o\
  tree.o
