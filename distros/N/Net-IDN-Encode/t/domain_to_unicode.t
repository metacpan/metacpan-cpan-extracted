use utf8;
use strict;

BEGIN { binmode STDOUT, ':utf8'; binmode STDERR, ':utf8'; }

use Test::More tests => 1 + 15;
use Test::NoWarnings;

use Net::IDN::Encode qw(:all);

is(eval{domain_to_unicode('xn--mller-kva')} || $@, 'müller', 'single label (to_unicode)');
is(eval{domain_to_unicode('XN--MLLER-KVA')} || $@, 'müller', 'single uppercase label (to_unicode)');

is(eval{domain_to_unicode('www.jürg.xn--mller-kva.com', )} || $@, 'www.jürg.müller.com', 'mixed utf8/ace/ascii (to_unicode)');
is(eval{domain_to_unicode('www.a.b。c．d｡com', )} || $@, 'www.a.b。c．d｡com', 'mixed dots (to_unicode)');

is(eval{domain_to_unicode("www.xn--4s9h.example", AllowUnassigned => 1)} || $@, "www.\x{1F985}.example", 'Unicode 9.0 emoji');

is(eval{domain_to_unicode('www.ä ö ü ß.example', 'UseSTD3ASCIIRules' => 0)}, 'www.ä ö ü ß.example', 'blank (without STD3 rules) (to_unicode)') or diag $@;
is(eval{domain_to_unicode('www.ä ö ü ß.example', 'UseSTD3ASCIIRules' => 1)}, undef, 'blank (without STD3 rules) (to_unicode pass-through)') or diag $@;
is(eval{domain_to_unicode('www.xn--   -7kav3ivb.example', 'UseSTD3ASCIIRules' => 0)}, 'www.ä ö ü ß.example', 'blank (with STD3 rules) (to_unicode)') or diag $@;
is(eval{domain_to_unicode('www.xn--   -7kav3ivb.example', 'UseSTD3ASCIIRules' => 1)}, undef, 'blank (with STD3 rules) (to_unicode pass-through)') or diag $@;

is(eval{domain_to_unicode("EXAMPLE.XN--11B5BS3A9AJ6G")}, 'EXAMPLE.परीक्षा', 'lowercase IDNA prefix') or diag $@;
is(eval{domain_to_unicode("EXAMPLE.xn--11B5BS3A9AJ6G")}, 'EXAMPLE.परीक्षा', 'uppercase IDNA prefix') or diag $@;

is(eval{domain_to_unicode("I.\x{2665}.Perl.invalid")}, "I.\x{2665}.Perl.invalid", 'mixed case');
is(eval{domain_to_unicode('I.xn--g6h.Perl.invalid')}, "I.\x{2665}.Perl.invalid", 'mixed case');
is(eval{domain_to_unicode('_test._srv.xn--mller-kva.example.com')}, '_test._srv.müller.example.com', 'SRV record');

is(eval{domain_to_unicode('xn--zcaa.de')}, 'ßß.de', 'bare ßß');
