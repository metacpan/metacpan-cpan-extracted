package Spp;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(ast_to_parser grammar_to_ast get_parser match spp_to_spp parse get_matcher match_matcher lint spp parse);

our $VERSION = '1.16';
use Spp::Builtin;
use Spp::IsChar;
use Spp::Ast;
use Spp::Grammar;
use Spp::Cursor;
use Spp::IsAtom;
use Spp::LintAst qw(lint_ast ast_to_table);
use Spp::Match qw(match_rule);
use Spp::OptAst qw(opt_spp_ast);
use Spp::ToSpp qw(ast_to_spp);

sub get_spp_parser {
   my $ast = get_spp_ast();
   lint_ast($ast);
   return ast_to_parser($ast);
}

sub ast_to_parser {
   my $ast   = shift;
   my $door  = $ast->[0][0];
   my $table = ast_to_table($ast);
   return [$door, $table];
}

sub grammar_to_ast {
   my $text   = shift;
   my $parser = get_spp_parser();
   my $match  = match($parser, $text, 0);
   if (is_false($match)) { die $match->[1] }
   return opt_spp_ast($match);
}

sub get_parser {
   my $text = shift;
   my $ast  = grammar_to_ast($text);
   lint_ast($ast);
   return ast_to_parser($ast);
}

sub eval_spp_ast {
   my $ast    = shift;
   my $parser = ast_to_parser($ast);
   my $table  = $parser->[1];
   if (exists $table->{'text'}) {
      my $text = get_text($table->{'text'});
      return match($parser, $text, 0);
   }
   return $ast;
}

sub get_text {
   my $rule = shift;
   if (is_atom_str($rule)) { return $rule->[1] }
   die "could not get Rule text!";
}

sub repl {
   my $parser = get_spp_parser();
   say "This is Spp REPL, type enter to exit.";
   while (1) {
      print ">> ";
      my $line = <STDIN>;
      exit() if $line eq "\n";
      $line = trim($line);
      my $match = match($parser, $line, 0);
      if (is_false($match)) {
         print $match->[1];
      }
      else {
         my $ast = opt_spp_ast($match);
         if (lint_ast($ast)) {
            $ast = eval_spp_ast($ast);
            say '.. ', to_json($ast);
         }
      }
   }
}

sub match {
   my ($parser, $text, $mode) = @_;
   my ($door, $table) = @{$parser};
   my $cursor = cursor($text, $table);
   my $door_rule = $cursor->{'ns'}{$door};
   $cursor->{'mode'} = $mode;
   my $match = match_rule($door_rule, $cursor);
   if (is_false($match)) {
      my $max_report = max_report($cursor);
      return ['false', $max_report];
   }
   if (is_true($match)) { return $match }
   my $char = first($door);
   if (is_char_upper($char)) { return [$door, $match] }
   if ($char eq '_') { return ['true'] }
   return $match;
}

sub update {
   my $grammar = get_spp_grammar();
   my $ast     = grammar_to_ast($grammar);
   if (lint_ast($ast)) {
      my $code = ast_to_perl_module($ast);
      if (-e 'Spp/Ast.pm') {
         rename('Spp/Ast.pm', 'Spp/Ast.pm.bak');
      }
      write_file('Spp/Ast.pm', $code);
   }
}

sub lint {
   my $grammar_file = shift;
   my $grammar_text = read_file($grammar_file);
   my $ast          = grammar_to_ast($grammar_text);
   lint_ast($ast);
}

sub spp_to_spp {
   my $str    = shift;
   my $parser = get_spp_parser();
   my $match  = match($parser, $str, 0);
   if (is_false($match)) {
      say "Could not match!";
      die $match->[1];
   }
   my $ast = opt_spp_ast($match);
   return ast_to_spp($ast);
}

sub parse {
   my ($grammar, $code, $mode) = @_;
   my $parser = get_parser($grammar);
   lint_parser($parser);
   my $match = match($parser, $code, $mode);
   if (is_false($match)) { die $match->[1] }
   return to_json($match);
}

sub spp {
   my ($grammar_file, $text_file) = @_;
   my $grammar = read_file($grammar_file);
   my $text    = read_file($text_file);
   return parse($grammar, $text);
}

sub get_matcher {
   my $grammar = shift;
   my $ast     = grammar_to_ast($grammar);
   my $table   = ast_to_table($ast);
   my $parser  = get_spp_parser();
   return [$parser, $table];
}

sub match_matcher {
   my ($matcher, $rule_text, $str) = @_;
   my ($spp_parser, $table) = @{$matcher};
   my $rule_spec    = "door = " . $rule_text;
   my $rule_ast     = match($spp_parser, $rule_spec, 0);
   if (is_false($rule_ast)) { die $rule_ast->[1] }
   my $opt_rule_ast = opt_spp_ast($rule_ast);
   my $rule         = $opt_rule_ast->[0][1];
   my $cursor       = cursor($str, $table);
   my $match        = match_rule($rule, $cursor);
   return is_match($match);
}

sub ast_to_perl_module {
   my $ast = shift;
   my $str = <<'EOFF';
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
