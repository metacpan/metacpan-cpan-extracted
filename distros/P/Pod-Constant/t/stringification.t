use strict;
use warnings;

=head1 A LIST OF THINGS

Quoted strings are taken verbatim:

X<$str1=>"Foo"
X<$str2=>"Foo!"
X<$str3=>"Foo."
X<$str4=>"Foo bar"

Special characters are not parsed:

X<$spec=>"Foo\nbar"

Single quotes and backticks are also supported:

X<$quote1=>'Whizzang!'
X<$quote2=>`12,345`

Unquoted strings may be treated as numbers:

X<$num1=>53
X<$num2=>53.2
X<$num3=>-999
X<$num4=>1,234
X<$num5=>-15.9e1

We strip trailing punctuation:

X<$num6=>53.
X<$num7=>53.2.
X<$num8=>-999!

Otherwise we try to parse as a string, but strip
trailing punctuation.

X<$ustr1=>/home/foo/blah.txt
X<$ustr2=>\\pizza\cheeseburgers
X<$ustr3=>simple.
X<$ustr4=>foo bar.
X<$ustr5=>Ardy!

=cut

use Test::More tests => 20;
use Test::Warn;

use Pod::Constant qw(
    $str1 $str2 $str3 $str4 $spec
    $quote1 $quote2
    $num1 $num2 $num3 $num4 $num5
    $num6 $num7 $num8
    $ustr1 $ustr2 $ustr3 $ustr4 $ustr5
);

is( $str1, "Foo", 'quoted string' );
is( $str2, "Foo!", 'quoted string with trailing punctuation' );
is( $str3, "Foo.", 'quoted string with trailing punctuation' );
is( $str4, "Foo bar", 'quoted string with whitespace' );

is( $spec, "Foo\\nbar", 'special characters not parsed' );

is( $quote1, 'Whizzang!', 'single quotes' );
is( $quote2, '12,345', 'backtick quotes' );

is( $num1, 53 );
is( $num2, 53.2 );
is( $num3, -999 );
is( $num4, 1234, 'number - commas removed' );
ok( abs($num5 - -15.9e1) < 1e-6, 'number - floating point' );
is( $num6, 53 );
is( $num7, 53.2 );
is( $num8, -999 );

is( $ustr1, '/home/foo/blah.txt' );
is( $ustr2, '\\\\pizza\\cheeseburgers' );
is( $ustr3, 'simple' );
is( $ustr4, 'foo' );
is( $ustr5, 'Ardy' );

