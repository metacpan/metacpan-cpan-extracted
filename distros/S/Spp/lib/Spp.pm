package Spp;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(spp_repl match_text grammar_to_ast lint_grammar parse_text spp_to_spp);

our $VERSION = '2.03';
use Spp::Builtin;
use Spp::Tools;
use Spp::Ast;
use Spp::Grammar;
use Spp::Cursor;
use Spp::MatchRule;
use Spp::OptAst;
use Spp::LintAst;
use Spp::ToSpp;

sub spp_repl {
  my $spp_ast   = get_spp_ast();
  my $estr_ast  = to_ejson($spp_ast);
  my $table     = ast_to_table($estr_ast);
  my $door_rule = $table->{'door'};
  say 'This is Spp REPL, type enter to exit.';
  while (1) {
    print '>> ';
    my $line = <STDIN>;
    exit() if ord($line) == 10;
    my $cursor = new_cursor($line, $table);
    my $match = match_spp_rule($cursor, $door_rule);
    if (is_false($match)) { say fail_report($cursor) }
    else {
      say '.. ', see_ast($match);
      my $ast = opt_spp_ast($match);
      say '.. ', see_ast($ast);
    }
  }
}

sub match_text {
  my ($table, $text) = @_;
  my $rule   = $table->{'door'};
  my $cursor = new_cursor($text, $table);
  my $match  = match_spp_rule($cursor, $rule);
  if (is_false($match)) {
    my $report = fail_report($cursor);
    return $report, 0;
  }
  return $match, 1;
}

sub grammar_to_ast {
  my $grammar  = shift;
  my $spp_ast  = get_spp_ast();
  my $estr_ast = to_ejson($spp_ast);
  my $table    = ast_to_table($estr_ast);
  my ($match, $ok) = match_text($table, $grammar);
  if ($ok) {
    my $ast = opt_spp_ast($match);
    lint_spp_ast($ast);
    return $ast;
  }
  else { error($match) }
}

sub lint_grammar {
  my $grammar = shift;
  my $ast     = grammar_to_ast($grammar);
  lint_spp_ast($ast);
  return True;
}

sub parse_text {
  my ($grammar, $text) = @_;
  my $ast = grammar_to_ast($grammar);
  lint_spp_ast($ast);
  my $table = ast_to_table($ast);
  my ($match, $ok) = match_text($table, $text);
  if   ($ok) { return $match }
  else       { error($match) }
}

sub spp_to_spp {
  my $str     = shift;
  my $spp_ast = to_ejson(get_spp_ast());
  my $table   = ast_to_table($spp_ast);
  my ($match, $ok) = match_text($table, $str);
  if ($ok) {
    my $ast = opt_spp_ast($match);
    return ast_to_spp($ast);
  }
}
1;
