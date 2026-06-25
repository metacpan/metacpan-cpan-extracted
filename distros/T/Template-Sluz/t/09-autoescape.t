#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

# ---------------------------------------------------------------------------
# Test opt-in auto_escape mode — escapes all variable output automatically
# ---------------------------------------------------------------------------

my $s_off = Template::Sluz->new(auto_escape => 0);
my $s_on  = Template::Sluz->new(auto_escape => 1);

$_->assign('name'        , 'Scott')                     for ($s_off, $s_on);
$_->assign('xss'         , '<script>alert(1)</script>') for ($s_off, $s_on);
$_->assign('safe_html'   , '<b>bold</b>')               for ($s_off, $s_on);
$_->assign('nums'        , [1, 2, 3])                   for ($s_off, $s_on);
$_->assign('hashref'     , {a => '<tag>'})              for ($s_off, $s_on);
$_->assign('empty_string', '')                          for ($s_off, $s_on);
$_->assign('zero'        , 0)                           for ($s_off, $s_on);

# ---------------------------------------------------------------------------
# auto_escape => 0 — everything raw (existing behaviour)
# ---------------------------------------------------------------------------
is($s_off->parse_string('{$name}')      , 'Scott'                                , 'off: plain var unchanged');
is($s_off->parse_string('{$xss}')       , '<script>alert(1)</script>'            , 'off: XSS payload raw');
is($s_off->parse_string('{$nums}')      , 'ARRAY'                                , 'off: array ref');
is($s_off->parse_string('{$xss|escape}'), '&lt;script&gt;alert(1)&lt;/script&gt;', 'off: explicit escape works');

# ---------------------------------------------------------------------------
# auto_escape => 1 — auto-escaped
# ---------------------------------------------------------------------------
is($s_on->parse_string('{$name}')                 , 'Scott'                                , 'on: plain text unchanged');
is($s_on->parse_string('{$empty_string}')         , ''                                     , 'on: empty string');
is($s_on->parse_string('{$zero}')                 , '0'                                    , 'on: zero preserved');
is($s_on->parse_string('{$nums}')                 , 'ARRAY'                                , 'on: array ref passthrough');
is($s_on->parse_string('{$xss}')                  , '&lt;script&gt;alert(1)&lt;/script&gt;', 'on: XSS auto-escaped');
is($s_on->parse_string('{$safe_html}')            , '&lt;b&gt;bold&lt;/b&gt;'              , 'on: HTML auto-escaped');
# noescape bypass
is($s_on->parse_string('{$xss|noescape}')         , '<script>alert(1)</script>'            , 'on: noescape bypass');
is($s_on->parse_string('{$safe_html|noescape}')   , '<b>bold</b>'                          , 'on: noescape raw HTML');
# Explicit escape — no double-escaping
is($s_on->parse_string('{$xss|escape}')           , '&lt;script&gt;alert(1)&lt;/script&gt;', 'on: explicit escape no double');
# Chained: modifier before auto-escape
is($s_on->parse_string('{$safe_html|uc|noescape}'), '<B>BOLD</B>'                          , 'on: uc + noescape');
# Chained: auto-escape wraps all modifiers
is($s_on->parse_string('{$safe_html|uc}')         , '&lt;B&gt;BOLD&lt;/B&gt;'              , 'on: uc then auto-escaped');

# ---------------------------------------------------------------------------
# Foreach with auto_escape
# ---------------------------------------------------------------------------
my @bad = ('<a>', '<b>', '<c>');
$s_on->assign('bad_items', \@bad);

is($s_on->parse_string('{foreach $bad_items as $x}{$x}{/foreach}')         , '&lt;a&gt;&lt;b&gt;&lt;c&gt;', 'on: foreach auto-escaped');
is($s_on->parse_string('{foreach $bad_items as $x}{$x|noescape}{/foreach}'), '<a><b><c>'                  , 'on: foreach noescape');

# ---------------------------------------------------------------------------
# If block payload with auto_escape
# ---------------------------------------------------------------------------
$s_on->assign('flag', 1);
$s_on->assign('payload', '<img src=x>');

is($s_on->parse_string('{if $flag}{$payload}{/if}')         , '&lt;img src=x&gt;', 'on: if-block escaped');
is($s_on->parse_string('{if $flag}{$payload|noescape}{/if}'), '<img src=x>'      , 'on: if-block noescape');

# ---------------------------------------------------------------------------
# Hashref iteration with auto_escape
# ---------------------------------------------------------------------------
$s_on->assign('items_hash', {one => '<1>', two => '<2>'});

is($s_on->parse_string('{foreach $items_hash as $v}{$v}{/foreach}'), '&lt;1&gt;&lt;2&gt;', 'on: hash foreach sorted escaped');

done_testing();
