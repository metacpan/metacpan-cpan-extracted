package Mylisp::SppAst;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(GetSppAst);

use Mylisp::Estr;

sub GetSppAst {
  my $json = <<'EOF'
[["door",["Rules",[["Rept",["+",["Branch",[["Rept",["+",["Cclass","s"]]],["Rtoken","_comm"],["Ntoken","Spec"]]]]],["Blank","b"],["Assert","$"]]]],["_comm",["Rules",[["Char","#"],["Till",["Assert","$$"]]]]],["Spec",["Rules",[["Ntoken","Token"],["Blank","b"],["Str","->"],["Blank","b"],["Rept",["+",["Branch",[["Ntoken","Blank"],["Ntoken","Branch"],["Ctoken","atom"]]]]],["Branch",[["Cclass","v"],["Assert","$"]]]]]],["Blank",["Rept",["+",["Cclass","h"]]]],["atom",["Branch",[["Ntoken","Group"],["Ntoken","Token"],["Ntoken","Str"],["Ntoken","String"],["Ntoken","Kstr"],["Ntoken","Cclass"],["Ntoken","Char"],["Ntoken","Chclass"],["Ntoken","Sym"],["Ntoken","Expr"],["Ntoken","Assert"],["Ntoken","Any"],["Ntoken","Rept"],["Ntoken","Till"]]]],["Branch",["Rules",[["Char","|"],["Blank","b"],["Rept",["+",["Branch",[["Rept",["+",["Cclass","s"]]],["Rtoken","_comm"],["Ctoken","atom"]]]]],["Blank","b"],["Char","|"]]]],["Group",["Rules",[["Char","{"],["Blank","b"],["Rept",["+",["Branch",[["Rept",["+",["Cclass","s"]]],["Rtoken","_comm"],["Ntoken","Branch"],["Ctoken","atom"]]]]],["Blank","b"],["Char","}"]]]],["Token",["Rept",["+",["Chclass",[["Cclass","a"],["Cchar","-"]]]]]],["Kstr",["Rules",[["Char",":"],["Rept",["+",["Chclass",[["Cclass","a"],["Cchar","-"]]]]]]]],["Str",["Rules",[["Char","'"],["Rept",["+",["Branch",[["Rept",["+",["Nclass",[["Cchar","\\"],["Cchar","'"]]]]],["Group",[["Char","\\"],["Any","."]]]]]]],["Char","'"]]]],["String",["Rules",[["Char","\""],["Rept",["+",["Branch",[["Rept",["+",["Nclass",[["Cchar","\\"],["Cchar","\""]]]]],["Group",[["Char","\\"],["Any","."]]]]]]],["Char","\""]]]],["Cclass",["Rules",[["Char","\\"],["Chclass",[["Cchar","a"],["Cchar","d"],["Cchar","h"],["Cchar","l"],["Cchar","s"],["Cchar","u"],["Cchar","v"],["Cchar","w"],["Cchar","x"],["Cchar","A"],["Cchar","D"],["Cchar","H"],["Cchar","L"],["Cchar","S"],["Cchar","U"],["Cchar","V"],["Cchar","W"],["Cchar","X"]]]]]],["Char",["Rules",[["Char","\\"],["Any","."]]]],["Chclass",["Rules",[["Char","["],["Blank","b"],["Rept",["?",["Ntoken","Flip"]]],["Rept",["+",["Branch",[["Cclass","s"],["Ntoken","Cclass"],["Ntoken","Char"],["Ntoken","Range"],["Ntoken","Cchar"]]]]],["Blank","b"],["Char","]"]]]],["Flip",["Char","^"]],["Range",["Rules",[["Cclass","w"],["Char","-"],["Cclass","w"]]]],["Cchar",["Nclass",[["Cclass","s"],["Cchar","]"],["Cchar","#"],["Cchar","\\"]]]],["Assert",["Branch",[["Str","^^"],["Str","$$"],["Char","^"],["Char","$"]]]],["Any",["Char","."]],["Rept",["Chclass",[["Cchar","?"],["Cchar","*"],["Cchar","+"]]]],["Till",["Char","~"]],["Sym",["Rules",[["Chclass",[["Cchar","@"],["Cchar","$"]]],["Rept",["+",["Chclass",[["Cclass","a"],["Cchar","-"]]]]]]]],["Sub",["Rept",["+",["Chclass",[["Cclass","a"],["Cchar","-"]]]]]],["Expr",["Rules",[["Char","("],["Blank","b"],["Rept",["+",["Ctoken","eatom"]]],["Blank","b"],["Char",")"]]]],["Array",["Rules",[["Char","["],["Blank","b"],["Rept",["*",["Ctoken","eatom"]]],["Blank","b"],["Char","]"]]]],["eatom",["Branch",[["Ntoken","Array"],["Ntoken","Sub"],["Ntoken","Sym"],["Ntoken","Kstr"]]]]]
EOF
;
  return json_to_estr($json);
}
1;
