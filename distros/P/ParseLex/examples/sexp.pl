#!/usr/local/bin/perl -w

require 5.004; 
use strict;
use lib "../lib";

package Parse::SymbolicExpressions;
use Parse::Lex;
@Parse::SymbolicExpressions::ISA = qw(Parse::Lex);

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
	       my $r;
	       foreach (@_) { $r += $_ }
	       $r;
	     },
	     '-' => sub {
	       my $r;
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

my @token = (
	     'LEFTP' => '[\(]' => sub {
	       my($operator, @operands) = shift->lexer->upto('RIGHTP');
	       &{$apply{$operator}}(@operands);
	     },
	     'RIGHTP' => '[\)]', 
	     'OPERATOR' => '[-+/*]',
	     'NUMBER' =>  '\d+',
	     'ERROR' => '.*' => sub {
	       die qq!can\'t analyze: "$_[1]"\n!;
	     }
	    );

my $lexer = Parse::SymbolicExpressions->new(@token);

my $exp = '(* 2 (+ 3 3))';
$lexer->from($exp);
print "result of $exp: ", $lexer->next->text, "\n";

__END__


