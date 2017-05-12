#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
use Test::More tests => 4;
use_ok qw(Parse::Eyapp) or exit;
#use Parse::Eyapp;
# use Data::Dumper;
use_ok qw( Parse::Eyapp::Treeregexp );

my $grammar = q{

%semantic token 'a' 'b' 'c'
%tree

%%

S: %name ABC
     A B C
 | %name BC
     B C
;

A: %name A
     'a' 
;

B: %name B
     'b'
;

C: %name C
    'c'
;
%%

sub _Error {
  die "Syntax error.\n";
}

my $in;

sub _Lexer {
    my($parser)=shift;

    {
      $in  or  return('',undef);

      $in =~ s/^\s+//;

      $in =~ s/^([AaBbCc])// and return($1,$1);
      $in =~ s/^(.)//s and print "<$1>\n";
      redo;
    }
}

sub Run {
    my($self)=shift;
    $in = shift;
    $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, );
}
}; # end grammar

# $Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(input=>$grammar, classname=>'AB', firstline => 9,); # outputfile => 'AB.pm');
my $parser = AB->new();
my $t = $parser->Run("abc");
#print "\n***** Before ******\n";
# print Dumper($t);

my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
   delete_b_in_abc : /BC|ABC/(@a, B, @c)
     => { @{$_[0]->{children}} = (@a, @c) }
  },
  SEVERITY => 0,
  #OUTPUTFILE => 'main.pm',
);
$p->generate();

our (@all);
$t->s(@all);
# print "\n***** After ******\n";
# print Dumper($t);

my $expected_tree = bless( {
  'children' => [
    bless( {
      'children' => [
        bless( { 'children' => [], 'attr' => 'a', 'token' => 'a' }, 'TERMINAL' )
      ]
    }, 'A' ),
    bless( {
      'children' => [
        bless( { 'children' => [], 'attr' => 'c', 'token' => 'c' }, 'TERMINAL' )
      ]
    }, 'C' )
  ]
}, 'ABC' );
is_deeply($t, $expected_tree, "or regexp as father and two arrays: abc");

$t = $parser->Run("bc");
$t->s(@all);
$expected_tree = bless( {
  'children' => [
    bless( {
      'children' => [
        bless( { 'children' => [], 'attr' => 'c', 'token' => 'c' }, 'TERMINAL' )
      ]
    }, 'C' )
  ]
}, 'BC' );
is_deeply($t, $expected_tree, "or regexp as father and two arrays:bc");
