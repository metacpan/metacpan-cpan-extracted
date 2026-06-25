#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

my $sluz = setup_sluz(extra => {
    xss_payload   => '<script>alert(1)</script>',
    html_fragment => '<img src=x onerror=alert(1)>',
    amps          => 'A & B',
    quotes        => qq{"double" and 'single'},
    angles        => '<tag>',
    mixed_case    => '<Script>',
    bad_items     => ['<a>', '<b>', '<c>'],
});

# -------------------------------------------------------------------
# Escape modifier tests (CWE-79 XSS mitigation)
# -------------------------------------------------------------------

# Basic behaviour
is($sluz->parse_string('{$first|escape}'),        'Scott',  'No HTML chars, unchanged');
is($sluz->parse_string('{$animal|escape}'),       'Kitten', 'Plain text unchanged');
is($sluz->parse_string('{$array|escape}'),        'ARRAY',  'Array ref still shows ARRAY');
is($sluz->parse_string('{$bogus_var|escape}'),    '',       'Undefined var yields empty');
is($sluz->parse_string('{$null|escape}'),         '',       'Null var yields empty');
is($sluz->parse_string('{$zero|escape}'),         '0',      'Zero preserved');

# XSS payloads
is($sluz->parse_string('{$xss_payload|escape}'),
    '&lt;script&gt;alert(1)&lt;/script&gt;', 'XSS script tag');

is($sluz->parse_string('{$html_fragment|escape}'),
    '&lt;img src=x onerror=alert(1)&gt;',   'XSS img tag');

# Entity encoding coverage
is($sluz->parse_string('{$amps|escape}'),   'A &amp; B',                                  'Ampersand');
is($sluz->parse_string('{$quotes|escape}'), '&quot;double&quot; and &#x27;single&#x27;', 'Double and single quotes');
is($sluz->parse_string('{$angles|escape}'), '&lt;tag&gt;',                                'Angle brackets');

# Chained modifiers
is($sluz->parse_string('{$mixed_case|uc|escape}'),   '&lt;SCRIPT&gt;',       'Chained uc + escape');
is($sluz->parse_string('{$mixed_case|escape|uc}'),   '&LT;SCRIPT&GT;',       'Chained escape + uc');

# Escape as function call in expression block
is($sluz->parse_string('{escape($xss_payload)}'),
    '&lt;script&gt;alert(1)&lt;/script&gt;', 'Callable form');

# Escape inside foreach
is($sluz->parse_string('{foreach $array as $x}{$x|escape}-{/foreach}'),
    'one-two-three-', 'Inside foreach (no HTML chars)');

is($sluz->parse_string('{foreach $bad_items as $x}{$x|escape}{/foreach}'),
    '&lt;a&gt;&lt;b&gt;&lt;c&gt;', 'Foreach with XSS payloads');

done_testing();
