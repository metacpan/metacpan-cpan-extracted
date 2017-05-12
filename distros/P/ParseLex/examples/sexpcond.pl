#!/usr/local/bin/perl -w

require 5.004; 
use strict;
BEGIN {  unshift @INC, "../lib"; }
package Parse::SExpressions;
use Parse::Lex;
@Parse::SExpressions::ISA = qw(Parse::Lex);

sub upto {
  my $self = shift;
  my $upto = shift;
  my $token;
  my @list = ();
  my $current = $self->getToken; # save the current token
  while (($token = $self->next)->type ne $upto) {
    push @list, $token->text;
  }
  $self->setToken($current);
  @list;
}

my %apply = (
	     '+' => sub {
	       my $r = shift;
	       foreach (@_) { $r += $_ }
	       $r;
	     },
	     '-' => sub {
	       my $r = shift;
	       foreach (@_) { $r -= $_ }
	       $r;
	     },
	     '*' => sub {
	       my $r = shift;
	       foreach (@_) {
		 $_ or return 0;
		 $r *= $_
	       }
	       $r;
	     },
	     '/' => sub {
	       my $r = shift;
	       foreach (@_) {
		 $_ or die "illegal division by 0";
		 $r /= $_;
	       }
	       $r;
	     },
	    );

Parse::Lex->exclusive('OPERATOR');
my $lexer;
Parse::Lex->trace;
$lexer = Parse::SExpressions->new(
				  'LEFTP' => '[\(]' => sub {
				    $lexer->start('OPERATOR');
				    my($operator, @operands) = $lexer->upto('RIGHTP');
				    &{$apply{$operator}}(@operands);
				  },
				  'RIGHTP' => '[\)]',
				  'OPERATOR:OPERATOR' => '[-+/*]' => sub { 
				    $lexer->end('OPERATOR'); 
				    $_[1]
				  },
				  'NUMBER' =>  '\d+', 
				  'ALL:ERROR' => '.*' => sub {	
				    if ($lexer->state('OPERATOR')) {
				      die qq!can\'t analyze: "$_[1]"\nOperator expected\n!;
				    } else {
				      die qq!can\'t analyze: "$_[1]"\n!;
				    }
				  }
				 );
my $sexp = '(* 2 (+ 3 3))';
$lexer->from($sexp);
print "result of $sexp: ", $lexer->next->text, "\n";

__END__


