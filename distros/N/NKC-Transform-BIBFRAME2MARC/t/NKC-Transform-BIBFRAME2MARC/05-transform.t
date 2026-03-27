use strict;
use warnings;

use File::Object;
use NKC::Transform::BIBFRAME2MARC;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = NKC::Transform::BIBFRAME2MARC->new(
	'version' => '2.6.0',
);
my $ex1 = slurp($data_dir->file('ex1.bibframe')->s);
my $ret = $obj->transform($ex1);
$ret =~ s{(<marc:controlfield\b[^>]*\btag="005"[^>]*>)[^<]*(</marc:controlfield>)}{$1DATE$2}g;
$ret =~ s{(<marc:subfield\b[^>]*\bcode="g"[^>]*>)[^<]*(</marc:subfield>)}{$1DATE$2}g;
my $expected_string = slurp($data_dir->file('ex1-2.6.0.marcxml')->s);
my $expected = decode_utf8($expected_string);
is($ret, $expected, 'Generated MARC file (2.6.0).');

# Test.
$obj = NKC::Transform::BIBFRAME2MARC->new(
	'version' => '2.10.0',
);
$ex1 = slurp($data_dir->file('ex1.bibframe')->s);
$ret = $obj->transform($ex1);
$ret =~ s{(<marc:controlfield\b[^>]*\btag="005"[^>]*>)[^<]*(</marc:controlfield>)}{$1DATE$2}g;
$ret =~ s{(<marc:subfield\b[^>]*\bcode="g"[^>]*>)[^<]*(</marc:subfield>)}{$1DATE$2}g;
$expected_string = slurp($data_dir->file('ex1-2.10.0.marcxml')->s);
$expected = decode_utf8($expected_string);
is($ret, $expected, 'Generated MARC file (2.10.0).');

# Test.
$obj = NKC::Transform::BIBFRAME2MARC->new(
	'version' => '3.0.0',
);
$ex1 = slurp($data_dir->file('ex1.bibframe')->s);
$ret = $obj->transform($ex1);
$ret =~ s{(<marc:controlfield\b[^>]*\btag="005"[^>]*>)[^<]*(</marc:controlfield>)}{$1DATE$2}g;
$ret =~ s{(<marc:subfield\b[^>]*\bcode="g"[^>]*>)[^<]*(</marc:subfield>)}{$1DATE$2}g;
$expected_string = slurp($data_dir->file('ex1-3.0.0.marcxml')->s);
$expected = decode_utf8($expected_string);
is($ret, $expected, 'Generated MARC file (3.0.0).');
