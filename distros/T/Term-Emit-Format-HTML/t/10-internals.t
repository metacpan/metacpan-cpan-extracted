#!perl -w
use strict;
use warnings;
use Term::Emit::Format::HTML;
use Test::More tests => 53;

my $ix;
my $line;
my $clin;
my $want;

# aoi() works on pre-cleaned lines, so the test is easy
$line = q{};
$ix = Term::Emit::Format::HTML::_amount_of_indentation($line);
is($ix, 0, "Empty string");

$line = " ";
$ix = Term::Emit::Format::HTML::_amount_of_indentation($line);
is($ix, 0, "_aoi(): Just a blank");

$line = "   ";
$ix = Term::Emit::Format::HTML::_amount_of_indentation($line);
is($ix, 0, "_aoi(): Just some blanks");

$line = "Has no indentation";
$ix = Term::Emit::Format::HTML::_amount_of_indentation($line);
is($ix, 0, "_aoi(): $line");

$line = " Has one space";
$ix = Term::Emit::Format::HTML::_amount_of_indentation($line);
is($ix, 1, "_aoi(): $line");

$line = "  Has two spaces";
$ix = Term::Emit::Format::HTML::_amount_of_indentation($line);
is($ix, 2, "_aoi(): $line");

$line = "    Has four spaces";
$ix = Term::Emit::Format::HTML::_amount_of_indentation($line);
is($ix, 4, "_aoi(): $line");

# Tests for _clean_line()
$line = q{};
$want = q{};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): Empty string");

$line = q{ };
$want = q{};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): One blank string");

$line = q{   };
$want = q{};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): Multiblank string");

$line = qq{\t \t };
$want = q{};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): Tabs and blanks string");

$line = q{Simple text};
$want = q{Simple text};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{Simple text with trailing spaces    };
$want = q{Simple text with trailing spaces};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{ Preserves leading space};
$want = q{ Preserves leading space};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{*Tight bullet};
$want = q{Tight bullet};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{* Basic bullet};
$want = q{ Basic bullet};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{+   Level 2 bullet};
$want = q{   Level 2 bullet};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{ *Tight bullet with leader};
$want = q{Tight bullet with leader};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{ * Basic bullet with leader};
$want = q{ Basic bullet with leader};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{ +   Level 2 bullet with leader};
$want = q{   Level 2 bullet with leader};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{ * L1 Bullet};
$want = q{ L1 Bullet};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{ +   L2 Bullet};
$want = q{   L2 Bullet};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{ -     L3 Bullet};
$want = q{     L3 Bullet};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{ .       L4 Bullet};
$want = q{       L4 Bullet};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{ #LA Bullet};
$want = q{LA Bullet};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = q{@  LB Bullet};
$want = q{  LB Bullet};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = qq{Backspace tests - none};
$want =  q{Backspace tests - none};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = qq{Backspace testx\010s - one};
$want =  q{Backspace tests - one};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = qq{Backspace tesxx\010\010ts - two};
$want =  q{Backspace tests - two};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = qq{Backspace texxx\010\010\010sts - three};
$want =  q{Backspace tests - three};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = qq{X\010Backspace tests - one at start};
$want =  q{Backspace tests - one at start};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = qq{Backspace tests - one at enz\010d};
$want =  q{Backspace tests - one at end};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = qq{Backspace tests - two at emb\010\010nd};
$want =  q{Backspace tests - two at end};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

$line = qq{Bacc\010kspace yr\010\010tests - scattered};
$want =  q{Backspace tests - scattered};
$clin = Term::Emit::Format::HTML::_clean_line($line);
is($clin, $want, "_cl(): $clin");

# Tests for _has_ellipsis()
my $he;

$line = "This has no ellipsis";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok(!$he, "_he(): $line");

$line = "This has some ellipsis...";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok( $he, "_he(): $line");

$line = "  This has no ellipsis . . . ";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok(!$he, "_he(): $line");

$line = "  This has some ellipsis  ... ";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok( $he, "_he(): $line");

$line = "* This has no ellipsis.. .";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok(!$he, "_he(): $line");

$line = "* With more dots.....";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok( $he, "_he(): $line");

$line = "* With more dots and space..... ";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok( $he, "_he(): $line");

$line = "* With a progress... 3/4 ";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok( $he, "_he(): $line");

$line = "* With a progress... 10%";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok( $he, "_he(): $line");

$line = "* With a progress overwrite... 10%\010\010\010\010 20%";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok( $he, "_he(): $line");

$line = "* With a status....... [YO]";
$he = Term::Emit::Format::HTML::_has_ellipsis($line);
ok( $he, "_he(): $line");

# Tests for _has_status()
my $hs;

$line = "* Without status...";
$hs = Term::Emit::Format::HTML::_has_status($line);
ok(!$hs, "_he(): $line");

$line = "* Without status 2....... [";
$hs = Term::Emit::Format::HTML::_has_status($line);
ok(!$hs, "_he(): $line");

$line = "* Without status 3....... []";
$hs = Term::Emit::Format::HTML::_has_status($line);
ok(!$hs, "_he(): $line");

$line = "* Not my status!.......[NOTME]";
$hs = Term::Emit::Format::HTML::_has_status($line);
ok(!$hs, "_he(): $line");

$line = "* Still not me!....... [NOTME] ";  #trailing blank
$hs = Term::Emit::Format::HTML::_has_status($line);
ok(!$hs, "_he(): $line");

$line = "* With a status....... [YO]";
$hs = Term::Emit::Format::HTML::_has_status($line);
is($hs, "YO", "_he(): $line");

$line = " [JUST]";
$hs = Term::Emit::Format::HTML::_has_status($line);
is($hs, "JUST", "_he(): $line");

$line = "... [MIN]";
$hs = Term::Emit::Format::HTML::_has_status($line);
is($hs, "MIN", "_he(): $line");
