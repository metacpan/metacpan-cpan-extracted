use strict;
use warnings;
use Test::More tests => 30;
use SOOT;
use SOOT::API qw/:all/;
pass();

SCOPE: {
  is(type("foo"), "STRING");
  is(type(9), "INTEGER");
  is(type(9.1), "FLOAT");

  my $int = 2;
  my $float = 3.1;
  my $str = "fooo";

  is(type($str), "STRING");
  is(type($int), "INTEGER");
  is(type($float), "FLOAT");

  my $foo = "123";
  is(type($foo), "STRING");

  $foo = "123"+2;
  is(type($foo), "INTEGER");

  $foo = "123.2"+2;
  is(type($foo), "FLOAT");

  $foo = (.2*3.3)."";
  is(type($foo), "STRING");
  is(type($foo*$foo), "FLOAT");

  is(type([]), 'INVALID_ARRAY');
  is(type({}), 'HASH');
  is(type(sub {}), 'CODE');
  is(type(\1), 'REF');
  is(type(\$foo), 'REF');

  my $scalar;
  my $obj;
  $obj = bless(\$scalar => 'TObject');
  is(type($obj), 'TOBJECT');
  $obj = bless(\$scalar => 'TH1D');
  is(type($obj), 'TOBJECT');

  $obj = bless([] => 'TObject');
  is(type($obj), 'TOBJECT');
  $obj = bless([] => 'TH1D');
  is(type($obj), 'TOBJECT');


  $obj = bless({} => 'TObject');
  is(type($obj), 'TOBJECT');
  $obj = bless({} => 'TH1D');
  is(type($obj), 'TOBJECT');

  $obj = bless({} => 'Something::Else');
  is(type($obj), 'HASH');

  is(type(['a', 12]), 'STRING_ARRAY');
  is(type([123, 1.3, ""]), 'INTEGER_ARRAY');
  is(type([123.2, 1.3, ""]), 'FLOAT_ARRAY');

  is(type(bless ['a', 12] => 'TH1D'), 'TOBJECT');

# does this do something utterly evil? (SEGV?)
  $obj = bless([] => 'TH1D');
  isa_ok(bless($obj => 'TH2'), 'TH2');
} # end SCOPE

pass("REACHED END");
