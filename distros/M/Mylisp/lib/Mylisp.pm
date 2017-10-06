package Mylisp;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(mylisp_to_ast get_mylisp_parser);

our $VERSION = '2.0';
use Spp qw(match_text spp_to_ast ast_to_parser);
use Spp::Builtin qw(uuid is_false error to_json clean_ast write_file see_ast);
use Mylisp::Grammar qw(get_mylisp_grammar);
use Mylisp::Ast qw(get_mylisp_ast);
use Mylisp::OptAst qw(opt_ast);
use Mylisp::ToPerl qw(ast_to_perl ast_to_perl_repl);
use Mylisp::Lint;

sub get_mylisp_parser {
   my $mylisp_ast = get_mylisp_ast();
   Spp::lint_ast($mylisp_ast);
   return ast_to_parser($mylisp_ast);
}

sub repl {
   my $parser = get_mylisp_parser();
   say 'This is Mylisp REPL, type enter to exit.';
   while (1) {
      print '>> ';
      my $line = <STDIN>;
      exit() if $line eq "\n";
      my $match = match_text($parser, $line);
      if (is_false($match)) {
         my $error_report = $match->[1];
         error($error_report);
      }
      say 'match ->    ', to_json(clean_ast($match));
      my $ast = opt_ast($match);
      say 'opt-ast   -> ', to_json(clean_ast($ast));
      my $lint = new_lint($line);
      lint_ast($lint, $ast);
      my $perl_code = ast_to_perl_repl($ast);
      say 'perl-code-> ', $perl_code;
      # my $mylisp_code = to_mylisp($ast);
      # say 'mylisp code -> ', $mylisp_code;
   }
}

sub mylisp_to_ast {
   my $text = shift;
   my $parser = get_mylisp_parser();
   my $match  = match_text($parser, $text);
   # say see_ast($match); exit();
   print "Matching ok ..";
   my $ast = opt_ast($match);
   print "Opt ok ..";
   #my $lint = new_lint($text);
   #lint_ast($lint, $ast);
   # say to_json($ast);
   $ast = clean_ast($ast);
   return $ast;
}

sub update {
   my $grammar = get_mylisp_grammar();
   my $ast     = spp_to_ast($grammar);
   my $code    = write_mylisp_ast($ast);
   my $uuid = substr(time(), 0, 5);
   rename('Mylisp/Ast.pm', "Mylisp/Ast.pm.$uuid");
   write_file('Mylisp/Ast.pm', $code);
}

sub write_mylisp_ast {
   my $ast = shift;
   my $str = <<'EOFF';
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
