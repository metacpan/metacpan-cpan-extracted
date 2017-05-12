#!perl -T

use lib 't';
use MoneyWorks;
use Test::More;

BEGIN {
  eval {
   $ENV{MONEYWORKS_TEST_BIN}
    or require MoneyWorks, new MoneyWorks ->bin
    or plan skip_all => "The MoneyWorks binary could not be found. Please"
     . " set the MONEYWORKS_TEST_BIN environment variable before running "
     . "these tests.";
  };
  $::REGO = $ENV{MONEYWORKS_TEST_REGO};
}

# untaint the registration number
if(defined $::REGO) {
  $::REGO =~ /^(.*)\z/s;
  $::REGO = $1
}


use warnings; no warnings qw' utf8 parenthesis regexp once qw ';
use strict;
use lib 't';

# We create three MoneyWorks objects initially, to test three modes:
# single-process, keep-alive, and the two again with no file. The version
# tests are sufficient to make sure all three work. Then we just use the
# keep-alive object after that, to avoid modifying the original Acme.mwd5
# file in case tests are run again. (The keep-alive object uses a copy.)

my $bin = $ENV{MONEYWORKS_TEST_BIN};
if($bin) { # untaint
  $bin =~ /^(.*)\z/s;
  $bin = $1;
}
else { $bin = new MoneyWorks ->bin }

# Run this test early, since we need the version number to determine which
# file to open.
use tests 1;
my $m_no_file = new MoneyWorks bin => $bin, keep_alive => 0;
my $v = $m_no_file->version;
# We have an r in here for versions like 7.3.8r1.
like $v, qr/^[\d\.r]+\z/, "version" . ($v?" $v":"") . " (no file)";
diag "Testing with MoneyWorks $v";
$v = int $v;
$v =~ /(.*)/; $v = $1; # untaint

use tests 13; # constructor and accessors
isa_ok my $m = MoneyWorks->new(
 rego => '12345',
 user => 'me',
 password => 'ne znayu',
 file => 'fg.cr.cg',
 bin => 'foo',
 keep_alive => 1,
), 'MoneyWorks';
{
 ok $m->keep_alive, 'keep_alive arg';
 $m->keep_alive(0);
 ok !$m->keep_alive, 'keep_alive accessor';

 is $m->rego, '12345', 'rego arg';
 $m->rego($::REGO);
 is $m->rego, $::REGO, 'rego accessor';

 is $m->user, 'me', 'user arg';
 $m->user(undef);
 is $m->user, undef, 'user accessor';

 is $m->password, 'ne znayu', 'password arg';
 $m->password(undef);
 is $m->password, undef, 'password accessor';

 is $m->file, 'fg.cr.cg', 'file arg';
 $m->file("t/Acme.mwd$v");
 is $m->file, "t/Acme.mwd$v", 'file accessor';

 is $m->bin, 'foo', 'bin arg';
 $m->bin($bin);
 is $m->bin, $bin, 'bin accessor';
}

sub skip_remainder {
 my $msg = shift;
 diag $msg;
 my $builder = builder Test'More;
 my $expected_tests = expected_tests $builder;
 my $tests_run_so_far = current_test $builder;
 my $remainder = $expected_tests - $tests_run_so_far;
 SKIP: {
   skip $msg, $remainder;
 }
 exit
}

unless ($v == 5 || $v == 6) {
 skip_remainder
   "There are no test files for your version of MoneyWorks ($v)";
}
unless( $::REGO = $ENV{MONEYWORKS_TEST_REGO} ) {
   require MoneyWorks;
   eval { MoneyWorks->new( file => "t/Acme.mwd$v" )->eval('name') };
   $@ =~ /serial number/i
    and skip_remainder "Please set the MONEYWORKS_TEST_REGO envir"
       . "onment variable to your MoneyWorks' registration number before"
       . " running these tests.";
}

# get more MW objects ready
my $m_no_file_live = new MoneyWorks bin => $bin;
use File::Copy;
copy("t/Acme.mwd$v","-e.mwd$v"); # We use a file name beginning with '-e'
END{ unlink "-e.mwd$v" }         # as an extra robustness test.
my $m_live = new MoneyWorks
 rego => $::REGO,
 file => "-e.mwd$v",
 bin => $bin,
 keep_alive => 1,
;

use tests 1; # password-protected file
{
 my $m = new MoneyWorks
  bin => $bin,
  file => "t/protected.mwd$v",
  rego => $::REGO,
  user => 123,
  password => 789
 ;
 is $m->eval('name'), 'Acme Veggies Ltd', 'password-protected file';
}

use tests 3; # version
{
 my $v = $m->version;
 like $v, qr/^[\d\.]+\z/, "version " . ($v||"");
 $v = $m_live->version;
 like $v, qr/^[\d\.]+\z/, "version" . ($v?" $v":"") . " (live)";
 $v = $m_no_file_live->version;
 like $v, qr/^[\d\.]+\z/, "version" . ($v?" $v":"")." (no file; live)";
}
$m_no_file_live->close;

use tests 3; # eval
{
 is $m_live->eval('name'), 'Acme Widgets Ltd', 'eval';
 # Double test here; we are also testing commands containing DEL, which we
 # would otherwise use as a delimiter:
 is $m_no_file->eval("`\x7f`"), "\x7f", 'eval with \x7f (no file)';
 is $m_live->eval("1\n+\n1"), 2, 'eval strips line breaks';
}

use tests 12; # import
is_deeply
  $m_live->import( data => "CBG\tCabbage", map => 't/prod-import.impo' ),
  { created => 1, updated => 0 },
  'import(data => single record)';
is $m_live->command(
  'export table=/Product/ format=/[Description]/ search=/Code="CBG"/'
), 'Cabbage', 'result of import';
 
is_deeply $m_live->import(
  data => "SHOE1\tRed Shoes\nSHOE2\tGreen Shoes\n",
  map => 't/prod-import.impo'
), { created => 2, updated => 0 }, 'import(data => multiple)';
is $m_live->command(
  'export table=/Product/ format=/[Code]-[Description]\n/ '
  . 'search=/Left(Code,4)="SHOE"/'
), "SHOE1-Red Shoes\nSHOE2-Green Shoes\n", 'result of multiple import';
 
is_deeply $m_live->import(
  data => "CHOU1\tRed Chou\rCHOU2\tGreen Chou\r",
  map => 't/prod-import.impo'
), { created => 2, updated => 0 }, 'import(data => multiple [with CR])';
is $m_live->command(
  'export table=/Product/ format=/[Code]-[Description]\n/ '
  . 'search=/Left(Code,4)="CHOU"/'
), "CHOU1-Red Chou\nCHOU2-Green Chou\n",'result of multiple import w/CR';
 
is_deeply $m_live->import(
  data => "COK1\tRed COK\r\nCOK2\tGreen COK\r\n",
  map => 't/prod-import.impo'
), { created => 2, updated => 0 }, 'import(data => multiple [with CRLF])';
is $m_live->command(
  'export table=/Product/ format=/[Code]-[Description]\n/ '
  . 'search=/Left(Code,3)="COK"/'
), "COK1-Red COK\nCOK2-Green COK\n",'result of multiple import w/CRLF';
 
is_deeply $m_live->import(
  data_file => "t/wax.txt",
  map => 't/prod-import.impo'
), { created => 2, updated => 0 }, 'file import';
is $m_live->command(
  'export table=/Product/ format=/[Code]|[Description]\n/ '
  .'search=/Left(Code,4)="WAX-"/'
), "WAX-C|Ceiling Wax\nWAX-F|Floor Wax\n", 'result of file import';

SKIP:{skip"not supported",2;
 is_deeply $m_live->import(
  table => 'product',
  data => [ my $data = {
   Code => 'SMV',
   Supplier => 'BSUPP',
   SuppliersCode => 'SAM',
   Description => 'Some of our samovars',
   Comment => 'I dislike these.',
   Category1 => 'Small',
   Category2 => 'Medium',
   Category3 => 'At',
   Category4 => 'Large',
   SalesAcct => 4100,
   StockAcct => 1700,
   COGAcct => 6100,
   SellUnit => 'ea',
   SellPrice => 1,
   SellPriceB => 2,
   SellPriceC => 3,
   SellPriceD => 4,
   SellPriceE => 5,
   SellPriceF => 6,
   QtyBrkSellPriceA1 => 7,
   QtyBrkSellPriceA2 => 8,
   QtyBrkSellPriceA3 => 9,
   QtyBrkSellPriceA4 => 10,
   QtyBrkSellPriceB1 => 11,
   QtyBrkSellPriceB2 => 12,
   QtyBrkSellPriceB3 => 13,
   QtyBrkSellPriceB4 => 14,
   QtyBreak1 => 15,
   QtyBreak2 => 16,
   QtyBreak3 => 17,
   QtyBreak4 => 18,
   BuyUnit => 'lot',
   BuyPrice => 19,
   ConversionFactor => 20,
   SellDiscount => 21,
   SellDiscountMode => 2,
   ReorderLevel => 22,
   Type => 'P',
   Colour => 'Green',
   UserNum => 23,
   UserText => "a",
   Plussage => 24,
   BuyWeight => 25,
   StockTakeQty => 26,
   StockTakeValue => 27,
   StockTakeNewQty => 28,
   BarCode => 29,
   BuyPriceCurrency => 'USD',
   Custom1 => 'b',
   Custom2 => 'c',
   Custom3 => 'd',
   Custom4 => 'e',
   LeadTimeDays => 30,
   SellWeight => 31,
   MinBuildQty => 32,
   NormalBuildQty => 33,
  } ],
 ), { created => 1, updated => 0 }, 'array import';
 my @keys = sort keys %$data;
 is $m_live->command(
  'export table=/Product/ format=/' . (join "|", map "[$_]", @keys) . '/ '
  .'search=/Code="SMV"/'
 ), join("|", map $$data{$_}, @keys), 'result of array import';
}

use tests 4; # export
{
 is_deeply
  [ sort { $$a{Code} cmp $$b{Code} } @{ $m_live->export(
   table => 'Product',
   fields => ['Code','Description','SellPrice'],
   search => 'Left(Code,1) == `B`',
  ) } ],
  [
   {
    Code => "BA100",
    Description => "Bronze Widget Medium",
    SellPrice => 24.95
   },
   {
    Code => "BA200",
    Description => "Bronze Widget Large",
    SellPrice => 69.75
   },
   {
    Code => "BB100",
    Description => "Bronze Widget Bevelled Medium",
    SellPrice => 22
   },
   {
    Code => "BB200",
    Description => "Bronze Widget Bevelled Large",
    SellPrice => 32
   },
   {
    Code => "BC100",
    Description => "Bronze Taper Widget Small",
    SellPrice => 12
   },
   {
    Code => "BC200",
    Description => "Bronze Taper Widget Medium",
    SellPrice => 21.5
   },
  ],
  'export without key';
 is_deeply
  $m_live->export(
   table => 'Product',
   fields => ['Code','Description','SellPrice'],
   search => 'Left(Code,1) == `B`',
   key     => 'Code',
  ),
  {
   BA100 => {
    Code => "BA100",
    Description => "Bronze Widget Medium",
    SellPrice => 24.95
   },
   BA200 => {
    Code => "BA200",
    Description => "Bronze Widget Large",
    SellPrice => 69.75
   },
   BB100 => {
    Code => "BB100",
    Description => "Bronze Widget Bevelled Medium",
    SellPrice => 22
   },
   BB200 => {
    Code => "BB200",
    Description => "Bronze Widget Bevelled Large",
    SellPrice => 32
   },
   BC100 => {
    Code => "BC100",
    Description => "Bronze Taper Widget Small",
    SellPrice => 12
   },
   BC200 => {
    Code => "BC200",
    Description => "Bronze Taper Widget Medium",
    SellPrice => 21.5
   },
  },
  'export with key';
 is_deeply
  $m_live->export(
   table => 'Product',
   fields => ['Description','SellPrice'],
   search => 'Left(Code,1) == `B`',
   key     => 'Code',
  ),
  {
   BA100 => {
    Description => "Bronze Widget Medium",
    SellPrice => 24.95
   },
   BA200 => {
    Description => "Bronze Widget Large",
    SellPrice => 69.75
   },
   BB100 => {
    Description => "Bronze Widget Bevelled Medium",
    SellPrice => 22
   },
   BB200 => {
    Description => "Bronze Widget Bevelled Large",
    SellPrice => 32
   },
   BC100 => {
    Description => "Bronze Taper Widget Small",
    SellPrice => 12
   },
   BC200 => {
    Description => "Bronze Taper Widget Medium",
    SellPrice => 21.5
   },
  },
  'export with key that is not in the list of exported fields';
 my $export = $m_live->export(
   table => 'Product',
   search => 'Left(Code,1) == `B`',
   key     => 'Code',
 );
 cmp_ok $export->{BC200}->{BuyPrice}, '==', 8,
  'export without explicit fields list'
  ;# or do{ use DDS; diag Dump $export};
}

use tests 3; # child proc methods
{
 my $pid = $m_live->pid;
 like $pid, qr/^[0-9]+\z/, "pid ($pid) looks like a number";
 is kill(0,$pid), 1, "$pid is alive";
 $m_live->close;
 is kill(0,$pid), 0, "close terminated $pid";
}

use tests 7; # ties
{
 my $tie = $m_live->tie("Name", "Code");
 ok !exists $tie->{ehuioyoy}, 'Ties: Customer ehuioyoy does not exist.';
 ok exists $tie->{BROWN}, "Ties: Customer BROWN exists";
 my $record = $tie->{BROWN};
 is $record->{Name}, 'Brown Suppliers', 'Ties: retrieve value from record';
 $m_live->eval('Replace(`Name.Name`,`Code="BROWN"`,`"Brown Briars"`)');
 is $record->{Name}, 'Brown Briars', 'Ties: retrieved record is live';

 $tie = $m_live->tie("name","email");
 ok !exists $$tie{'accounts@chext.gued'},
  'The EXISTS method of a table tie can deal with @ signs.';
 is $$tie{'accounts@brown.co'}{name}, 'Brown Briars',
  'Ties can handle @ when fetching individual fields';

 $m_live->close;

 tie my %h, MoneyWorks =>
  rego => $::REGO,
  file => "-e.mwd$v",
  bin  => $bin,
  table => 'Transaction',
  key    => 'OurRef'
 ;
 is $h{1869}{NameCode}, 'GREEN', 'tie function';
}

use tests 7; # quoting functions
{
 my $str = join "", map chr, 33..127;
 like mw_cli_quote('foo'), qr/^([^fo])foo\1\z/, 'mw_cli_quote';
 is mw_cli_quote($str), " $str ", 'mw_cli_quote with space delimiters';
 like mw_str_quote('"'), qr/^(?:`\\?"`|"\\"")\z/, 'mw_str_quote(q["])';
 like mw_str_quote('`'), qr/^(?:"\\?`"|`\\``)\z/, 'mw_str_quote(q[`])';
 like mw_str_quote('"`'), qr/^(?:`\\?"\\``|"\\"\\?`")\z/,
  'mw_str_quote(q["`])';
 like mw_str_quote('foo'), qr/^([`"])foo\1\z/, 'mw_str_quote(q[foo])';

 my $w;
 local $SIG{__WARN__} = sub { $w = shift };
 use warnings;
 mw_cli_quote "\n";
 like $w, qr/^Argument to mw_cli_quote contains line breaks/,
  'mw_cli_quote warns with line breaks';

}

use tests 4; # command
{
 ok !eval { $m_live->command("\n");1}, 'command dies with line breaks';
 like $@, qr/^Commands cannot contain line breaks/, 'error message';
 my $w;
 local $SIG{__WARN__} = sub { $w = shift };
 use warnings;
 is $m_live->command("evaluate expr='1\0+1'"), '2', 'command strips nulls';
 like $w, qr/^Command contains null chars/, 'warning message';
}
