package Spp;

use 5.012;
no warnings "experimental";

our $VERSION = '1.13';

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_parser match parse spp_to_spp
  get_matcher match_matcher grammar_to_ast ast_to_parser);

use Spp::Ast qw(get_spp_ast);
use Spp::Grammar qw(get_spp_grammar);
use Spp::Builtin;
use Spp::Cursor;
use Spp::LintParser qw(lint_parser);
use Spp::Match qw(match match_rule);
use Spp::OptSppAst qw(opt_spp_ast);
use Spp::IsAtom;
use Spp::ToSpp qw(ast_to_spp);

sub ast_to_table {
   my $ast   = shift;
   my $table = {};
   for my $spec (@{$ast}) {
      my ($name, $rule) = @{$spec};
      if (exists $table->{$name}) {
         say("repeat token define $name");
      }
      $table->{$name} = $rule;
   }
   return $table;
}

sub ast_to_parser {
   my $ast   = shift;
   my $door  = $ast->[0][0];
   my $table = ast_to_table($ast);
   return [$door, $table];
}

sub get_spp_parser {
   my $ast = get_spp_ast();
   return ast_to_parser($ast);
}

sub grammar_to_ast {
   my $text   = shift;
   my $parser = get_spp_parser();
   my $match  = match($parser, $text);

   # say to_json($match);
   return opt_spp_ast($match);
}

sub get_parser {
   my $grammar_text = shift;
   my $ast          = grammar_to_ast($grammar_text);
   return ast_to_parser($ast);
}

sub eval_spp_ast {
   my $ast    = shift;
   my $parser = ast_to_parser($ast);
   if (exists $parser->[1]->{'text'}) {
      my $text = get_text($parser->[1]->{'text'});
      return match($parser, $text);
   }
   if (exists $parser->[1]->{'file'}) {
      my $file = get_text($parser->[1]->{'file'});
      my $text = read_file($file);
      return match($parser, $text);
   }
   return $ast;
}

sub get_text {
   my $rule = shift;
   return $rule->[1] if is_str_atom($rule);
   die "could not get Rule text not Str atom";
}

## test basic parse rule
sub repl {
   my $parser = get_spp_parser();
   lint_parser($parser);
   say("This is Spp REPL, type enter to exit.");
   while (1) {
      print(">> ");
      my $line = <STDIN>;
      exit() if $line eq "\n";
      $line = trim($line);
      my $match = match($parser, $line);
      if (is_false($match)) {
         print $match->[1];
      }
      else {
         # say("match-> ", to_json($match));
         my $ast = opt_spp_ast($match);

         # say ast_to_spp($ast);
         $ast = eval_spp_ast($ast);
         say(".. ", to_json($ast));
      }
   }
}

sub spp_to_spp {
   my $str    = shift;
   my $parser = get_spp_parser();
   my $match  = match($parser, $str);
   if (is_false($match)) {
      return "Could not match";
   }
   else {
      my $ast = opt_spp_ast($match);
      return ast_to_spp($ast);
   }
}

# should add lang to --lang mylisp --action update
sub update {
   my $grammar_str = get_spp_grammar();
   my $ast         = grammar_to_ast($grammar_str);
   my $code        = write_spp_ast($ast);
   write_file("SppAst.pm", $code);
   say("write SppAst.pm ok!");
}

# --action lint --grammar grammar.file
sub lint {
   my $grammar_file = shift;
   my $grammar_text = read_file($grammar_file);
   my $ast          = grammar_to_ast($grammar_text);
   my $parser       = ast_to_parser($ast);
   lint_parser($parser);
}

sub parse {
   my ($grammar_text, $code_text, $mode) = @_;
   my $parser = get_parser($grammar_text);

   # exit();
   lint_parser($parser);

   # say to_json($parser); exit();
   return match($parser, $code_text, $mode);
}

# --action spp --grammar grammar.file --target target.file
sub spp {
   my ($grammar_file, $text_file) = @_;
   my $grammar = read_file($grammar_file);
   my $text    = read_file($text_file);
   return parse($grammar, $text);
}

sub get_matcher {
   my $grammar_text = shift;
   my $ast          = grammar_to_ast($grammar_text);
   my $table        = ast_to_table($ast);
   my $spp_parser   = get_spp_parser();
   return [$spp_parser, $table];
}

sub match_matcher {
   my ($matcher, $rule_text, $str) = @_;
   my ($spp_parser, $table) = @{$matcher};
   my $rule_spec    = "door = " . $rule_text;
   my $rule_ast     = match($spp_parser, $rule_spec);
   my $opt_rule_ast = opt_spp_ast($rule_ast);
   my $rule         = $opt_rule_ast->[0][1];
   my $cursor       = cursor($str, $table);
   my $match        = match_rule($rule, $cursor);
   return is_match($match);
}

sub write_spp_ast {
   my $ast = shift;
   my $str = <<'EOFF';
## Create by Spp::write_spp_ast()   
package Spp::Ast;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_spp_ast);

use Spp::Builtin qw(from_json);

sub get_spp_ast {
   return from_json(<<'EOF'
EOFF
   return $str . to_json($ast) . "\nEOF\n) }\n1;";
}

1;
