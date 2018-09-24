use utf8;
use strict;

BEGIN { binmode STDOUT, ':utf8'; binmode STDERR, ':utf8'; }

use Net::IDN::Encode qw(:all);

use Test::More tests => 1 + 13;
use Test::NoWarnings;

use Net::IDN::Encode qw(:all);

is(eval{domain_to_ascii('müller')} || $@, 'xn--mller-kva', 'single label (to_ascii)');
is(eval{domain_to_ascii('XN--MLLER-KVA')} || $@, 'XN--MLLER-KVA', 'single uppercase label (to_ascii)');

is(eval{domain_to_ascii('www.jürg.xn--mller-kva.com', )} || $@, 'www.xn--jrg-hoa.xn--mller-kva.com', 'mixed utf8/ace/ascii');
is(eval{domain_to_ascii('www.a.b。c．d｡com', )} || $@, 'www.a.b.c.d.com', 'mixed dots');

is(eval{domain_to_ascii("www.\x{1F985}.example", AllowUnassigned => 1)} || $@, 'www.xn--4s9h.example', 'Unicode 9.0 emoji');

is(eval{domain_to_ascii('www.ä ö ü ß.example', 'UseSTD3ASCIIRules' => 0)}, 'www.xn--   -7kav3ivb.example', 'blank (without STD3 rules) (to_unicode)') or diag $@;
is(eval{domain_to_ascii('www.ä ö ü ß.example', 'UseSTD3ASCIIRules' => 1)}, undef, 'blank (with STD3 rules) (to_unicode)') or diag $@;
is(eval{domain_to_ascii('www.xn--   -7kav3ivb.example', 'UseSTD3ASCIIRules' => 0)}, 'www.xn--   -7kav3ivb.example', 'blank (without STD3 rules) (to_unicode pass-through)') or diag $@;
is(eval{domain_to_ascii('www.xn--   -7kav3ivb.example', 'UseSTD3ASCIIRules' => 1)}, 'www.xn--   -7kav3ivb.example', 'blank (with STD3 rules) (to_unicode pass-through)') or diag $@;

is(eval{domain_to_ascii("I.\x{2665}.Perl.invalid")}, 'I.xn--g6h.Perl.invalid', 'mixed case');
is(eval{domain_to_ascii("I.xn--g6h.Perl.invalid")}, 'I.xn--g6h.Perl.invalid', 'mixed case');
is(eval{domain_to_ascii('www.xn--garbage')}, 'www.xn--garbage', 'Invalid A-label');
is(eval{domain_to_ascii('_test._srv.müller.example.com')}, '_test._srv.xn--mller-kva.example.com', 'SRV record');
