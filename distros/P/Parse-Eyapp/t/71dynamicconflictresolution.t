#!/usr/bin/perl -w
use strict;
my $nt;

BEGIN { $nt = 9 }
use Test::More tests=>$nt;
#use_ok qw(Parse::Eyapp) or exit;

SKIP: {
  skip "t/dynamicresolution/pascalenumeratedvsrangesolvedviadyn.eyp not found", $nt unless ($ENV{DEVELOPER} && ($ENV{DEVELOPER} eq 'casiano') && -r "t/dynamicresolution/pascalenumeratedvsrangesolvedviadyn.eyp" && -x "./eyapp");

  unlink 't/Calc.pm';

  my $r = system(q{perl -I./lib/ eyapp -b '' -s -o t/dynamicresolution/persvd.pl t/dynamicresolution/pascalenumeratedvsrangesolvedviadyn.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/dynamicresolution/persvd.pl", "modulino standalone exists");

  ok(-x "t/dynamicresolution/persvd.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/dynamicresolution/persvd.pl -t -c 'Type r = (x+2)*3 ..  y/2 ;'};
  };

  ok(!$@,'pascalenumeratedvsrangesolvedviadyn executed as standalone modulino');

  my $expected =  q{
  typeDecl_is_TYPE_ID_type(TERMINAL,
    TERMINAL,
    RANGE(
      expr_is_expr_TIMES_expr(
        expr_is_LP_expr_RP(
          expr_is_expr_PLUS_expr(
            ID(
              TERMINAL
            ),
            expr_is_NUM(
              TERMINAL
            )
          )
        ),
        expr_is_NUM(
          TERMINAL
        )
      ),
      TERMINAL,
      expr_is_expr_DIV_expr(
        ID(
          TERMINAL
        ),
        expr_is_NUM(
          TERMINAL
        )
      )
    )
  )};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'AST for Type r = (x+2)*3 ..  y/2 ;');

  eval {
    $r = qx{t/dynamicresolution/persvd.pl -t -c 'Type e = (x, y, z);'};
  };

  ok(!$@,'pascalenumeratedvsrangesolvedviadyn executed as standalone modulino');

  $expected = q{
    typeDecl_is_TYPE_ID_type(
      TERMINAL,
      TERMINAL,
      ENUM(
        idList_is_idList_COMMA_ID(
          idList_is_idList_COMMA_ID(
            ID(
              TERMINAL
            ),
            TERMINAL
          ),
          TERMINAL
        )
      )
    )
    };

  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'AST for Type e = (x, y, z);');

  eval {
    $r = qx{t/dynamicresolution/persvd.pl -t -c 'Type e = (x);'};
  };

  ok(!$@,'pascalenumeratedvsrangesolvedviadyn executed as standalone modulino');

  $expected = q{
typeDecl_is_TYPE_ID_type(
  TERMINAL,
  TERMINAL,
  ENUM(
    ID(
      TERMINAL
    )
  )
)
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'AST for Type e = (x);');

  unlink 't/dynamicresolution/persvd.pl';

}

