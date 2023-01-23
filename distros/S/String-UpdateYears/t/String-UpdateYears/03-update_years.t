use strict;
use warnings;

use String::UpdateYears qw(update_years);
use Test::More 'tests' => 12;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $input = '1900';
my $ret = update_years($input, {}, 2000);
is($ret, '1900-2000', 'Add year to string with start year (1900).');

# Test.
$input = '1900-1999';
$ret = update_years($input, undef, 2000);
is($ret, '1900-2000', 'Update year to string with years range (1900-1999).');

# Test.
$input = decode_utf8('© 2013 Michal Josef Špaček');
$ret = update_years($input, {}, 2022);
is($ret, decode_utf8('© 2013-2022 Michal Josef Špaček'),
	'Add year to string which contain start year.');

# Test.
$input = decode_utf8('© 2013-2020 Michal Josef Špaček');
$ret = update_years($input, {}, 2022);
is($ret, decode_utf8('© 2013-2022 Michal Josef Špaček'),
	'Add year to string which contain year range.');

# Test.
$input = decode_utf8('© 2013 Michal Josef Špaček');
my $opts_hr = {
	'prefix_glob' => decode_utf8('©\s'),
};
$ret = update_years($input, $opts_hr, 2022);
is($ret, decode_utf8('© 2013-2022 Michal Josef Špaček'),
	'Add year to string which contain start year. Lookup by prefix glob.');

# Test.
$input = decode_utf8('© 2013-2020 Michal Josef Špaček');
$ret = update_years($input, $opts_hr, 2022);
is($ret, decode_utf8('© 2013-2022 Michal Josef Špaček'),
	'Add year to string which contain year range. Lookup by prefix glob.');

# Test.
$input = decode_utf8('© 2013 Michal Josef Špaček');
$opts_hr = {
	'suffix_glob' => decode_utf8('\sMichal.*'),
};
$ret = update_years($input, $opts_hr, 2022);
is($ret, decode_utf8('© 2013-2022 Michal Josef Špaček'),
	'Add year to string which contain start year. Lookup by suffix glob.');

# Test.
$input = decode_utf8('© 2013-2020 Michal Josef Špaček');
$ret = update_years($input, $opts_hr, 2022);
is($ret, decode_utf8('© 2013-2022 Michal Josef Špaček'),
	'Add year to string which contain year range. Lookup by suffix glob.');

# Test.
$input = '190';
$ret = update_years($input, {}, 2000);
is($ret, undef, 'Not found year (190).');

# Test.
$input = '2000';
$ret = update_years($input, {}, 2000);
is($ret, undef, 'Nothing to update (2000).');

# Test.
$input = '1900-2000';
$ret = update_years($input, {}, 2000);
is($ret, undef, 'Nothing to update (1900-2000).');
