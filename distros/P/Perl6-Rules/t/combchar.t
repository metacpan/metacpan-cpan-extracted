use Perl6::Rules;
use Test::Simple 'no_plan';
use charnames ':full';

$unichar = "\N{GREEK CAPITAL LETTER ALPHA}";
$combchar = "\N{LATIN CAPITAL LETTER A}\N{COMBINING ACUTE ACCENT}";

ok( "A" =~ m/^<.>$/, "ASCII" );
ok( $combchar =~ m/^<.>$/, "Unicode combining" );
ok( $unichar =~ m/^<.>$/, "Unicode" );
