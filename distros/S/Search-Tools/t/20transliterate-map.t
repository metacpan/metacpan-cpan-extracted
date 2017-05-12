#!/usr/bin/perl
use strict;
use Test::More tests => 10;
use Data::Dump qw( dump );
use Search::Tools::Transliterate;
use Search::Tools::UTF8;
use utf8;

binmode STDERR, ':utf8';

my $string = "ăşţâîĂŞŢÂÎ";
my $ascii  = 'astaiASTAIsStT';

# new romanian utf8 chars
$string .= "\x{0218}";
$string .= "\x{0219}";
$string .= "\x{021A}";
$string .= "\x{021B}";

my $tr = Search::Tools::Transliterate->new( ebit => 0 );
$tr->map->{"\x{0218}"} = 's';
$tr->map->{"\x{0219}"} = 'S';
$tr->map->{"\x{021A}"} = 't';
$tr->map->{"\x{021B}"} = 'T';

#print STDERR $string . "\n";
#print STDERR $tr->convert($string) . "\n";

is( $ascii, $tr->convert($string), "transliterate with map" );

# test 0.21 and 0.22 bugs
my $tr2 = Search::Tools::Transliterate->new( ebit => 0 );

ok( keys %{ $tr2->map }, "map init has keys" );

my $tr3 = Search::Tools::Transliterate->new( ebit => 1 );

is( $tr3->map->{"\x{0218}"}, 'Ş', "ebit 1 3rd instance" );

# cp1252

#$tr->debug(1);
my $cp1252 = "a\x{80}b\x{82}c\x{83}d\x{91}e\x{92}f\x{93}g";

# \xcf char == \xc3\x8f octets
my $utf8_not_1252 = to_utf8("\xcf");
ok( looks_like_cp1252($cp1252),         "looks_like_cp1252" );
ok( !looks_like_cp1252($utf8_not_1252), "utf8 string !looks_like_cp1252" );
ok( my $cp1252_conv = $tr->convert1252($cp1252), "convert1252" );

#diag("cp1252");
#debug_bytes($cp1252_conv);

#debug_bytes($utf8_not_1252);

#diag( dump $cp1252_conv );
is( $cp1252_conv, qq{aEURb'cfd'e'f"g}, "transliterate 1252" );

my $more1252 = "what\x92s a person";

#dump( $more1252 );
ok( my $more1252_conv = $tr->convert1252($more1252), "convert1252 more1252" );
is( $more1252_conv, "what's a person", "transliterate more1252" );
is( $tr->convert( to_utf8($more1252) ),
    "what s a person",
    "convert more1252"
);

#diag("more1252");
#debug_bytes($more1252);
#diag("more1252_conv");
#debug_bytes($more1252_conv);

1;

