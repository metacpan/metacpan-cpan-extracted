#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;
use_ok qw( Parse::Eyapp );

SKIP: {
  skip "developer test", 3 unless ($ENV{DEVELOPER} && ($ENV{DEVELOPER} eq 'casiano'));

  my $grammar = q{
    /* intermediate action and %tree */
    %{
    #use Data::Dumper;
    #$Data::Dumper::Indent = 1;

    sub tutu {
      print "Tutu:\n<@_>\n";
    }

    %}


    %%
    S:                 { print "S -> epsilon\n" }
        |   'a' 
             S 
                { tutu(@_) }
            'b'  { print "S -> a S b\n" }
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
        or  $parser->YYData->{INPUT} = <STDIN>
        or  return('',undef);

        $parser->YYData->{INPUT}=~s/^[ \t\n]//;

        for ($parser->YYData->{INPUT}) {
            s/^(.)//s and return($1,$1);
        }
    }
  };


  my $p = Parse::Eyapp->new_grammar(
    input=>$grammar,
    classname=>'aSb_int',
    firstline => 10,
    #outputfile => 'aSb_int.pm'
  );
  die $p->warnings."Solve Ambiguities. See file aSb_int.output\n"  if $p->Warnings;
  my $parser = new aSb_int();
  #print Dumper($parser);
  my $expected_parser = bless( {
    'DEBUG' => 0,
    'STACK' => [],
    'VALUE' => \undef,
    'STATES' => [
      {
        'GOTOS' => { 'S' => 1 },
        'ACTIONS' => { 'a' => 2 },
        'DEFAULT' => -1
      },
      {
        'ACTIONS' => { '' => 3 }
      },
      {
        'GOTOS' => { 'S' => 4 },
        'ACTIONS' => { 'a' => 2
        },
        'DEFAULT' => -1
      },
      {
        'DEFAULT' => 0
      },
      {
        'GOTOS' => { '@2-2' => 5 },
        'DEFAULT' => -3
      },
      {
        'ACTIONS' => { 'b' => 6 }
      },
      {
        'DEFAULT' => -2
      }
    ],
    'GRAMMAR' => [
      [ '_SUPERSTART', '$start', [ 'S', '$end' ] ],
      [ 'S_1', 'S', [] ],
      [ 'S_2', 'S', [ 'a', 'S', '@2-2', 'b' ] ],
      [ '_CODE', '@2-2', [] ]
    ],
    'RULES' => [
      [ '$start', 2, undef ],
      [ 'S', 0, sub { "DUMMY" } ],
      [ 'S', 4, sub { "DUMMY" } ],
      [ '@2-2', 0, sub { "DUMMY" } ]
    ],
    'CHECK' => \undef,
    'ERRST' => \undef,
    'PREFIX' => '',
    'DOTPOS' => \undef,
    'ERROR' => sub { "DUMMY" },
    'TOKEN' => \undef,
    'VERSION' => '1.06',
    'NBERR' => \undef,
    'TERMS' => {
      'a' => 0,
      'b' => 0,
      '$end' => 0
    }
  }, 'aSb_int' );

  is_deeply($expected_parser->{STATES}, $parser->{STATES}, "DFA states intermediate action");
  is_deeply([ 'S_2', 'S', [ 'a', 'S', '@2-2', 'b' ], 0 ], $parser->{GRAMMAR}[2], "GRAMMAR intermediate action");
  is_deeply([ '', 'a', 'b', 'error' ] , [ sort keys %{$parser->{TERMS}} ], "TERMS states intermediate action");
} # SKIP test
