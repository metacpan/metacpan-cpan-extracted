use 5.16.0;
use strict;
use warnings;
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


my @cut_tests = (
    [ "\x{61}\x{ff41}\x{4e2d}\x{b7}\x{1f44d}",      $wide ? 7 : 6, [ "\x{61}\x{ff41}\x{4e2d}\x{b7}", "\x{1f44d}" ] ],
    [ "\x{68}\x{65}\x{6c}\x{6c}\x{6f}",                         2, [ "\x{68}\x{65}",                 "\x{6c}\x{6c}\x{6f}"                   ] ], # "hello"
    [ "\x{68}\x{e9}\x{6c}\x{6c}\x{6f}",             $wide ? 3 : 2, [ "\x{68}\x{e9}",                 "\x{6c}\x{6c}\x{6f}"                   ] ], # "héllo"
    [ "\x{61}\x{3042}\x{62}\x{3044}\x{63}\x{3046}",             2, [ "\x{61}\x{20}",                 "\x{3042}\x{62}\x{3044}\x{63}\x{3046}" ] ], # "aあbいcう"
    [ "\x{61}\x{ff}\x{62}\x{63}\x{64}",                         2, [ "\x{61}\x{ff}",                 "\x{62}\x{63}\x{64}"                   ] ], # "a\x{ff}bcd"
    [ "\x{0e2a}\x{0e27}\x{0e31}\x{0e2a}\x{0e14}\x{0e35}",       2, [ "\x{0e2a}\x{0e27}\x{0e31}",     "\x{0e2a}\x{0e14}\x{0e35}"             ] ], # "สวัสดี"
    [ "\x{61}\x{1f60a}\x{1f60a}\x{1f60a}\x{1f60a}",             4, [ "\x{61}\x{1f60a}\x{20}",        "\x{1f60a}\x{1f60a}\x{1f60a}"          ] ], # "a😊😊😊😊"
    [ "\x{61}\x{1f60a}\x{1f60a}\x{1f60a}\x{1f60a}",             5, [ "\x{61}\x{1f60a}\x{1f60a}",     "\x{1f60a}\x{1f60a}"                   ] ], # "a😊😊😊😊"
    [ "\x{1f60a}\x{1f60a}\x{1f60a}\x{1f60a}",                   4, [ "\x{1f60a}\x{1f60a}",           "\x{1f60a}\x{1f60a}"                   ] ], # "😊😊😊😊"
    [ "\x{1f60a}\x{1f60a}\x{1f60a}\x{1f60a}",                   5, [ "\x{1f60a}\x{1f60a}\x{20}",     "\x{1f60a}\x{1f60a}"                   ] ], # "😊😊😊😊"
);


for my $d ( @cut_tests ) {
    my ( $str, $w, $ret ) = @$d;
    my ( $first, $rem ) = Term::Choose::LineFold::XS::cut_to_printwidth( $str, $w );
    is_deeply( [ $first, $rem ], $ret, "cut_to_printwidth( $str, $w ): [ |$first|, |$rem| ] -> [ |$ret->[0]|, |$ret->[0]| ]" );
}


for my $d ( @cut_tests ) {
    my ( $str, $w, $ret ) = @$d;
    my $cut = Term::Choose::LineFold::XS::cut_to_printwidth( $str, $w );
    is( $cut, $ret->[0], "scalar cut_to_printwidth( $str, $w ): |$cut| -> |$ret->[0]|" );
}





for my $d ( @cut_tests ) {
    my ( $str, $w, $ret ) = @$d;
    my $expected = $ret->[0];
    my $adjusted = Term::Choose::LineFold::XS::adjust_to_printwidth( $str, $w );
    is( $adjusted, $expected, "adjust_to_printwidth( $str, $w ): |$adjusted| -> |$expected|" );
}



my $w = 10;
my @pad_tests = (
    [ "\x{61}\x{ff41}\x{4e2d}\x{b7}\x{1f44d}", $wide ? 1 : 2 ],
    [ "\x{68}\x{e9}\x{6c}\x{6c}\x{6f}",        $wide ? 4 : 5 ], # "héllo"
    [ "\x{61}\x{ff}\x{62}\x{63}\x{64}",                    5 ], # "a\x{ff}bcd"
    [ "\x{0e2a}\x{0e27}\x{0e31}\x{0e2a}\x{0e14}\x{0e35}",  6 ], # "สวัสดี"
    [ "\x{61}\x{1f60a}\x{1f60a}\x{1f60a}\x{1f60a}",        1 ], # "a😊😊😊😊"
    [ "\x{1f60a}\x{1f60a}\x{1f60a}\x{1f60a}",              2 ], # "😊😊😊😊"
    [ "",                                                 10 ],
);

for my $d ( @pad_tests ) {
    my ( $str, $trailing_saces ) = @$d;
    my $expected = $str . ( "\x{20}" x $trailing_saces );
    my $adjusted = Term::Choose::LineFold::XS::adjust_to_printwidth( $str, $w );
    is( $adjusted, $expected, "adjust_to_printwidth( $str, $w ): |$adjusted| -> |$expected|" );
}








done_testing();
