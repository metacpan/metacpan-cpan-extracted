use strict;
use warnings;
use Test::More tests => 29;
use SOOT;
use SOOT::API qw/:all/;
pass();

is(cproto("foo"), "char*");
is(cproto(9), "int");
is(cproto(9.1), "double");

my $int = 2;
my $float = 3.1;
my $str = "fooo";

is(cproto($str), "char*");
is(cproto($int), "int");
is(cproto($float), "double", "float var has double prototype");

my $foo = "123";
is(cproto($foo), "char*");

$foo = "123"+2;
is(cproto($foo), "int");

$foo = "123.2"+2;
is(cproto($foo), "double");

$foo = (.2*3.3)."";
is(cproto($foo), "char*");
is(cproto($foo*$foo), "double");

is(cproto([]), undef);
is(cproto({}), undef);
is(cproto(sub {}), undef);
is(cproto(\1), undef);
is(cproto(\$foo), undef, "reference to scalar does not have known prototype");

my $scalar;
my $obj;
$obj = bless(\$scalar => 'TObject');
is(cproto($obj), 'TObject*');
$obj = bless(\$scalar => 'TH1D');
is(cproto($obj), 'TH1D*');

$obj = bless([] => 'TObject');
is(cproto($obj), 'TObject*');
$obj = bless([] => 'TH1D');
is(cproto($obj), 'TH1D*');


$obj = bless({} => 'TObject');
is(cproto($obj), 'TObject*');
$obj = bless({} => 'TH1D');
is(cproto($obj), 'TH1D*');

$obj = bless({} => 'Something::Else');
is(cproto($obj), undef);

is(cproto(['a', 12]), 'char**');
is(cproto([123, 1.3, ""]), 'int*');
is(cproto([123.2, 1.3, ""]), 'double*');

is(cproto(bless ['a', 12] => 'TH1D'), 'TH1D*');

pass("REACHED END");
