#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 14;

use Spreadsheet::HTML;

my $encodes = [
    [ qw( < = & > " ' ) ],
    [ qw( < = & > " ' ) ],
];
my $spaces = [
    [ "\n", "foo\n", " ", " \n" ],
    [ "\n", "foo\n", " ", " \n" ],
];

my $expected_encodes = [
    [ map { tag => 'th', cdata => $_ }, qw( < = & > " ' ) ],
    [ map { tag => 'td', cdata => $_ }, qw( < = & > " ' ) ],
];
my $expected_spaces = [
    [ map { tag => 'th', cdata => $_ }, '&nbsp;', "foo\n", '&nbsp;', '&nbsp;' ],
    [ map { tag => 'td', cdata => $_ }, '&nbsp;', "foo\n", '&nbsp;', '&nbsp;' ],
];

my $table = Spreadsheet::HTML->new( data => $encodes );
is_deeply scalar $table->_process, $expected_encodes,  "we are not encoding data by default";
is_deeply scalar $table->_process, $expected_encodes,  "only processes once";

is $table->generate(),
    q(<table><tr><th><</th><th>=</th><th>&</th><th>></th><th>"</th><th>'</th></tr><tr><td><</td><td>=</td><td>&</td><td>></td><td>"</td><td>'</td></tr></table>),
    "encodes turned off by default";

is $table->generate( encode => 1 ),
    q(<table><tr><th>&lt;</th><th>=</th><th>&amp;</th><th>&gt;</th><th>&quot;</th><th>&#39;</th></tr><tr><td>&lt;</td><td>=</td><td>&amp;</td><td>&gt;</td><td>&quot;</td><td>&#39;</td></tr></table>),
    "setting encode to true encodes default chars";

is $table->generate( encode => 1, encodes => '' ),
    q(<table><tr><th>&lt;</th><th>=</th><th>&amp;</th><th>&gt;</th><th>&quot;</th><th>&#39;</th></tr><tr><td>&lt;</td><td>=</td><td>&amp;</td><td>&gt;</td><td>&quot;</td><td>&#39;</td></tr></table>),
    "setting encodes to '' with encode set to true encodes default";

is $table->generate( encode => 1, encodes => undef ),
    q(<table><tr><th>&lt;</th><th>=</th><th>&amp;</th><th>&gt;</th><th>&quot;</th><th>&#39;</th></tr><tr><td>&lt;</td><td>=</td><td>&amp;</td><td>&gt;</td><td>&quot;</td><td>&#39;</td></tr></table>),
    "setting encodes to undef with encode set to true encodes default";


$table = Spreadsheet::HTML->new( data => $spaces );
is_deeply scalar $table->_process, $expected_spaces,  "correctly substituted spaces";
is_deeply scalar $table->_process, $expected_spaces,  "only processes once";

$expected_spaces = [
    [ map { tag => 'th', cdata => $_ }, '', "foo\n", '', '' ],
    [ map { tag => 'td', cdata => $_ }, '', "foo\n", '', '' ],
];
$table = Spreadsheet::HTML->new( data => $spaces, empty => undef );
is_deeply scalar $table->_process, $expected_spaces,  "spaces untouched";

$expected_spaces = [
    [ map { tag => 'th', cdata => $_ }, '', "foo\n", '', '' ],
    [ map { tag => 'td', cdata => $_ }, '', "foo\n", '', '' ],
];
$table = Spreadsheet::HTML->new( data => $spaces, empty => '' );
is_deeply scalar $table->_process, $expected_spaces,  "correctly substituted spaces";

$expected_spaces = [
    [ map { tag => 'th', cdata => $_ }, ' ', "foo\n", ' ', ' ' ],
    [ map { tag => 'td', cdata => $_ }, ' ', "foo\n", ' ', ' ' ],
];
$table = Spreadsheet::HTML->new( data => $spaces, empty => ' ' );
is_deeply scalar $table->_process, $expected_spaces,  "correctly substituted spaces";

$expected_spaces = [
    [ map { tag => 'th', cdata => $_ }, 0, "foo\n", 0, 0 ],
    [ map { tag => 'td', cdata => $_ }, 0, "foo\n", 0, 0 ],
];
$table = Spreadsheet::HTML->new( data => $spaces, empty => 0 );
is_deeply scalar $table->_process, $expected_spaces,  "correctly substituted spaces";

$table = Spreadsheet::HTML->new( data => '&bar', encodes => 'a&' );
is $table->generate, '<table><tr><th>&amp;b&#97;r</th></tr></table>',  "ampersand does not double encode";

$table = Spreadsheet::HTML->new( data => 0, encodes => 0 );
is $table->generate, '<table><tr><th>&#48;</th></tr></table>',  "ampersand does not double encode";
