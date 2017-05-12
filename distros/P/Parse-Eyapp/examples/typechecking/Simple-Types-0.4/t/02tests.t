#!/usr/bin/perl -w
use strict;
my ($nt, $nt2, $nt3, $nt4, $nt5, $nt6);

sub qmw {
  my $expected1 = shift;

  $expected1 =~ s/\s+//g;
  $expected1 = quotemeta($expected1);
  $expected1 = qr{$expected1};
  
  return $expected1;
}

BEGIN { $nt = 2; $nt2 = 3; $nt3 = 2;
}
use Test::More tests=> $nt + $nt2+$nt3;

# test -S option and PPCR methodology with Pascal range versus enumerated conflict
SKIP: {
  skip "t/prueba01.c not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/prueba01.c" 
                                                        && -x "./script/usetypes.pl");

  my $r = qx{perl -I./lib/ script/usetypes.pl t/prueba01.c 2>&1};

  ok(!$@,'t/prueba01.c executed as modulino');

  my $expected = q{
Type Error at line 8:  Variable 'e' declared with less than 2 dimensions
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'checking output for prueba01.c');

  ############################
}

SKIP: {
  skip "t/prueba02.c not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/prueba02.c" 
                                                        && -x "./script/usetypes.pl");


  my $r = qx{perl -I./lib/ script/usetypes.pl t/prueba02.c 1 2>&1};

  ok(!$@,'t/prueba02.c executed as modulino');

  my $expected1 = qmw q{
 1 int a,b,e[10];
 2 
 3 g() {}
 4 
 5 int f(char c) {
 6 char d;
 7  c = 'X';
 8  e[d][b] = 'A'+c;
 9  { 
10    int d;
11    d = a + b;
12  }
13  c = d * 2;
14  return c;
15 }
16 

};
  my $expected2 = qmw q{
Type Error at line 8:  Variable 'e' declared with less than 2 dimensions
};

  $r =~ s/\s+//g;


  like($r, $expected1,'checking output for prueba02.c');

  like($r, $expected2,'checking err for prueba02.c');

  ############################
}

SKIP: {
  skip "t/prueba03.c not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/prueba03.c" 
                                                        && -x "./script/usetypes.pl");


  my $r = qx{perl -I./lib/ script/usetypes.pl t/prueba03.c 1 2>&1};

  ok(!$@,'t/prueba03.c executed as modulino');

  my $expected1 = qmw q{
 1 int a,b,e[10];
 2 
 3 g() {}
 4 
 5 int f(char c) {
 6 char d;
 7  c = 'X';
 8  e[d] = 'A'+c;
 9  { 
10    int d;
11    d = a + b;
12  }
13  a = b * 2;
14  return c;
15 }
16 

PROGRAM^{0}(
  FUNCTION[g]^{1},
  FUNCTION[f]^{2}(
    ASSIGNCHAR(
      VAR(
        TERMINAL[c:7]
      ),
      CHARCONSTANT(
        TERMINAL['X':7]
      )
    ),
    ASSIGNINT(
      VARARRAY(
        TERMINAL[e:8],
        INDEXSPEC(
          CHAR2INT(
            VAR(
              TERMINAL[d:8]
            )
          )
        )
      ),
      PLUS(
        CHAR2INT(
          CHARCONSTANT(
            TERMINAL['A':8]
          )
        ),
        CHAR2INT(
          VAR(
            TERMINAL[c:8]
          )
        )
      )
    ),
    BLOCK[9:3:f]^{3}(
      ASSIGNINT(
        VAR(
          TERMINAL[d:11]
        ),
        PLUS(
          VAR(
            TERMINAL[a:11]
          ),
          VAR(
            TERMINAL[b:11]
          )
        )
      )
    ),
    ASSIGNINT(
      VAR(
        TERMINAL[a:13]
      ),
      TIMES(
        VAR(
          TERMINAL[b:13]
        ),
        INUM(
          TERMINAL[2:13]
        )
      )
    ),
    RETURNINT(
      CHAR2INT(
        VAR(
          TERMINAL[c:14]
        )
      )
    )
  )
)
---------------------------
0)
Types:
$VAR1 = {
  'A_10(INT)' => bless( {
    'children' => [
      bless( {
        'children' => []
      }, 'INT' )
    ]
  }, 'A_10' ),
  'F(X_1(CHAR),INT)' => bless( {
    'children' => [
      bless( {
        'children' => [
          bless( {
            'children' => []
          }, 'CHAR' )
        ]
      }, 'X_1' ),
      $VAR1->{'A_10(INT)'}{'children'}[0]
    ]
  }, 'F' ),
  'CHAR' => $VAR1->{'F(X_1(CHAR),INT)'}{'children'}[0]{'children'}[0],
  'VOID' => bless( {
    'children' => []
  }, 'VOID' ),
  'INT' => $VAR1->{'A_10(INT)'}{'children'}[0],
  'F(X_0(),INT)' => bless( {
    'children' => [
      bless( {
        'children' => []
      }, 'X_0' ),
      $VAR1->{'A_10(INT)'}{'children'}[0]
    ]
  }, 'F' )
};
Symbol Table:
$VAR1 = {
  'e' => {
    'type' => 'A_10(INT)',
    'line' => 1
  },
  'a' => {
    'type' => 'INT',
    'line' => 1
  },
  'b' => {
    'type' => 'INT',
    'line' => 1
  },
  'g' => {
    'type' => 'F(X_0(),INT)',
    'line' => 3
  },
  'f' => {
    'type' => 'F(X_1(CHAR),INT)',
    'line' => 5
  }
};

---------------------------
1)
$VAR1 = {};

---------------------------
2)
$VAR1 = {
  'c' => {
    'type' => 'CHAR',
    'param' => 1,
    'line' => 5
  },
  'd' => {
    'type' => 'CHAR',
    'line' => 6
  }
};

---------------------------
3)
$VAR1 = {
  'd' => {
    'type' => 'INT',
    'line' => 10
  }
};

};

  $r =~ s/\s+//g;


  like($r, $expected1,'checking output for prueba02.c');

  ############################
}

