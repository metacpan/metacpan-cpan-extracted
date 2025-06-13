use 5.16.0;
use strict;
use warnings;
#use utf8;
use open qw(:std :utf8);
use Test::More;
use Term::Choose::LineFold::XS;


#my $wide = $ENV{TC_AMBIGUOUS_WIDTH_IS_WIDE};
my $wide;                                          # 24.03.2025
if ( exists $ENV{TC_AMBIGUOUS_WIDTH_IS_WIDE} ) {   #
    $wide = $ENV{TC_AMBIGUOUS_WIDTH_IS_WIDE};      #
}                                                  #
else {                                             #
    $wide = $ENV{TC_AMBIGUOUS_WIDE};               #
}                                                  #


my @char_tests = (
    [ "\x{61}", 1 ],                   # a
    [ "\x{ff41}", 2 ],                 # Full-width a
    [ "\x{4e2d}", 2 ],                 # CJK character 中,
    [ "\x{b7}", $wide ? 2 : 1 ],       # Middle dot ·, ambiguous width
    [ "\x{1f44d}", 2 ],                # 👍
    [ "\x{20}", 1 ],
    [ "\x{ff71}", 1 ],                 # Half-width Katakana ｱ
    [ "\x{1f600}", 2 ],                # 😀
    [ "\x0", 1 ],                      # Null character, default to 1
    [ "\x{11000}", 1 ],                # Above Unicode range, defaults to 1
    [ "\x{ffe9}", 1 ],                 # Yen sign ￥
    [ "\x{ffe5}", 2 ],                 # Fullwidth Yen sign ￥
);

for my $d ( @char_tests ) {
    my ( $char, $expected_w ) = @$d;
    my $w = Term::Choose::LineFold::XS::char_width( ord $char );
    ok( $w == $expected_w, "char_width( ord $char ): $w -> $expected_w" );
}


my @str_tests = (
    [ "\x{61}\x{ff41}\x{4e2d}\x{b7}\x{1f44d}\x{20}\x{ff71}\x{3042}", $wide ? 13 : 12  ],
    [ "\x{68}\x{65}\x{6c}\x{6c}\x{6f}",                         5 ], # "hello"
    [ "\x{68}\x{e9}\x{6c}\x{6c}\x{6f}",             $wide ? 6 : 5 ], # "héllo"
    [ "\x{61}\x{3042}\x{62}\x{3044}\x{63}\x{3046}",             9 ], # "aあbいcう"
    [ "\x{1d11e}\x{1d122}\x{1d12b}",                            3 ], # musical symbols
    [ "\x{61}\x{ff}\x{62}\x{63}\x{64}",                         5 ], # "a\x{ff}bcd" malformed UTF-8
    [ "\x{ff21}\x{ff22}\x{ff23}\x{ff24}\x{ff25}",              10 ], # "ＡＢＣＤＥ"
    [ "\x{3053}\x{3093}\x{306b}\x{3061}\x{306f}",              10 ], # "こんにちは"
    [ "\x{c548}\x{b155}\x{d558}\x{c138}\x{c694}",              10 ], # "안녕하세요"
    [ "\x{0e2a}\x{0e27}\x{0e31}\x{0e2a}\x{0e14}\x{0e35}",       4 ], # "สวัสดี"
    [ "\x{48}\x{65}\x{6c}\x{6c}\x{6f}\x{20}\x{1f60a}\x{20}",    9 ], # "Hello 😊 "
    [ "\x{77}\x{6f}\x{72}\x{6c}\x{64}\x{20}\x{1f389}",          8 ], # "world 🎉"
);

for my $d (@str_tests) {
    my ( $str, $expected_w ) = @$d;
    my $w = Term::Choose::LineFold::XS::print_columns( $str );
    ok( $w == $expected_w, "print_columns( $str ): $w -> $expected_w" );
}

done_testing();
