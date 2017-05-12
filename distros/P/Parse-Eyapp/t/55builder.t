#!/usr/bin/perl -w
use strict;
use Test::More tests=>3;
use_ok qw(Parse::Eyapp::Node) or exit;

my $string = 'ASSIGN(VAR(TERMINAL), TIMES(NUM(TERMINAL),NUM(TERMINAL)))  ';
my @t = Parse::Eyapp::Node->new($string, sub { my $i = 0; $_->{n} = $i++ for @_ });

my $expected = [
  bless( {
    'n' => 0,
    'children' => [
      bless( {
        'n' => 1,
        'children' => [
          bless( {
            'n' => 2,
            'children' => []
          }, 'TERMINAL' )
        ]
      }, 'VAR' ),
      bless( {
        'n' => 3,
        'children' => [
          bless( {
            'n' => 4,
            'children' => [
              bless( {
                'n' => 5,
                'children' => []
              }, 'TERMINAL' )
            ]
          }, 'NUM' ),
          bless( {
            'n' => 6,
            'children' => [
              bless( {
                'n' => 7,
                'children' => []
              }, 'TERMINAL' )
            ]
          }, 'NUM' )
        ]
      }, 'TIMES' )
    ]
  }, 'ASSIGN' ),
  {},
  {},
  {},
  {},
  {},
  {},
  {}
];
$expected->[1] = $expected->[0]{'children'}[0];
$expected->[2] = $expected->[0]{'children'}[0]{'children'}[0];
$expected->[3] = $expected->[0]{'children'}[1];
$expected->[4] = $expected->[0]{'children'}[1]{'children'}[0];
$expected->[5] = $expected->[0]{'children'}[1]{'children'}[0]{'children'}[0];
$expected->[6] = $expected->[0]{'children'}[1]{'children'}[1];
$expected->[7] = $expected->[0]{'children'}[1]{'children'}[1]{'children'}[0];


is_deeply($expected, \@t, 'Parse::Eyapp::Node->new with blanks at the end');

$string = '         ASSIGN(   VAR(    TERMINAL), TIMES(   NUM(TERMINAL),   NUM(   TERMINAL) )   )  ';
@t = Parse::Eyapp::Node->new($string, sub { my $i = 0; $_->{n} = $i++ for @_ });

is_deeply($expected, \@t, 'Parse::Eyapp::Node->new with blanks in the middle');


