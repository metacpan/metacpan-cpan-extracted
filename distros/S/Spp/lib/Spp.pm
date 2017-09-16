package Spp;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(ast_to_parser grammar_to_ast grammar_to_parser match
     spp_to_spp parse lint spp parse lint_spp_ast);

our $VERSION = '1.22';
use Spp::Builtin;
use Spp::Core;
use Spp::Ast;
use Spp::Grammar;
use Spp::Cursor;
use Spp::LintAst qw(lint_spp_ast);
use Spp::MatchRule qw(match_rule);
use Spp::OptAst qw(opt_spp_ast);
use Spp::ToSpp  qw(ast_to_spp);

sub get_spp_parser {
   my $ast = get_spp_ast();
   lint_spp_ast($ast);
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
   my $match  = match($parser, $text);
   if (is_false($match)) { error($match->[1]) }
   return opt_spp_ast($match);
}

sub grammar_to_parser {
   my $text = shift;
   my $ast  = grammar_to_ast($text);
   lint_spp_ast($ast);
   $ast = clean_ast($ast);
   return ast_to_parser($ast);
}

sub eval_spp_ast {
   my $ast    = shift;
   my $parser = ast_to_parser($ast);
   my $table  = $parser->[1];
   if (exists $table->{'text'}) {
      my $text = get_text($table->{'text'});
      return match($parser, $text);
   }
   return $ast;
}

sub get_text {
   my $rule = shift;
   if (is_atom_str($rule)) { return $rule->[1] }
   error("could not get Rule text!");
}

sub repl {
   my $parser = get_spp_parser();
   say "This is Spp REPL, type enter to exit.";
   while (1) {
      print ">> ";
      my $line = <STDIN>;
      exit() if $line eq "\n";
      my $match = match($parser, $line);
      if (is_false($match)) {
         print $match->[1];
      }
      else {
         my $ast = opt_spp_ast($match);
         if (lint_spp_ast($ast)) {
            $ast = eval_spp_ast($ast);
            say '.. ', to_json(clean_ast($ast));
         }
      }
   }
}

sub match {
   my ($parser, $text) = @_;
   my ($door, $table) = @{$parser};
   my $door_rule = $table->{$door};
   my $cursor = Spp::Cursor->new($text, $table);
   my $match = match_rule($door_rule, $cursor);
   if (is_false($match)) {
      my $max_report = $cursor->max_report;
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
   if (lint_spp_ast($ast)) {
      my $code = ast_to_perl_module($ast);
      if (-e 'Spp/Ast.pm') {
         rename('Spp/Ast.pm', 'Spp/Ast.pm.bak');
      }
      write_file('Spp/Ast.pm', $code);
   }
}

sub lint {
   my $file = shift;
   my $grammar = read_file($file);
   my $ast     = grammar_to_ast($grammar);
   lint_spp_ast($ast);
}

sub spp_to_spp {
   my $str    = shift;
   my $parser = get_spp_parser();
   my $match  = match($parser, $str);
   if (is_false($match)) {
      say "Could not match!";
      error($match->[1]);
   }
   my $ast = opt_spp_ast($match);
   return ast_to_spp($ast);
}

sub parse {
   my ($grammar, $code) = @_;
   my $parser = grammar_to_parser($grammar);
   my $match = match($parser, $code);
   if (is_false($match)) { error($match->[1]) }
   return $match if is_true($match);
   return to_json(clean_ast($match));
}

sub spp {
   my ($grammar_file, $text_file) = @_;
   my $grammar = read_file($grammar_file);
   my $text    = read_file($text_file);
   return parse($grammar, $text);
}

sub ast_to_perl_module {
   my $ast = shift;
   my $str = <<'EOFF';
package Spp::Ast;

use 5.012;
no warnings "experimental";

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
