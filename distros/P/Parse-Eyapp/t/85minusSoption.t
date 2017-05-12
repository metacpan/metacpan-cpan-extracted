#!/usr/bin/perl -w
use strict;
my ($nt, $nt2, $nt3, $nt4, $nt5, $nt6, $nt7, $nt9);

BEGIN { $nt = 8; $nt2 = 8; $nt5 = 7; $nt6 = 7; $nt7 = 6; $nt9 = 6;
}
use Test::More tests=> $nt+$nt2+$nt5+$nt6+$nt7+$nt9;

# test -S option and PPCR methodology with Pascal range versus enumerated conflict
SKIP: {
  skip "t/pascalnestedeyapp3.eyp not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/pascalnestedeyapp3.eyp" 
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -P -S range t/pascalnestedeyapp3.eyp 2>&1});
  ok(!$r, "pascalnestedeyapp3.eyp compiled with options '-S range' and -P");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/pascalnestedeyapp3.eyp});
  ok(!$r, "Pascal conflict grammar compiled");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c 'type r = (x) .. (y); 4'};

  };

  ok(!$@,'t/pascalnestedeyapp3.eyp executed as modulino');

  my $expected = q{

typeDecl_is_type_ID_type_expr(
  TERMINAL[r],
  RANGE(
    range_is_expr_expr(
      ID(
        TERMINAL[x]
      ),
      ID(
        TERMINAL[y]
      )
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

  ok(!$@,'t/pascalnestedeyapp3.eyp executed as modulino');

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
  unlink 'range.pm';
}

# test -S option and PPCR methodology with Pascal range versus enumerated conflict
SKIP: {
  skip "t/pascalnestedeyapp3_5.eyp not found", $nt2 unless ($ENV{DEVELOPER}
                                                        && -r "t/pascalnestedeyapp3_5.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -P -S range t/pascalnestedeyapp3_5.eyp 2>&1});
  ok(!$r, "pascalnestedeyapp3_5.eyp compiled with options '-S range' and -P");

  $r = system(q{perl -I./lib/ eyapp -TC -o t/ppcr.pl t/pascalnestedeyapp3_5.eyp});
  ok(!$r, "Pascal conflict grammar compiled");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c 'type e = (x, y, z);'};

  };  

  ok(!$@,'t/pascalnestedeyapp3_5.eyp executed as modulino');

  my $expected = q{

typeDecl_is_type_ID_type(
  TERMINAL[e],
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
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type e = (x, y, z);"');

  ############################
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -m 1 -c 'type e = (x) .. (y);'};

  };

  ok(!$@,'t/pascalnestedeyapp3_5.eyp executed as modulino');

  $expected = q{

typeDecl_is_type_ID_type(
  TERMINAL[e],
  RANGE(
    range_is_expr_expr(
      ID(
        TERMINAL[x]
      ),
      ID(
        TERMINAL[y]
      )
    )
  )
)

};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type e = (x) .. (y);"');

  unlink 't/ppcr.pl';
  unlink 'range.pm';
}

# testing PPCR and -S option with CplusplusNested2.eyp
# testing nested parsing (YYPreParse) when one token 
# has been read by the outer parser
SKIP: {
  skip "t/CplusplusNested2.eyp not found", $nt5 unless ($ENV{DEVELOPER} 
                                                        && -r "t/CplusplusNested2.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -PS decl t/CplusplusNested2.eyp});
  ok(!$r, "Auxiliary grammar decl.pm gnerated with '-PS decl' option");

  $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/CplusplusNested2.eyp 2> t/err});
  ok(!$r, "t/CplusplusNested2.eyp grammar compiled");
  like(qx{cat t/err},qr{^$},"no warning: %expect-rr 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) + 2; int (z) = 4;' 2>&1};

  };

  ok(!$@,'t/CplusplusNested2.eyp executed as modulino');

  my $expected = q{
PROG(PROG(EMPTY,EXP(TYPECAST(TERMINAL[int],ID[x]),NUM[2])),DECL(TERMINAL[int],ID[z],NUM[4]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) + 2; int (z) = 4;"');

  unlink 't/ppcr.pl';
  unlink 'decl.pm';
  unlink 't/err';

}

# testing PPCR and -S option with CplusplusNested.eyp
# testing nested parsing (YYPreParse) when one token 
# has been read by the outer parser
SKIP: {
  skip "t/CplusplusNested3.eyp not found", $nt6 unless ($ENV{DEVELOPER}
                                                        && -r "t/CplusplusNested3.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp  -PS decl t/CplusplusNested3.eyp});
  ok(!$r, "Auxiliary grammar decl.pm gnerated with '-PS decl' option");

  $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/CplusplusNested3.eyp 2> t/err});
  ok(!$r, "t/CplusplusNested3.eyp grammar compiled");
  like(qx{cat t/err},qr{^$},"no warning: %expect-rr 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) + 2; int (z) = 4;' 2>&1};

  };

  ok(!$@,'t/CplusplusNested3.eyp executed as modulino');

  my $expected = q{
PROG(PROG(EMPTY,EXP(TYPECAST(TERMINAL[int],ID[x]),NUM[2])),DECL(TERMINAL[int],ID[z],NUM[4]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) + 2; int (z) = 4;"');

  unlink 't/ppcr.pl';
  unlink 'decl.pm';
  unlink 't/err';

}


# testing PPCR and -S option with CplusplusStartOption.eyp
# testing nested parsing (YYPreParse) when one token 
# has been read by the outer parser
SKIP: {
  skip "t/CplusplusStartOption.eyp not found", $nt7 unless ($ENV{DEVELOPER}
                                                        && -r "t/CplusplusStartOption.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -C -S decl -o t/ppcr.pl t/CplusplusStartOption.eyp 2> t/err});
  ok(!$r, "t/CplusplusStartOption.eyp grammar compiled");
  like(qx{cat t/err},qr{^$},"no warning: %expect-rr 1");

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) = y+z;' 2>&1};

  };

  ok(!$@,'t/CplusplusStartOption.eyp executed as modulino');

  my $expected = q{
DECLARATORINIT(TERMINAL[int],ID[x],PLUS(ID[y],ID[z]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) = y+z;"');

  unlink 't/ppcr.pl';
  unlink 't/err';

}

SKIP: {
  skip "t/CplusplusStartOption.eyp not found", $nt9 unless ($ENV{DEVELOPER}
                                                        && -r "t/CplusplusStartOption.eyp"
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -C -o t/ppcr.pl t/CplusplusStartOption.eyp 2> t/err});
  ok(!$r, "t/CplusplusStartOption.eyp grammar compiled");

  like(qx{cat t/err},qr/Useless rules:/,"warnings");
  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) = y+z;' 2>&1};

  };

  ok(!$@,'t/CplusplusStartOption.eyp executed as modulino');

  my $expected = q{
DECLARATORINIT(TERMINAL[int],ID[x],PLUS(ID[y],ID[z]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) = y+z;"');

  unlink 't/ppcr.pl';
  unlink 't/err';

}


