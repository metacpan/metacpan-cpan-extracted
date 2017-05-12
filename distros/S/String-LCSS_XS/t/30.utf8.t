use Test::More;
use strict;

use String::LCSS_XS qw(lcss);

sub _u   { my $s = shift; utf8::upgrade(   $s ); $s }
sub _d   { my $s = shift; utf8::downgrade( $s ); $s }
sub _enc { my $s = shift; utf8::encode(    $s ); $s }

sub _f {
    my ($lcss, $s, $e) = @_;
    if (defined($lcss)) {
        $lcss = join(':', map sprintf('%02X', ord($_)), $lcss =~ /./gs );
    } else {
        $lcss = '[undef]';
    }
    $s = '[undef]' if !defined($s);
    $e = '[undef]' if !defined($e);
    return "$lcss,$s,$e";
}

my @tests = (
    [ "dd" => _d("\xB0\xB1\xB2"), _d("\xA1\xB1\xC1"), "\xB1", 1, 1 ],
    [ "du" => _d("\xB0\xB1\xB2"), _u("\xA1\xB1\xC1"), "\xB1", 1, 1 ],
    [ "ud" => _u("\xB0\xB1\xB2"), _d("\xA1\xB1\xC1"), "\xB1", 1, 1 ],
    [ "uu" => _u("\xB0\xB1\xB2"), _u("\xA1\xB1\xC1"), "\xB1", 1, 1 ],

    [ "Same 8-bit PV, different UTF8 (1)" => _u("\xC0"), _d(_enc("\xC0")), undef, undef, undef ],
    [ "Same 8-bit PV, different UTF8 (2)" => _d(_enc("\xC0")), _u("\xC0"), undef, undef, undef ],

    [ "Same >8-bit PV, different UTF8 (1)" => _u("\x{2660}"), _d(_enc("\x{2660}")), undef, undef, undef ],
    [ "Same >8-bit PV, different UTF8 (2)" => _d(_enc("\x{2660}")), _u("\x{2660}"), undef, undef, undef ],
);

plan tests => 10+@tests;

for (@tests) {
    my ($test, $s1, $s2, $exp_lcss, $exp_s, $exp_e) = @$_;
    is( _f(lcss($s1, $s2)), _f($exp_lcss, $exp_s, $exp_e), $test);
}

################################################################
# old tests
my $s = "\x{263a}xyzz";
my $t = "abcxyzefg";

my ($longest,$p1,$p2) = lcss ( $s, $t );
is ( $longest, "xyz", "xyzzx vs abcxyzefg" );
is( $p1, 1, "position unicode string correct");
is( $p2, 3, "position non-unicode string correct");

($longest,$p2,$p1) = lcss ( $t, $s );
is ( $longest, "xyz", "xyzzx vs abcxyzefg" );
is( $p1, 1, "position unicode string correct");
is( $p2, 3, "position non-unicode string correct");

$t = "abc\x{263a}xyzefg";
($longest,$p1,$p2) = lcss ( $s, $t );
ok(utf8::is_utf8($longest), "we got an utf8 string");
is( $longest , "\x{263a}xyz", "xyzzx vs abcxyzefg" );
is( $p1, 0, "position unicode string correct");
is( $p2, 3, "position non-unicode string correct");

