#!/usr/bin/perl -w
use strict;
#use Test::More tests=>4;
use Test::More qw{no_plan};
use_ok qw(Parse::Eyapp) or exit;

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

my $b = 4+ ;# Semantic error

sub Run {
    my($self)=shift;
    $in = shift;
    #$in = <>;
    $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, );
}
}; # end grammar

eval {
  Parse::Eyapp->new_grammar(input=>$grammar, chuchu => 4);
};

like($@, qr/Parse::Eyapp::Output::new_grammar Error!: unknown argumen/, 'Unknown arg for new_grammar');

eval {
  Parse::Eyapp->new_grammar(input=>$grammar, 4);
};

like($@, qr/Error in new_grammar: Use named argument/, 'Odd number of args for new_grammar');

eval {
  Parse::Eyapp->new_grammar(input=>$grammar);
};

like($@, qr/Error in  new_grammar: Please provide a name for the grammar/, 'class not provided for new_grammar');

eval {
  Parse::Eyapp->new_grammar(input=>$grammar, classname=>'AB', firstline => 9,); # outputfile => 'AB.pm')
};

like($@, qr/Error while compiling your parser:/, 'grammar has semantic errors');

