package Mylisp;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(my_repl get_my_parser my_to_ast);

our $VERSION = '2.03';
use Spp::Builtin;
use Spp::Tools;
use Spp;
use Mylisp::Grammar;
use Mylisp::OptAst;
use Mylisp::ToPerl;
use Mylisp::ToGo;

sub my_repl {
  my $parser = get_my_parser();
  say 'This is Mylisp REPL, type enter to exit.';
  while (1) {
    print '>> ';
    my $line = <STDIN>;
    exit() if ord($line) == 10;
    my ($match, $ok) = match_text($parser, $line);
    if ($ok) {
      say '.. ', see_ast($match);
      my $ast = opt_my_ast($match);
      say 'opt  => ', see_ast($ast);
      say 'go   => ', ast_to_go($ast);
      say 'perl => ', ast_to_perl_repl($ast);
    }
    else { say $match }
  }
}

sub get_my_parser {
  my $grammar = get_my_grammar();
  my $ast     = grammar_to_ast($grammar);
  return ast_to_table($ast);
}

sub my_to_ast {
  my $code   = shift;
  my $parser = get_my_parser();
  my ($match, $ok) = match_text($parser, $code);
  if   ($ok) { return opt_my_ast($match) }
  else       { error($match) }
}
1;
