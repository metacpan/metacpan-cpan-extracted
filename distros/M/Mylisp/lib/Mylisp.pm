package Mylisp;

our $VERSION = '1.05';

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(mylisp_to_ast to_ast);

use 5.012;
no warnings "experimental";
use Spp qw(match grammar_to_ast ast_to_parser);
use Mylisp::Grammar qw(get_mylisp_grammar);
use Mylisp::Ast qw(get_mylisp_ast);
use Mylisp::OptAst qw(opt_mylisp_ast);

# use Mylisp::Stable qw(stable);
# use Mylisp::LintAst qw(lint_mylisp_ast);
# use Mylisp::ToMylisp qw(ast_to_mylisp);
use Spp::IsAtom;
use Spp::LintParser qw(lint_parser);
use Spp::Builtin;

## test basic parse rule
sub repl {
   my $mylisp_ast = get_mylisp_ast();
   my $parser     = ast_to_parser($mylisp_ast);
   lint_parser($parser);
   say("This is Mylisp REPL, type enter to exit.");
   while (1) {
      print(">> ");
      my $line = <STDIN>;
      exit() if $line eq "\n";
      $line = trim($line);
      my $match = match($parser, $line, 2);
      if (is_false($match)) {
         say $match->[1];
      }
      else {
         # say("mat-> ", to_json($match));
         my $ast = opt_mylisp_ast($match);

         # say(".. ", to_json($ast));
         $ast = remove_ast_pos($ast);
         say(".. ", to_json($ast));

         # my $stable = stable($line);
         # lint_mylisp_ast($stable, $ast);
         # say ast_to_perl($ast);
      }
   }
}

sub to_ast {
   my $file = shift;
   my $text = read_file($file);
   my $ast  = mylisp_to_ast($text);
   $ast = remove_ast_pos($ast);
   say to_json($ast);
}

sub mylisp_to_ast {
   my $mylisp_text = shift;
   my $mylisp_ast  = get_mylisp_ast();
   my $parser      = ast_to_parser($mylisp_ast);
   my $match       = match($parser, $mylisp_text, 2);
   my $ast         = opt_mylisp_ast($match);
   return $ast;
}

sub remove_ast_pos {
   my $ast   = shift;
   my $exprs = [];
   for my $expr (@{$ast}) {
      if (is_atom($expr)) {
         push @{$exprs}, remove_atom_pos($expr);
      }
      elsif (is_perl_str($expr)) {
         push @{$exprs}, $expr;
      }
   }
   return $exprs;
}

sub remove_atom_pos {
   my $atom = shift;
   my ($name, $value, $pos) = @{$atom};
   if (is_perl_str($value)) {
      return [$name, $value];
   }
   if (is_atom($value)) {
      return [$name, remove_atom_pos($value)];
   }
   return [$name, remove_ast_pos($value)];
}

sub update {
   my $grammar_str = get_mylisp_grammar();
   my $ast         = grammar_to_ast($grammar_str);
   my $code        = write_mylisp_ast($ast);
   write_file("Ast.pm", $code);
   return 1;
}

sub write_mylisp_ast {
   my $ast = shift;
   my $str = <<'EOFF';
## Create by Mylisp::write_mylisp_ast()   
package Mylisp::Ast;

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
