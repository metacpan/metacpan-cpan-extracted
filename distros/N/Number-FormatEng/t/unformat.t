
use warnings;
use strict;
use Test::More tests => 47;

# Check if module loads ok
BEGIN { use_ok('Number::FormatEng', qw(unformat_pref)) }

# Check all symbols (positive exponent)
is(unformat_pref('1.23Y')  , 1.23e+24  , 'prefix Y');
is(unformat_pref('1.23Z')  , 1.23e+21  , 'prefix Z');
is(unformat_pref('1.23E')  , 1.23e+18  , 'prefix E');
is(unformat_pref('1.23P')  , 1.23e+15  , 'prefix P');
is(unformat_pref('1.23T')  , 1.23e+12  , 'prefix T');
is(unformat_pref('1.23G')  , 1.23e+09  , 'prefix G');
is(unformat_pref('1.23M')  , 1.23e+06  , 'prefix M');
is(unformat_pref('1.23k')  , 1.23e+03  , 'prefix k');

# Check all symbols (negative exponent)
is(unformat_pref('1.23y')  , 1.23e-24  , 'prefix y');
is(unformat_pref('1.23z')  , 1.23e-21  , 'prefix z');
is(unformat_pref('1.23a')  , 1.23e-18  , 'prefix a');
is(unformat_pref('1.23f')  , 1.23e-15  , 'prefix f');
is(unformat_pref('1.23p')  , 1.23e-12  , 'prefix p');
is(unformat_pref('1.23n')  , 1.23e-09  , 'prefix n');
is(unformat_pref('1.23u')  , 1.23e-06  , 'prefix u');
is(unformat_pref('1.23m')  , 1.23e-03  , 'prefix m');

# Check zero
is(unformat_pref('0k'          ) , '0'      , '0 with prefix');
is(unformat_pref(0             ) , '0'      , 'number 0');
is(unformat_pref(0e0           ) , '0'      , 'number 0e0');
is(unformat_pref('0'           ) , '0'      , 'string 0, no prefix');
is(unformat_pref('0.00'        ) , '0.00'   , '0 with decimal');
is(unformat_pref(" \n\t0\t\n  ") , '0'      , '0 with whitespace');

# Out of prefix range
is(unformat_pref('9876e56'     ) , '9876e56'   , 'over range ');
is(unformat_pref('-5.43e-50'   ) , '-5.43e-50' , 'under range');

# Miscellaneous
is(unformat_pref('-400u')  , -4e-4);
is(unformat_pref('1.23' )  , 1.23 , 'no prefix');
is(unformat_pref('5'           ) , '5'        );
is(unformat_pref(    5         ) , 5          );
is(unformat_pref('5k'          ) , 5000       );
is(unformat_pref("\t \n5k  \t\n"), 5000 , 'with whitespace'    );
is(unformat_pref('1.2345k'     ) , 1234.5     );
is(unformat_pref('1'           ) , '1'        );
is(unformat_pref('12345M')  , 12345e6, 'number has more than 3 digits');
is(unformat_pref('-7.89123m', 'junk')  , -7.89123e-3, 'ignore extra inputs');
is(unformat_pref('12.34e-3k'   ) , '12.34' , 'number has exponent');
is(unformat_pref(37.5)  , 37.5);

# Check error message
$@ = '';
eval { my $ret = unformat_pref() };
like($@, qr/Error: unformat_pref requires input/, 'die if no input');

$@ = '';
eval { my $ret = unformat_pref('') };
like($@, qr/Error: unformat_pref requires input/, 'die if no input');

$@ = '';
eval { my $ret = unformat_pref(undef) };
like($@, qr/Error: unformat_pref requires input/, 'die if undef');

$@ = '';
eval { my $ret = unformat_pref('  ') };
like($@, qr/Error: unformat_pref requires input/, 'die if just spaces');

$@ = '';
eval { my $ret = unformat_pref('q') };
like($@, qr/Error: .* not numeric/, 'die if illegal string');

$@ = '';
eval { my $ret = unformat_pref('123x') };
like($@, qr/Error: .* not numeric/, 'die if illegal string');

$@ = '';
eval { my $ret = unformat_pref('k') };
like($@, qr/Error: .* not numeric/, 'die if illegal string');

$@ = '';
eval { my $ret = unformat_pref('ok') };
like($@, qr/Error: .* not numeric before prefix/, 'die if illegal string');

$@ = '';
eval { my $ret = unformat_pref([3]) };
like($@, qr/Error: .* not numeric/, 'die if array ref');

$@ = '';
eval { my $ret = unformat_pref("\x22") };
like($@, qr/Error: .* not numeric/, 'die if control char');

