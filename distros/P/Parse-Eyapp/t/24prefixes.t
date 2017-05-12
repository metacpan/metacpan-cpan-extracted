#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
use Test::More tests => 4;
use_ok qw(Parse::Eyapp) or exit;
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
    #$in = <>;
    $self->YYParse(); 
}
}; # end grammar

# $Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'AB', 
  #firstline => 9, 
  #outputfile => 'AB.pm',
  linenumbers => 0
);
my $parser = AB->new(yyprefix => 'Parse::Eyapp::Node::', 
                     yylex => \&AB::_Lexer, 
		     yyerror => \&AB::_Error,);
my $t = $parser->Run("abc");
#print "\n***** Before ******\n";
# print Dumper($t);

my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
   delete_b_in_abc : $x(@a, B, @c)
     => { @{$_[0]->{children}} = (@a, @c) }
  },
  #OUTPUTFILE => 'main.pm',
  PREFIX => 'Parse::Eyapp::Node::'
);
$p->generate();

our (@all);
$t->s(@all);
#print "\n***** After ******\n";
# print Dumper($t);

my $expected_tree = bless( { 'children' => [
    bless( { 'children' => [
        bless( { 'children' => [], 'attr' => 'a', 'token' => 'a' }, 'Parse::Eyapp::Node::TERMINAL' )
      ]
    }, 'Parse::Eyapp::Node::A' ),
    bless( { 'children' => [
        bless( { 'children' => [], 'attr' => 'c', 'token' => 'c' }, 'Parse::Eyapp::Node::TERMINAL' )
      ]
    }, 'Parse::Eyapp::Node::C' )
  ]
}, 'Parse::Eyapp::Node::ABC' );

is_deeply($t, $expected_tree, "prefixing and transfoming: abc");

# new test
$t = $parser->Run("bc");
$t->s(@all);
$expected_tree = bless( { 'children' => [
    bless( { 'children' => [
        bless( { 'children' => [], 'attr' => 'c', 'token' => 'c' }, 'Parse::Eyapp::Node::TERMINAL' )
      ]
    }, 'Parse::Eyapp::Node::C' )
  ]
}, 'Parse::Eyapp::Node::BC' );
is_deeply($t, $expected_tree, "prefixing and transfoming: bc");


