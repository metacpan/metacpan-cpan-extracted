package Mylisp::Ast;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(get_mylisp_ast);

use Spp::Builtin qw(from_json);

sub get_mylisp_ast {
  return from_json(
    <<'EOF'
[["mylisp",["Rules",[["Assert","^",[16,2,12,1]],["Rept",["+",["Branch",[["Rtoken","_"],["Rtoken","_pod"],["Ntoken","Expr"]]]]],["Assert","$",[33,2,29,1]]]]],["_",["Rept",["+",["Branch",[["Rept",["+",["Cclass","s"]]],["Rtoken","_comm"]]]]]],["_pod",["Rules",[["Str","=pod"],["Till",["Str","=end"]]]]],["_comm",["Rules",[["Char","#"],["Till",["Assert","$$",[113,6,18,2]]]]]],["Expr",["Rules",[["Char","("],["Rept",["+",["Branch",[["Rtoken","_"],["Ctoken","atom"]]]]],["Char",")"]]]],["atom",["Branch",[["Ntoken","Expr"],["Ntoken","Array"],["Ntoken","Hash"],["Ntoken","Lstr"],["Ntoken","Int"],["Ntoken","Kstr"],["Ntoken","Str"],["Ntoken","String"],["Ntoken","Char"],["Ntoken","Aindex"],["Ntoken","Arange"],["Ntoken","Hkey"],["Ntoken","Ocall"],["Ntoken","Onew"],["Ntoken","Oper"],["Ntoken","Sub"],["Ntoken","Var"]]]],["Int",["Rules",[["Rept",["?",["Char","-"]]],["Rept",["+",["Cclass","d"]]]]]],["Kstr",["Rules",[["Char",":"],["Rept",["+",["Chclass",[["Cclass","w"],["Char",":"]]]]]]]],["Lstr",["Rules",[["Char","'"],["Char","'"],["Char","'"],["Till",["Group",[["Char","'"],["Char","'"],["Char","'"]]]]]]],["Str",["Rules",[["Char","'"],["Rept",["*",["Branch",[["Ctoken","schars"],["Ctoken","char"]]]]],["Char","'"]]]],["schars",["Rept",["+",["Nchclass",[["Char","\\"],["Char","'"]]]]]],["char",["Rules",[["Char","\\"],["Any",".",[486,24,15,1]]]]],["String",["Rules",[["Char","\""],["Rept",["*",["Branch",[["Ntoken","Chars"],["Ntoken","Char"],["Ntoken","Scalar"]]]]],["Char","\""]]]],["Chars",["Rept",["+",["Nchclass",[["Char","\\"],["Char","\""],["Char","$"]]]]]],["Char",["Rules",[["Char","\\"],["Any",".",[571,28,15,1]]]]],["Scalar",["Rules",[["Char","$"],["Rept",["+",["Chclass",[["Cclass","a"],["Char","-"]]]]]]]],["Oper",["Rept",["+",["Chclass",[["Char","-"],["Char","+"],["Char","="],["Char",">"],["Char","<"],["Char","!"],["Char","~"],["Char","|"],["Char","&"]]]]]],["Sub",["Rules",[["Cclass","a"],["Rept",["*",["Chclass",[["Char","-"],["Cclass","w"],["Char",":"]]]]]]]],["Var",["Rules",[["Chclass",[["Char","$"],["Char","@"],["Char","%"]]],["Rept",["+",["Chclass",[["Char","-"],["Cclass","w"],["Char",":"],["Char","?"],["Char","+"]]]]]]]],["Array",["Rules",[["Char","["],["Rept",["*",["Branch",[["Rtoken","_"],["Char",","],["Ctoken","atom"]]]]],["Char","]"]]]],["Hash",["Rules",[["Char","{"],["Rept",["*",["Branch",[["Rtoken","_"],["Char",","],["Ntoken","Pair"]]]]],["Char","}"]]]],["Pair",["Rules",[["Branch",[["Ntoken","Kstr"],["Ntoken","Str"]]],["Rept",["*",["Cclass","s"]]],["Str","=>"],["Rept",["*",["Cclass","s"]]],["Ctoken","atom"]]]],["Aindex",["Rules",[["Ntoken","Var"],["Rept",["+",["Group",[["Char","["],["Ntoken","Int"],["Char","]"]]]]]]]],["Arange",["Rules",[["Ntoken","Var"],["Ntoken","Range"]]]],["Range",["Rules",[["Char","["],["Rept",["?",["Ntoken","From"]]],["Char",":"],["Rept",["?",["Ntoken","To"]]],["Char","]"]]]],["From",["Branch",[["Rept",["+",["Cclass","d"]]],["Group",[["Chclass",[["Char","$"]]],["Rept",["+",["Chclass",[["Cclass","a"],["Char","-"]]]]]]]]]],["To",["Branch",[["Group",[["Rept",["?",["Char","-"]]],["Rept",["+",["Cclass","d"]]]]],["Group",[["Chclass",[["Char","$"]]],["Rept",["+",["Chclass",[["Cclass","a"],["Char","-"]]]]]]]]]],["Hkey",["Rules",[["Ntoken","Var"],["Rept",["+",["Group",[["Char","["],["Branch",[["Ntoken","Kstr"],["Ntoken","Scalar"]]],["Char","]"]]]]]]]],["Ocall",["Rules",[["Ntoken","Var"],["Char","."],["Ntoken","Sub"]]]],["Onew",["Rules",[["Ntoken","Sub"],["Char","."],["Ntoken","Sub"]]]]]
EOF
  );
}
1;
