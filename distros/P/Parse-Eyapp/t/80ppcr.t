#!/usr/bin/perl -w
use strict;
my ($nt, $nt2, $nt3, $nt4, $nt5, $nt6, $nt7, $nt8, $nt9, $nt10, $nt11, $nt12, $nt13, $nt14);

BEGIN { 
  $nt = 8; 
  $nt2 = 7; 
  $nt3 = 11; 
  $nt4 = 7; 
  $nt5 = 7; 
  $nt6 = 6;
  $nt7 = 7;
  $nt8 = 7;
  $nt9 = 9;
  $nt10 = 8;
  $nt11 = 8;
  $nt12 = 6;
  $nt13 = 7;
  $nt14 = 11;
}
use Test::More tests=> $nt+$nt2+$nt3+$nt4+$nt5+$nt6+$nt7+$nt8+$nt9+$nt10+$nt11+$nt12+$nt13+$nt14;

# test PPCR methodology with Pascal range versus enumerated conflict
SKIP: {
  skip "t/pascalnestedeyapp2.eyp not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/pascalnestedeyapp2.eyp" 
                                                        #&& $^V ge v5.10.0
                                                        && -r "t/Range.eyp" 
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -Po t/Range.pm t/Range.eyp 2>&1});
  ok(!$r, "Auxiliary grammar Range.yp compiled with option -P");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/pascalnestedeyapp2.eyp});
  ok(!$r, "Pascal conflict grammar compiled");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c 'type r = (x) .. (y); 4'};

  };

  ok(!$@,'t/pascalnestedeyapp2.eyp executed as modulino');

  my $expected = q{

typeDecl_is_type_ID_type_expr(
  TERMINAL[r],
  RANGE(
    ID(
      TERMINAL[x]
    ),
    ID(
      TERMINAL[y]
    )
  ),
  NUM(
    TERMINAL[4]
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type r = (x) .. (y); 4"');

  ############################
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c 'type r = (x,y,z); 8'};

  };

  ok(!$@,'t/pascalnestedeyapp2.eyp executed as modulino');

  $expected = q{

typeDecl_is_type_ID_type_expr(
  TERMINAL[r],
  ENUM(
    idList_is_idList_ID(
      idList_is_idList_ID(
        ID(
          TERMINAL[x]
        ),
        TERMINAL[y]
      ),
      TERMINAL[z]
    )
  ),
  NUM(
    TERMINAL[8]
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type r = (x,y,z); 8"');

  unlink 't/ppcr.pl';
  unlink 't/Range.pm';

}

SKIP: {
  skip "t/noPackratSolvedExpRG2.eyp not found", $nt2 unless ($ENV{DEVELOPER} 
                                                        && -r "t/noPackratSolvedExpRG2.eyp"
                                                        && -r "t/ExpList.eyp" 
                                                        #&& $^V ge v5.10.0
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -Po t/ExpList.pm t/ExpList.eyp});
  ok(!$r, "Auxiliary grammar ExpList.yp compiled witn -P option");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/noPackratSolvedExpRG2.eyp 2> t/err});
  ok(!$r, "S->xSx|x grammar compiled");
  like(qx{cat t/err},qr{1 shift/reduce conflict},"number of conflicts eq 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c '2-3 3*4 5+2 other things' 2>&1};

  };

  ok(!$@,'t/noPackratSolvedExpRG2.eyp executed as modulino');

  my $expected = q{
Number of x's = 3
nxr = 1 nxs = 1
Shifting input: '*4 5+2 other things'
nxr = 1 nxs = 2
Reducing by :MIDx nxs = 2 nxr = 1 input: '+2 other things'

T_is_S_other_things(
  S_is_x_S_x(
    x_is_NUM_OP_x(
      TERMINAL[2],
      TERMINAL[-],
      x_is_NUM(
        TERMINAL[3]
      )
    ),
    S_is_x(
      x_is_NUM_OP_x(
        TERMINAL[3],
        TERMINAL[*],
        x_is_NUM(
          TERMINAL[4]
        )
      )
    ),
    x_is_NUM_OP_x(
      TERMINAL[5],
      TERMINAL[+],
      x_is_NUM(
        TERMINAL[2]
      )
    )
  )
)
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "2-3 3*4 5+2"');

  unlink 't/ppcr.pl';
  unlink 't/ExpList.pm';
  unlink 't/err';

}

# testing eyapp option -P

SKIP: {
  skip "t/Calc.eyp not found", $nt3 unless ($ENV{DEVELOPER} && -x "./eyapp"); 
  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -PTC -o t/ppcr.pl t/Calc.eyp 2> t/err});
  ok(!$r, "Calc.eyp  compiled with opt P");
  ok(-s 't/err' == 0, "no errors during compilation");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  # a prefix is acceptable but the whole string isn't
  eval {

    $r = qx{perl -Ilib t/ppcr.pl -t -c 'a=2\@'};

  };

  ok(!$@,'t/Calc.eyp accepts strict prefix');

  my $expected = q{
$VAR1 = {
          'a' => bless( {
                          'children' => [
                                          bless( {
                                                   'children' => [],
                                                   'attr' => '2',
                                                   'token' => 'NUM'
                                                 }, 'TERMINAL' )
                                        ]
                        }, 'exp_is_NUM' )
        };

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "a=2@"');

  unlink 't/err';
  unlink 't/ppcr.pl';
  unlink 't/ExpList.pm';

  #without -P option

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/Calc.eyp 2> t/err});
  ok(!$r, "Calc.eyp  compiled without opt P");
  ok(-s 't/err' == 0, "no errors during compilation");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib t/ppcr.pl -t -c 'a=2\@' 2>&1};

  };

  $expected = q{

Syntax error near input: '@' (lin num 1). 
Expected one of these terminals: -, , /, ^, *, +, 

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'error as expected for "a=2@"');

  unlink 't/err';
  unlink 't/ppcr.pl';
  unlink 't/ExpList.pm';
  unlink 't/err';
}

# testing the use of the same conflict handler in different grammar
# sections
SKIP: {
  skip "t/reuseconflicthandler.eyp not found", $nt4 unless ($ENV{DEVELOPER} 
                                                        && -r "t/reuseconflicthandler.eyp"
                                                        && -r "t/ExpList.eyp" 
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -Po t/ExpList.pm t/ExpList.eyp});
  ok(!$r, "Auxiliary grammar ExpList.yp compiled witn -P option");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/reuseconflicthandler.eyp 2> t/err});
  ok(!$r, "repeated conflicts grammar compiled");
  like(qx{cat t/err},qr{1 shift/reduce conflict},"number of conflicts eq 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c '2-3 3*4 5+2 ; 4+8 3-1 2*3 ;' 2>&1};

  };

  ok(!$@,'t/reuseconflicthandler.eyp executed as modulino');

  my $expected = q{
Number of x's = 3
Reducing by :MIDx input = '+2 ; 4+8 3-1 2*3 ; '
Number of x's = 3
Reducing by :MIDx input = '*3 ; '

T_is_S_S(
  S_is_x_S_x(
    x_is_NUM_OP_x(
      TERMINAL[2],
      TERMINAL[-],
      x_is_NUM(
        TERMINAL[3]
      )
    ),
    S_is_x(
      x_is_NUM_OP_x(
        TERMINAL[3],
        TERMINAL[*],
        x_is_NUM(
          TERMINAL[4]
        )
      )
    ),
    x_is_NUM_OP_x(
      TERMINAL[5],
      TERMINAL[+],
      x_is_NUM(
        TERMINAL[2]
      )
    )
  ),
  S_is_x_S_x(
    x_is_NUM_OP_x(
      TERMINAL[4],
      TERMINAL[+],
      x_is_NUM(
        TERMINAL[8]
      )
    ),
    S_is_x(
      x_is_NUM_OP_x(
        TERMINAL[3],
        TERMINAL[-],
        x_is_NUM(
          TERMINAL[1]
        )
      )
    ),
    x_is_NUM_OP_x(
      TERMINAL[2],
      TERMINAL[*],
      x_is_NUM(
        TERMINAL[3]
      )
    )
  )
)
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,q{AST for '2-3 3*4 5+2 ; 4+8 3-1 2*3 ;'} );

  unlink 't/ppcr.pl';
  unlink 't/ExpList.pm';
  unlink 't/err';

}

# testing PPCR with CplusplusNested.eyp
# testing nested parsing (YYPreParse) when one token 
# has been read by the outer parser
SKIP: {
  skip "t/CplusplusNested.eyp not found", $nt5 unless ($ENV{DEVELOPER} 
                                                        && -r "t/CplusplusNested.eyp"
                                                        && -r "t/Decl.eyp" 
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -Po t/Decl.pm t/Decl.eyp});
  ok(!$r, "Auxiliary grammar Decl.eyp compiled witn -P option");

  $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/CplusplusNested.eyp 2> t/err});
  ok(!$r, "t/CplusplusNested.eyp grammar compiled");
  like(qx{cat t/err},qr{^$},"no warning: %expect-rr 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) + 2; int (z) = 4;' 2>&1};

  };

  ok(!$@,'t/CplusplusNested.eyp executed as modulino');

  my $expected = q{
PROG(PROG(EMPTY,EXP(TYPECAST(TERMINAL[int],ID[x]),NUM[2])),DECL(TERMINAL[int],ID[z],NUM[4]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) + 2; int (z) = 4;"');

  unlink 't/ppcr.pl';
  unlink 't/Decl.pm';
  unlink 't/err';

}

# testing PPCR with dynamic.eyp
SKIP: {
  skip "t/dynamic.eyp not found", $nt6 unless ($ENV{DEVELOPER} 
                                                        && -r "t/dynamic.eyp"
                                                        && -r "t/input_for_dynamicgrammar.txt"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/dynamic.eyp 2> t/err});
  ok(!$r, "t/dynamic.eyp grammar compiled");
  like(qx{cat t/err},qr{^$},"no warning: %expect-rr 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -f t/input_for_dynamicgrammar.txt 2>&1};

  };

  ok(!$@,'t/dynamic.eyp executed as modulino');

  my $expected = q{
0
2
1
3
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) + 2; int (z) = 4;"');

  unlink 't/ppcr.pl';
  unlink 't/err';

}

SKIP: {
  skip "t/DebugDynamicResolution4.eyp not found", $nt7 unless ($ENV{DEVELOPER} 
                                                        && -r "t/DebugDynamicResolution4.eyp"
                                                        && -r "t/lastD.eyp" 
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -Po t/lastD.pm t/lastD.eyp});
  ok(!$r, "Auxiliary grammar lastD.eyp compiled witn -P option");

  $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/DebugDynamicResolution4.eyp 2> t/err});
  ok(!$r, "t/DebugDynamicResolution4.eyp grammar compiled");
  like(qx{cat t/err},qr{1 shift/reduce conflict},"1 shift-reduce conflict");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'D; D; S; S ' 2>&1};

  };

  ok(!$@,'t/DebugDynamicResolution4.eyp executed as modulino');

  my $expected = q{
PROG(D(D),SS(S)
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "D; D; S; S "');

  unlink 't/ppcr.pl';
  unlink 't/lastD.pm';
  unlink 't/err';

}

SKIP: {
  skip "t/CplusplusNested4.eyp not found", $nt8 unless ($ENV{DEVELOPER} 
                                                        && -r "t/CplusplusNested4.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -S decl -Po t/decl.pm t/CplusplusNested4.eyp});
  ok(!$r, "Auxiliary parser decl.pm generated from t/CplusplusNested4.eyp");

  $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/CplusplusNested4.eyp 2> t/err});
  ok(!$r, "t/CplusplusNested4.eyp grammar compiled");
  is(qx{cat t/err},'',"no warnings");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) + 2; int (z) = 4; ' 2>&1};

  };

  ok(!$@,'t/CplusplusNested4.eyp executed as modulino');

  my $expected = q{
PROG(PROG(EMPTY,EXP(TYPECAST(TERMINAL[int],ID[x]),NUM[2])),DECL(TERMINAL[int],ID[z],NUM[4])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) + 2; int (z) = 4; "');

  unlink 't/ppcr.pl';
  unlink 't/decl.pm';
  unlink 't/err';

}

SKIP: {
  skip "t/pascalnestedeyapp3_6.eyp not found", $nt9 unless ($ENV{DEVELOPER} 
                                                        && -r "t/pascalnestedeyapp3_6.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -S range -Po t/range.pm t/pascalnestedeyapp3_6.eyp});
  ok(!$r, "Auxiliary parser decl.pm generated from t/pascalnestedeyapp3_6.eyp");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/pascalnestedeyapp3_6.eyp 2> t/err});
  ok(!$r, "t/pascalnestedeyapp3_6.eyp grammar compiled");
  is(qx{cat t/err},'',"no warnings");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'type e = (x)..(z);' 2>&1};

  };

  ok(!$@,'t/pascalnestedeyapp3_6.eyp executed as modulino');

  my $expected = q{
typeDecl_is_type_ID_type(TERMINAL[e],RANGE(range_is_expr_expr(ID(TERMINAL[x]),ID(TERMINAL[z]))))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type e = (x)..(z);"');

  ###################################################
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'type e = (x, y, z);' 2>&1};

  };

  ok(!$@,'t/pascalnestedeyapp3_6.eyp executed as modulino');

  $expected = q{
typeDecl_is_type_ID_type(TERMINAL[e],ENUM(idList_is_idList_ID(idList_is_idList_ID(ID(TERMINAL[x]),TERMINAL[y]),TERMINAL[z]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type e = (x, y, z);"');

  unlink 't/ppcr.pl';
  unlink 't/decl.pm';
  unlink 't/err';

}

# 10 # testing syntax
#           %conflict DORF /.*?d/? XY:D : XY:F
SKIP: {
  skip "t/confusingsolvedppcr.eyp not found", $nt10 unless ($ENV{DEVELOPER} 
                                                        && -r "t/confusingsolvedppcr.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/confusingsolvedppcr.eyp 2> t/err});
  ok(!$r, "t/confusingsolvedppcr.eyp grammar compiled");
  like(qx{cat t/err},qr{1 reduce/reduce conflict\s*},"1 rr conflict");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'x y c d' 2>&1};

  };

  ok(!$@,'t/confusingsolvedppcr.eyp executed as modulino');

  my $expected = q{
Bcd(XY(TERMINAL[x],TERMINAL[y]),TERMINAL[c],TERMINAL[d])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "x y c d"');

  ###################################################
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'x y c f' 2>&1};

  };

  ok(!$@,'t/confusingsolvedppcr.eyp executed as modulino');

  $expected = q{
Ecf(XY(TERMINAL[x],TERMINAL[y]),TERMINAL[c],TERMINAL[f])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "x y c f"');

  unlink 't/ppcr.pl';
  unlink 't/decl.pm';
  unlink 't/err';

}

# 11 # testing syntax
#           %conflict DORF !/.*?d/? XY:F : XY:D
SKIP: {
  skip "t/confusingsolvedppcrnot.eyp not found", $nt11 unless ($ENV{DEVELOPER} 
                                                        && -r "t/confusingsolvedppcrnot.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/confusingsolvedppcrnot.eyp 2> t/err});
  ok(!$r, "t/confusingsolvedppcrnot.eyp grammar compiled");
  like(qx{cat t/err},qr{1 reduce/reduce conflict\s*},"1 rr conflict");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'x y c d' 2>&1};

  };

  ok(!$@,'t/confusingsolvedppcrnot.eyp executed as modulino');

  my $expected = q{
Bcd(XY(TERMINAL[x],TERMINAL[y]),TERMINAL[c],TERMINAL[d])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "x y c d"');

  ###################################################
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'x y c f' 2>&1};

  };

  ok(!$@,'t/confusingsolvedppcrnot.eyp executed as modulino');

  $expected = q{
Ecf(XY(TERMINAL[x],TERMINAL[y]),TERMINAL[c],TERMINAL[f])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "x y c f"');

  unlink 't/ppcr.pl';
  unlink 't/decl.pm';
  unlink 't/err';

}

# 12 # testing syntax
#           %conflict DORF /.*?d/? XY:D : XY:F
SKIP: {
  skip "t/DebugDynamicResolution2.eyp not found", $nt12 unless ($ENV{DEVELOPER} 
                                                        && -r "t/DebugDynamicResolution2.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/DebugDynamicResolution2.eyp 2> t/err});
  ok(!$r, "t/DebugDynamicResolution2.eyp grammar compiled");
  like(qx{cat t/err},qr{1 shift/reduce conflict\s*},"1 sr conflict");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'D;D;D;S;S;S' 2>&1};

  };

  ok(!$@,'t/DebugDynamicResolution2.eyp executed as modulino');

  my $expected = q{
PROG(D(D(D)),SS(SS(S)))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "D;D;D;S;S;S"');

  unlink 't/ppcr.pl';
  unlink 't/decl.pm';
  unlink 't/err';

}

SKIP: {
  skip "t/CplusplusNested5.eyp not found", $nt13 unless ($ENV{DEVELOPER} 
                                                        && -r "t/CplusplusNested5.eyp"
                                                        && -x "./eyapp"
                                                        && ( -d 't/Tutu' or mkdir 't/Tutu'));

  unlink 't/ppcr.pl';


  my $r = system(q{perl -I./lib/ eyapp -m Tutu::decl -o t/Tutu/decl.pm -S decl -P t/CplusplusNested5.eyp});
  ok(!$r, "Auxiliary parser decl.pm generated from t/CplusplusNested5.eyp");

  $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/CplusplusNested5.eyp 2> t/err});
  ok(!$r, "t/CplusplusNested5.eyp grammar compiled");
  is(qx{cat t/err},'',"no warnings");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) + 2; int (z) = 4; ' 2>&1};

  };

  ok(!$@,'t/CplusplusNested5.eyp executed as modulino');

  my $expected = q{
PROG(PROG(EMPTY,EXP(TYPECAST(TERMINAL[int],ID[x]),NUM[2])),DECL(TERMINAL[int],ID[z],NUM[4])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) + 2; int (z) = 4; "');

  unlink 't/ppcr.pl';
  unlink 't/Tutu/decl.pm';
  rmdir  't/Tutu';
  unlink 't/err';

}

SKIP: {
  skip "t/AmbiguousLanguage2.eyp not found", $nt14 unless ($ENV{DEVELOPER} 
                                                        && -r "t/AmbiguousLanguage2.eyp"
                                                        && -r "t/ab.eyp"
                                                        && -x "./eyapp"
                                                        && ( -d 't/Tutu' or mkdir 't/Tutu'));

  unlink 't/ppcr.pl';


  my $r = system(q{perl -I./lib/ eyapp -m Tutu::ab -o t/Tutu/ab.pm -P t/ab.eyp});
  ok(!$r, "Auxiliary parser Tutu/ab.pm generated from t/ab.eyp");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/AmbiguousLanguage2.eyp 2> t/err});
  ok(!$r, "t/AmbiguousLanguage2.eyp grammar compiled");
  is(qx{cat t/err},"1 shift/reduce conflict and 1 reduce/reduce conflict\n","1 sr and 1rr warnings");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  ########## abbcc
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'abbcc' 2>&1};

  };

  ok(!$@,'t/AmbiguousLanguage2.eyp executed as modulino');

  my $expected = q{
st_is_s(_OPTIONAL,s_is_beqc(beqc_is_as_bc(as_is_as_a(BC),bc_is_b_bc_c(bc_is_b_bc_c(bc_is_empty)))))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "abbcc"');

  ########## aabb
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'aabb' 2>&1};

  };

  ok(!$@,'t/AmbiguousLanguage2.eyp executed as modulino');

  $expected = q{
st_is_s(_OPTIONAL,s_is_aeqb(aeqb_is_ab_cs(ab_is_a_ab_b(ab_is_a_ab_b(ab_is_empty)),cs_is_empty))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "aabb"');


  ########## bbcc
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'bbcc' 2>&1};

  };

  ok(!$@,'t/AmbiguousLanguage2.eyp executed as modulino');

  $expected = q{
st_is_s(_OPTIONAL,s_is_beqc(beqc_is_as_bc(BC,bc_is_b_bc_c(bc_is_b_bc_c(bc_is_empty)))))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'AST for "bbcc"');

  unlink 't/ppcr.pl';
  unlink 't/Tutu/ab.pm';
  rmdir  't/Tutu';
  unlink 't/err';

}
