#!/usr/bin/perl -w
use strict;
my ($nt, $nt6, $nt7, $nt8, $nt9, $nt10, $nt11, $nt12);
my $skips;

BEGIN { 
  $nt = 5; 
  $skips = 4; 
  $nt6 = 1;
  $nt7 = 7;
  $nt8 = 9;
  $nt9 = 9;
  $nt10 = 15;
  $nt11 = 11;
  $nt12 = 23;
}
use Test::More 'no_plan'; #tests=> $skips*$nt+$nt6+$nt7+$nt8+$nt9+$nt10+$nt11+$nt12;


SKIP: {
  skip "t/numlist.eyp not found", $nt unless ($ENV{DEVELOPER} && -r "t/numlist.eyp" && -x "./eyapp");

  unlink 't/numlist.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -s -o t/numlist.pl t/numlist.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/numlist.pl", "modulino standalone exists");

  ok(-x "t/numlist.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/numlist.pl -t -i -c '4 a b'};

  };

  ok(!$@,'t/numlist.eyp executed as standalone modulino');

  my $expected = q{
A_is_A_B(A_is_A_B(A_is_B(B_is_NUM(TERMINAL[4])),B_is_a(TERMINAL[a])),B_is_ID(TERMINAL[b]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "4 a b"');

  unlink 't/numlist.pl';

}

SKIP: {
  skip "t/simplewithwhites.eyp not found", $nt unless ($ENV{DEVELOPER} && -r "t/simplewithwhites.eyp" && -r "t/inputfor77" && -x "./eyapp");

  unlink 't/simplewithwhites.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -s -o t/simplewithwhites.pl t/simplewithwhites.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/simplewithwhites.pl", "modulino standalone exists");

  ok(-x "t/simplewithwhites.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/simplewithwhites.pl -t -i -f t/inputfor77};

  };

  ok(!$@,'t/simplewithwhites.eyp executed as standalone modulino');

  my $expected = q{
A_is_A_d(A_is_a(TERMINAL[a]),TERMINAL[d])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for file "t/inputfor77"');

  unlink 't/simplewithwhites.pl';

}

SKIP: {
  skip "t/tokensemdef.eyp not found", $nt unless ($ENV{DEVELOPER} && -r "t/tokensemdef.eyp" && -r "t/input2for77" && -x "./eyapp");

  unlink 't/tokensemdef.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -s -o t/tokensemdef.pl t/tokensemdef.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/tokensemdef.pl", "modulino standalone exists");

  ok(-x "t/tokensemdef.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/tokensemdef.pl -t -i -f t/input2for77};

  };

  ok(!$@,'t/tokensemdef.eyp executed as standalone modulino');

  my $expected = q{
A_is_A_B(A_is_A_B(A_is_B(B_is_NUM(TERMINAL[4])),B_is_a(TERMINAL[a])),B_is_ID(TERMINAL[b]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for file "t/input2for77"');

  unlink 't/tokensemdef.pl';

}

SKIP: {
  skip "t/quotemeta.eyp not found", $nt unless ($ENV{DEVELOPER} && -r "t/quotemeta.eyp" && -x "./eyapp");

  unlink 't/quotemeta.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -s -o t/quotemeta.pl t/quotemeta.eyp});
  
  ok(!$r, "standalone option for quotemeta.eyp");

  ok(-s "t/quotemeta.pl", "modulino standalone exists");

  ok(-x "t/quotemeta.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/quotemeta.pl -t -i -m 1 -c '43 + - * []'};

  };

  ok(!$@,'t/quotemeta.eyp executed as standalone modulino');

  my $expected = q{

s_is_s(
  s_is_s(
    s_is_s(
      s_is_s(
        s_is_NUM(
          TERMINAL
        ),
        TERMINAL[+]
      ),
      TERMINAL[-]
    ),
    TERMINAL[*]
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for file "43 + - * []"');

  unlink 't/quotemeta.pl';

}

SKIP: {
  skip "t/quotemeta2.eyp not found", $nt6 unless ($ENV{DEVELOPER} && -r "t/quotemeta2.eyp" && -r "t/input2for77" && -x "./eyapp");

  unlink 't/quotemeta2.pl';

  system(q{perl -I./lib/ eyapp -TC -s -o t/quotemeta2.pl t/quotemeta2.eyp 2> t/err});
  
  my $r = qx{cat t/err};

  my $expected = q{
*Error* Unexpected input: '=', at line 1 at file t/quotemeta2.eyp
*Fatal* Errors detected: No output, at eof at file t/quotemeta2.eyp
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,q{Error for %semantic token '+' = /(\+)/});

  unlink 't/err';

}

SKIP: {
  skip "t/dummytoken.eyp not found", $nt7 unless ($ENV{DEVELOPER} && -r "t/dummytoken.eyp" && -x "./eyapp");

  unlink 't/dummytoken.pl';

  my $r = system(q{perl -I./lib/ eyapp -C -s -o t/dummytoken.pl t/dummytoken.eyp 2> t/err});
  
  ok(!$r, "standalone option");
  
  $r = qx{cat t/err};

  is($r, '', q{no errors during compilation '%dummy token'});

  unlink 't/err';

  ok(-s "t/dummytoken.pl", "modulino standalone exists");

  ok(-x "t/dummytoken.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/dummytoken.pl -t -i -m 1 -c 'if e then if e then o else o'};

  };

  ok(!$@,'t/dummytoken.eyp executed as standalone modulino');

  my $expected = q{

IFTHEN(
  TERMINAL[e],
  IFTHENELSE(
    TERMINAL[e],
    TERMINAL[o],
    TERMINAL[o]
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if e then if e then o else o"');

  eval {

    $r = qx{t/dummytoken.pl -t -i -m 1 -c 'TUTU' 2>&1};

  };

  $expected = q{

Syntax error near 'TUTU'. 
Expected terminal: 'end of input'
There were 1 errors during parsing

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'dummy token produces error');

  unlink 't/dummytoken.pl';

}

SKIP: {
  skip "t/PL_I_conflictWithLexical.eyp not found", $nt8 unless ($ENV{DEVELOPER} && -r "t/PL_I_conflictWithLexical.eyp" && -x "./eyapp");

  unlink 't/PL_I_conflictWithLexical.pl';

  my $r = system(q{perl -I./lib/ eyapp -C -s -o t/PL_I_conflictWithLexical.pl t/PL_I_conflictWithLexical.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/PL_I_conflictWithLexical.pl", "modulino standalone exists");

  ok(-x "t/PL_I_conflictWithLexical.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/PL_I_conflictWithLexical.pl -t -i -c 'if if=then then then=if'};

  };

  ok(!$@,'t/PL_I_conflictWithLexical.eyp executed as standalone modulino');

  my $expected = q{
IF(TERMINAL[if],EQ(ID[if],ID[then]),TERMINAL[then],ASSIGN(ID[then],ID[if]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if if=then then then=if"');

  eval {

    $r = qx{t/PL_I_conflictWithLexical.pl -t -i -c 'if then=if then if=then'};

  };

  ok(!$@,'t/PL_I_conflictWithLexical.eyp executed as standalone modulino');

  $expected = q{
IF(TERMINAL[if],EQ(ID[then],ID[if]),TERMINAL[then],ASSIGN(ID[if],ID[then]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if then=if then if=then"');

  eval {

    $r = qx{t/PL_I_conflictWithLexical.pl -t -i -c 'if then=if then if a=b then c=d'};

  };

  ok(!$@,'t/PL_I_conflictWithLexical.eyp executed as standalone modulino');

  $expected = q{
IF(TERMINAL[if],EQ(ID[then],ID[if]),TERMINAL[then],
   IF(TERMINAL[if],EQ(ID[a],ID[b]),TERMINAL[then],ASSIGN(ID[c],ID[d]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if then=if then if a=b then c=d"');

  unlink 't/PL_I_conflictWithLexical.pl';

}

SKIP: {
  skip "t/PL_I_conflictContextualTokens.eyp not found", $nt9 unless ($ENV{DEVELOPER} && -r "t/PL_I_conflictContextualTokens.eyp" && -x "./eyapp");

  unlink 't/PL_I_conflictContextualTokens.pl';

  my $r = system(q{perl -I./lib/ eyapp -C -s -o t/PL_I_conflictContextualTokens.pl t/PL_I_conflictContextualTokens.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/PL_I_conflictContextualTokens.pl", "modulino standalone exists");

  ok(-x "t/PL_I_conflictContextualTokens.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/PL_I_conflictContextualTokens.pl -t -i -c 'if if=then then then=if'};

  };

  ok(!$@,'t/PL_I_conflictContextualTokens.eyp executed as standalone modulino');

  my $expected = q{
IF(TERMINAL[if],EQ(ID[if],ID[then]),TERMINAL[then],ASSIGN(ID[then],ID[if]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if if=then then then=if"');

  eval {

    $r = qx{t/PL_I_conflictContextualTokens.pl -t -i -c 'if then=if then if=then'};

  };

  ok(!$@,'t/PL_I_conflictContextualTokens.eyp executed as standalone modulino');

  $expected = q{
IF(TERMINAL[if],EQ(ID[then],ID[if]),TERMINAL[then],ASSIGN(ID[if],ID[then]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if then=if then if=then"');

  eval {

    $r = qx{t/PL_I_conflictContextualTokens.pl -t -i -c 'if then=if then if a=b then c=d'};

  };

  ok(!$@,'t/PL_I_conflictContextualTokens.eyp executed as standalone modulino');

  $expected = q{
IF(TERMINAL[if],EQ(ID[then],ID[if]),TERMINAL[then],
   IF(TERMINAL[if],EQ(ID[a],ID[b]),TERMINAL[then],ASSIGN(ID[c],ID[d]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if then=if then if a=b then c=d"');

  unlink 't/PL_I_conflictContextualTokens.pl';

}

SKIP: {
  skip "t/PLIConflictNested.eyp not found", $nt10 unless ($ENV{DEVELOPER} && -r "t/PLIConflictNested.eyp" && -x "./eyapp");

  unlink 't/PLIConflictNested.pl';
  unlink 't/Assign2.pm';

  my $r = system(q{perl -I./lib/ eyapp -P -o t/Assign2.pm  t/Assign2.eyp});
  
  ok(!$r, "aux standalone option");

  ok(-s "t/Assign2.pm", "aux module Assign2 exists");

  $r = system(q{perl -I./lib/ eyapp -C -o t/PLIConflictNested.pl t/PLIConflictNested.eyp});
  
  ok(!$r, "compiled t/PLIConflictNested.eyp");

  ok(-s "t/PLIConflictNested.pl", "modulino exists");

  ok(-x "t/PLIConflictNested.pl", "modulino has execution permits");


    $r = qx{perl -It t/PLIConflictNested.pl -t -i -c 'if if=then then then=if'};


  ok(!$@,'t/PLIConflictNested.eyp executed as standalone modulino');

  my $expected = q{
IF(TERMINAL[if],EQ(ID[if],ID[then]),TERMINAL[then],ASSIGN(ID[then],ID[if]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if if=then then then=if"');

  eval {

    $r = qx{perl -It t/PLIConflictNested.pl -t -i -c 'if then=if then if=then'};

  };

  ok(!$@,'t/PLIConflictNested.eyp executed as standalone modulino');

  $expected = q{
IF(TERMINAL[if],EQ(ID[then],ID[if]),TERMINAL[then],ASSIGN(ID[if],ID[then]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if then=if then if=then"');

  eval {

    $r = qx{perl -It t/PLIConflictNested.pl -t -i -c 'if then=if then if a=b then c=d'};

  };

  ok(!$@,'t/PLIConflictNested.eyp executed as standalone modulino');

  $expected = q{
IF(TERMINAL[if],EQ(ID[then],ID[if]),TERMINAL[then],
   IF(TERMINAL[if],EQ(ID[a],ID[b]),TERMINAL[then],ASSIGN(ID[c],ID[d]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if then=if then if a=b then c=d"');

  unlink 't/PLIConflictNested.pl';
  unlink 't/Assign2.pm';

}

# Checking syntax: %token if   = %/(if)\b/=Assign2
SKIP: {
  skip "t/PLIConflictNested2.eyp not found", $nt10 unless ($ENV{DEVELOPER} && -r "t/PLIConflictNested2.eyp" && -x "./eyapp");

  unlink 't/PLIConflictNested2.pl';
  unlink 't/Assign2.pm';

  my $r = system(q{perl -I./lib/ eyapp -P -o t/Assign2.pm  t/Assign2.eyp});
  
  ok(!$r, "aux standalone option");

  ok(-s "t/Assign2.pm", "aux module Assign2 exists");

  $r = system(q{perl -I./lib/ eyapp -C -o t/PLIConflictNested2.pl t/PLIConflictNested2.eyp});
  
  ok(!$r, "compiled t/PLIConflictNested2.eyp");

  ok(-s "t/PLIConflictNested2.pl", "modulino exists");

  ok(-x "t/PLIConflictNested2.pl", "modulino has execution permits");


    $r = qx{perl -It t/PLIConflictNested2.pl -t -i -c 'if if=then then then=if'};


  ok(!$@,'t/PLIConflictNested2.eyp executed as standalone modulino');

  my $expected = q{
IF(TERMINAL[if],EQ(ID[if],ID[then]),TERMINAL[then],ASSIGN(ID[then],ID[if]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if if=then then then=if"');

  eval {

    $r = qx{perl -It t/PLIConflictNested2.pl -t -i -c 'if then=if then if=then'};

  };

  ok(!$@,'t/PLIConflictNested2.eyp executed as standalone modulino');

  $expected = q{
IF(TERMINAL[if],EQ(ID[then],ID[if]),TERMINAL[then],ASSIGN(ID[if],ID[then]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if then=if then if=then"');

  eval {

    $r = qx{perl -It t/PLIConflictNested2.pl -t -i -c 'if then=if then if a=b then c=d'};

  };

  ok(!$@,'t/PLIConflictNested2.eyp executed as standalone modulino');

  $expected = q{
IF(TERMINAL[if],EQ(ID[then],ID[if]),TERMINAL[then],
   IF(TERMINAL[if],EQ(ID[a],ID[b]),TERMINAL[then],ASSIGN(ID[c],ID[d]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "if then=if then if a=b then c=d"');

  #############################################

  eval {

    $r = qx{perl -It t/PLIConflictNested2.pl -t -i -c 'if if then if if then if=then'};

  };

  ok(!$@,'t/PLIConflictNested2.eyp executed as standalone modulino');

  $expected = q{
        IF(
          TERMINAL[if],
          ID[if],
          TERMINAL[then],
          IF(
            TERMINAL[if],
            ID[if],
            TERMINAL[then],
            ASSIGN(
              ID[if],
              ID[then]
            )
          )
        )
  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'PLIConflictNested2 AST for "if if then if if then if=then"');

  #############################################

  eval {

    $r = qx{perl -It t/PLIConflictNested2.pl -t -i -c 'if if then if=then'};

  };

  ok(!$@,'t/PLIConflictNested2.eyp executed as standalone modulino');

  $expected = q{
        IF(
          TERMINAL[if],
          ID[if],
          TERMINAL[then],
          ASSIGN(
            ID[if],
            ID[then]
          )
        )
  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'PLIConflictNested2 AST for "if if then if if then if=then"');

  unlink 't/PLIConflictNested2.pl';
  unlink 't/Assign2.pm';

}

# Checking syntax: %token if   = %/(if)\b/=variable
# with forforeach example
SKIP: {
  skip "t/forforeacherik.eyp not found", $nt12 unless 
      ($ENV{DEVELOPER} 
      && -r "t/forforeacherik.eyp" 
      && -r "t/forforeacherikcontextual.eyp" 
      && -r "t/forforeacherikcontextual2.eyp" 
      && -r "t/C.eyp" 
      && -x "./eyapp");

  unlink 't/forforeacherik.pl';
  unlink 't/C.pm';

  my $r = system(q{perl -I./lib/ eyapp -P -o t/C.pm  t/C.eyp});
  
  ok(!$r, "aux grammar C.eyp compiled");

  ok(-s "t/C.pm", "aux module C.pm exists");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/forforeacherik.pl t/forforeacherik.eyp});
  
  ok(!$r, "compiled t/forforeacherik.eyp");

  ok(-s "t/forforeacherik.pl", "modulino exists");

  ok(-x "t/forforeacherik.pl", "modulino has execution permits");


    $r = qx{perl -It t/forforeacherik.pl -t -i -c 'with for each a' 2>&1};


  ok(!$@,'t/forforeacherik.eyp executed as standalone modulino');

  my $expected = q{
s_is_with_FE_ID(TERMINAL[foreach],TERMINAL[a])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST of forforeacherik.eyp for "with for each a"');



    $r = qx{perl -It t/forforeacherik.pl -t -i -c 'for each' 2>&1};


  ok(!$@,'t/forforeacherik.eyp executed as standalone modulino');

  $expected = q{
Syntax error near 'for each'. 
Expected one of these terminals: 'F' 'with'
There were 1 errors during parsing
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,q{syntax error in  forforeacherik.eyp for "for each" since token isn't context sensitive});

  ############################################

  $r = system(q{perl -I./lib/ eyapp -TC -o t/forforeacherik.pl t/forforeacherikcontextual.eyp});
  
  ok(!$r, "compiled t/forforeacherikcontextual.eyp");

  ok(-s "t/forforeacherik.pl", "modulino exists");

  ok(-x "t/forforeacherik.pl", "modulino has execution permits");


    $r = qx{perl -It t/forforeacherik.pl -t -i -c 'with for each a' 2>&1};


  ok(!$@,'t/forforeacherikcontextual.eyp executed as standalone modulino');

  $expected = q{
s_is_with_FE_ID(TERMINAL[foreach],TERMINAL[a])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST of forforeacherikcontextual.eyp for "with for each a"');



    $r = qx{perl -It t/forforeacherik.pl -t -i -c 'for each' 2>&1};


  ok(!$@,'t/forforeacherikcontextual.eyp executed as standalone modulino');

  $expected = q{
s_is_F_ID(TERMINAL[for],TERMINAL[each])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,q{AST in  forforeacherikcontextual.eyp for "for each"});

  ############################################

  $r = system(q{perl -I./lib/ eyapp -TC -o t/forforeacherik.pl t/forforeacherikcontextual2.eyp});
  
  ok(!$r, "compiled t/forforeacherikcontextual2.eyp");

  ok(-s "t/forforeacherik.pl", "modulino exists");

  ok(-x "t/forforeacherik.pl", "modulino has execution permits");


    $r = qx{perl -It t/forforeacherik.pl -t -i -c 'for each each s' 2>&1};


  ok(!$@,'t/forforeacherikcontextual2.eyp executed as standalone modulino');

  $expected = q{
s_is_FE_ID_s(TERMINAL[for each],TERMINAL[each])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST of forforeacherikcontextual2.eyp for "for each each s"');



    $r = qx{perl -It t/forforeacherik.pl -t -i -c 'for each' 2>&1};


  ok(!$@,'t/forforeacherikcontextual2.eyp executed as standalone modulino');

  $expected = q{
s_is_F_ID(TERMINAL[for],TERMINAL[each])
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,q{AST in  forforeacherikcontextual2.eyp for "for each"});

  ############################################

  unlink 't/forforeacherik.pl';
  unlink 't/C.pm';

}
