#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
use Test::More tests => 3;
use_ok qw(Parse::Eyapp) or exit;
use Data::Dumper;

my $grammar = q{
  %{
  use Data::Dumper;
  $Data::Dumper::Indent=1;
  %}

  %semantic token 'c' 
  %tree

  %%
  Start: %name ROOT S
  ;
  S: %name CC     
     'c' (',' 'c') <%name OPTIONALC ?>
  ;

  %%

  sub _Error {
          exists $_[0]->YYData->{ERRMSG}
      and do {
          print $_[0]->YYData->{ERRMSG};
          delete $_[0]->YYData->{ERRMSG};
          return;
      };
      print "Syntax error.\n";
  }

  sub _Lexer {
      my($parser)=shift;

          $parser->YYData->{INPUT}
      or  return('',undef);

      $parser->YYData->{INPUT}=~s/^[ \t\n]//;

      for ($parser->YYData->{INPUT}) {
          s/^(.)//s and return($1,$1);
      }
  }

  sub Run {
      my($self)=shift;
      $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error 
        #, yydebug => 0x1F 
      );
  }
};

$Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Optional',
  #outputfile => 'Optional.pm',
  firstline=>8,
);
my $parser = Optional->new();
$parser->YYData->{INPUT} = "c,c";
my $t = $parser->Run;
#print Dumper($t);
my $et = bless( {
  'children' => [
    bless( {
      'children' => [
        bless( {
          'children' => [],
          'attr' => 'c',
          'token' => 'c'
        }, 'TERMINAL' ),
        bless( {
          'children' => [
            bless( {
              'children' => [],
              'attr' => 'c',
              'token' => 'c'
            }, 'TERMINAL' )
          ]
        }, 'OPTIONALC' )
      ]
    }, 'CC' )
  ]
}, 'ROOT' );
is_deeply($t, $et,"optional c,c");

$parser->YYData->{INPUT} = "c";

$t = $parser->Run;
#print Dumper($t);
$et = bless( {
  'children' => [
    bless( {
      'children' => [
        bless( {
          'children' => [],
          'attr' => 'c',
          'token' => 'c'
        }, 'TERMINAL' ),
        bless( {
          'children' => []
        }, 'OPTIONALC' )
      ]
    }, 'CC' )
  ]
}, 'ROOT' );
is_deeply($t, $et,"optional c,c");
