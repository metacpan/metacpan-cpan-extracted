package Mylisp;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(mylisp_to_ast);

our $VERSION = '1.08';
use Spp qw(lint_spp_ast match grammar_to_ast ast_to_parser);
use Spp::Builtin;
use Spp::Core;
use Mylisp::Grammar qw(get_mylisp_grammar);
use Mylisp::Ast qw(get_mylisp_ast);
use Mylisp::OptAstAtom qw(opt_ast_atom);
use Mylisp::OptAstMacro qw(opt_ast_macro);
use Mylisp::Stable;
use Mylisp::ToPerl qw(ast_to_perl ast_to_perl_repl);

sub repl {
   my $mylisp_ast = get_mylisp_ast();
   my $parser     = ast_to_parser($mylisp_ast);
   say 'This is Mylisp REPL, type enter to exit.';
   while (1) {
      print '>> ';
      my $line = <STDIN>;
      exit() if $line eq "\n";
      $line = trim($line);
      my $match = match($parser, $line);
      if (is_false($match)) {
         my $error_report = $match->[1];
         error($error_report);
      }
      # say 'match ->    ', to_json($match);
      my $ast = opt_ast_atom($match);
      # say 'opt-atom -> ', to_json(clean_ast($ast));
      $ast = opt_ast_macro($ast);
      say 'opt-macro -> ', to_json(clean_ast($ast));
      # $ast = get_ast_type_ast($ast);
      # say 'type-ast  -> ', to_json($ast);
      # $ast = clean_type_ast($ast);
      # say 'clean-ast -> ', to_json($ast);
      my $stable = Mylisp::Stable->new($line);
      $stable->lint_ast($ast);
      # say '.. ', to_json(clean_ast($ast));
      # say to_json($ast);
      my $perl_code = ast_to_perl_repl($ast);
      say 'perl-code-> ', $perl_code;

   }
}

sub mylisp_to_ast {
   my $text = shift;
   my $mylisp_ast  = get_mylisp_ast();
   lint_spp_ast($mylisp_ast);
   my $parser = ast_to_parser($mylisp_ast);
   my $match  = match($parser, $text);
   if (is_false($match)) {
      my $error_report = $match->[1];
      error($error_report);
   }
   print "Matching ok ..";
   my $ast = opt_ast_atom($match);
   print "Opt atom ok ..";
   my $opt_ast = opt_ast_macro($ast);
   say "Opt Macro ok ..";
   # my $stable = Mylisp::Stable->new($text);
   # $stable->lint_ast($opt_ast);
   return $opt_ast;
}

sub update {
   my $grammar = get_mylisp_grammar();
   my $ast     = grammar_to_ast($grammar);
   my $code    = write_mylisp_ast($ast);
   rename('Mylisp/Ast.pm', 'Mylisp/Ast.pm.bak');
   write_file('Mylisp/Ast.pm', $code);
}

sub write_mylisp_ast {
   my $ast = shift;
   my $str = <<'EOFF';
## Create by Mylisp::write_mylisp_ast()   
package Mylisp::Ast;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_mylisp_ast);

use Spp::Builtin qw(from_json);

sub get_mylisp_ast {
   return from_json(<<'EOF'
EOFF
   return $str . to_json($ast) . "\nEOF\n) }\n1;";
}

1;
