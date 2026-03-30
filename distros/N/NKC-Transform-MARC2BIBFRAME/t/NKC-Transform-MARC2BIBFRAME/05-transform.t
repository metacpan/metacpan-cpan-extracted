use strict;
use warnings;

use File::Object;
use NKC::Transform::MARC2BIBFRAME;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Common.
my $act_year = (localtime)[5] + 1900;

# Test.
my $obj = NKC::Transform::MARC2BIBFRAME->new;
my $ex1 = slurp($data_dir->file('ex1.xml')->s);
my $ret = $obj->transform($ex1,
	'idsource' => "'IDSOURCE'",
);
$ret =~ s{<bf:generationProcess\b[^>]*/>\K(\s*<bf:date\b[^>]*>)[^<]*(</bf:date>)}{$1DATE$2}g;
my $expected_string = slurp($data_dir->file('ex1-3.0.0-expected.xml')->s);
my $expected = decode_utf8($expected_string);
is($ret, $expected, 'Compare transformed with expected (default - 3.0.0).');

# Test.
$obj = NKC::Transform::MARC2BIBFRAME->new(
	'version' => '2.5.0',
);
$ex1 = slurp($data_dir->file('ex1.xml')->s);
$ret = $obj->transform($ex1);
$ret =~ s{(<bf:generationDate\b[^>]*>).*?(</bf:generationDate>)}{$1DATE$2};
$expected_string = slurp($data_dir->file('ex1-2.5.0-expected.xml')->s);
$expected = decode_utf8($expected_string);
is($ret, $expected, 'Compare transformed with expected (2.5.0).');

# Test.
$obj = NKC::Transform::MARC2BIBFRAME->new(
	'version' => '2.9.0',
);
$ex1 = slurp($data_dir->file('ex1.xml')->s);
$ret = $obj->transform($ex1,
	'idsource' => "'IDSOURCE'",
);
$ret =~ s{<bf:generationProcess\b[^>]*/>\K(\s*<bf:date\b[^>]*>)[^<]*(</bf:date>)}{$1DATE$2}g;
$expected_string = slurp($data_dir->file('ex1-2.9.0-expected.xml')->s);
$expected = decode_utf8($expected_string);
is($ret, $expected, 'Compare transformed with expected (2.9.0).');

# Test.
$obj = NKC::Transform::MARC2BIBFRAME->new(
	'version' => '2.10.0',
);
$ex1 = slurp($data_dir->file('ex1.xml')->s);
$ret = $obj->transform($ex1,
	'idsource' => "'IDSOURCE'",
);
$ret =~ s{<bf:generationProcess\b[^>]*/>\K(\s*<bf:date\b[^>]*>)[^<]*(</bf:date>)}{$1DATE$2}g;
$expected_string = slurp($data_dir->file('ex1-2.10.0-expected.xml')->s);
$expected = decode_utf8($expected_string);
is($ret, $expected, 'Compare transformed with expected (2.10.0).');
