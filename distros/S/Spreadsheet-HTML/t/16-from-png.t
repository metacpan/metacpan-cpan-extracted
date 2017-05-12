#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

eval "use Imager::File::PNG";
plan skip_all => "Imager::File::PNG required" if $@;
plan tests => 10;

use_ok 'Spreadsheet::HTML';

my %attr = ( file => 't/data/simple.png', block => 4, sorted_attrs => 1, empty => undef );

my $html = '<table border="0" cellpadding="0" cellspacing="0"><tr><th height="4" style="background-color: #000000" width="8"></th><th height="4" style="background-color: #000000" width="8"></th><th height="4" style="background-color: #FFFFFF" width="8"></th><th height="4" style="background-color: #FFFFFF" width="8"></th></tr><tr><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #FFFFFF" width="8"></td><td height="4" style="background-color: #FFFFFF" width="8"></td></tr><tr><td height="4" style="background-color: #FF0000" width="8"></td><td height="4" style="background-color: #FFFFFF" width="8"></td><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #000000" width="8"></td></tr><tr><td height="4" style="background-color: #00FF00" width="8"></td><td height="4" style="background-color: #0000FF" width="8"></td><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #000000" width="8"></td></tr></table>';

my $table = new_ok 'Spreadsheet::HTML', [ %attr ];

is $table->generate,
    $html,
    "loaded simple PNG image via method"
;

is Spreadsheet::HTML::generate( %attr ),
    $html,
    "loaded simple PNG image via procedure"
;

$html = '<table border="0" cellpadding="0" cellspacing="0"><tr><th height="4" style="background-color: #000000" width="8"></th><th height="4" style="background-color: #000000" width="8"></th><th></th><th></th></tr><tr><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #000000" width="8"></td><td></td><td></td></tr><tr><td height="4" style="background-color: #FF0000" width="8"></td><td></td><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #000000" width="8"></td></tr><tr><td height="4" style="background-color: #00FF00" width="8"></td><td height="4" style="background-color: #0000FF" width="8"></td><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #000000" width="8"></td></tr></table>';
is $table->generate( alpha => 'FFFFFF' ),
    $html,
    "alpha param for image via method"
;

is Spreadsheet::HTML::generate( %attr, alpha => 'FFFFFF' ),
    $html,
    "alpha param for image via procedure"
;

$html = '<table><tr><th height="4" style="background-color: #000000" width="8"></th><th height="4" style="background-color: #000000" width="8"></th><th></th><th></th></tr><tr><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #000000" width="8"></td><td></td><td></td></tr><tr><td height="4" style="background-color: #FF0000" width="8"></td><td></td><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #000000" width="8"></td></tr><tr><td height="4" style="background-color: #00FF00" width="8"></td><td height="4" style="background-color: #0000FF" width="8"></td><td height="4" style="background-color: #000000" width="8"></td><td height="4" style="background-color: #000000" width="8"></td></tr></table>';
is $table->generate( alpha => 'FFFFFF', table => {} ),
    $html,
    "alpha param for image via method"
;

is Spreadsheet::HTML::generate( %attr, alpha => 'FFFFFF', table => {} ),
    $html,
    "alpha param for image via procedure"
;

my %extra = ( data => [ 1 .. 16 ], wrap => 4, alpha => 'FFFFFF' );

$html = '<table border="0" cellpadding="0" cellspacing="0"><tr><th height="4" style="background-color: #000000" width="8">1</th><th height="4" style="background-color: #000000" width="8">2</th><th>3</th><th>4</th></tr><tr><td height="4" style="background-color: #000000" width="8">5</td><td height="4" style="background-color: #000000" width="8">6</td><td>7</td><td>8</td></tr><tr><td height="4" style="background-color: #FF0000" width="8">9</td><td>10</td><td height="4" style="background-color: #000000" width="8">11</td><td height="4" style="background-color: #000000" width="8">12</td></tr><tr><td height="4" style="background-color: #00FF00" width="8">13</td><td height="4" style="background-color: #0000FF" width="8">14</td><td height="4" style="background-color: #000000" width="8">15</td><td height="4" style="background-color: #000000" width="8">16</td></tr></table>';

is $table->generate( %extra ),
    $html,
    "added data to simple PNG image via method"
;

is Spreadsheet::HTML::generate( %attr, %extra ),
    $html,
    "added data to simple PNG image via procedure"
;
