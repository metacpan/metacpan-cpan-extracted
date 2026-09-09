#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::SAML ();

use MIME::Base64 ();
use Time::Local ();

# The bundled codecs against the core oracles, in the way Punk-Challenge
# tests its bundled SHA-256 against Digest::SHA. A codec written from a
# specification and tested only against itself agrees with itself.
#
# The inputs are chosen to SELECT each branch rather than to be varied:
# a random corpus of base64 exercises the three-byte group and almost
# never the two padding tails.

# ---- base64 ----------------------------------------------------------

for my $case (
    ['empty',            ''],
    ['one byte, xx==',   "\x00"],
    ['two bytes, xxx=',  "\x00\x01"],
    ['three, no pad',    "\x00\x01\x02"],
    ['four',             "\x00\x01\x02\x03"],
    ['high bits',        "\xff\xfe\xfd"],
    ['+ and / present',  "\xfb\xef\xbe"],
    ['long',             join('', map { chr($_ % 256) } 0 .. 999)],
) {
    my ($name, $bytes) = @$case;
    is Punk::SAML::_b64_encode($bytes), MIME::Base64::encode_base64($bytes, ''),
        "base64 encode: $name";
    is Punk::SAML::_b64_decode(Punk::SAML::_b64_encode($bytes)), $bytes,
        "base64 round trip: $name";
}

# Strict on the way in. Each of these is something a tolerant decoder
# accepts and this one must not.
for my $bad (
    ['url alphabet',        '-_=='],
    ['whitespace',          'AA =='],
    ['newline',             "AAAA\nAAAA"],
    ['bad length',          'AAAAA'],
    ['padding in middle',   'AA==AA=='],
    ['triple padding',      'A==='],
    ['lone padding',        '='],
    ['data after padding',  'AA==A'],
    ['non-zero tail bits',  'AB=='],
    ['not base64 at all',   '****'],
) {
    my ($name, $str) = @$bad;
    is Punk::SAML::_b64_decode($str), undef, "base64 refuses $name";
}

# The XML variant accepts the line wrapping every IdP puts in a
# certificate, and nothing else.
{
    my $bytes = join '', map { chr($_ % 256) } 0 .. 200;
    my $wrapped = MIME::Base64::encode_base64($bytes);   # wraps at 76
    like $wrapped, qr/\n/, 'the oracle wrapped it';
    is Punk::SAML::_b64_decode($wrapped, 1), $bytes,
        'the xml variant accepts wrapping';
    is Punk::SAML::_b64_decode($wrapped, 0), undef,
        'the strict variant does not';
    is Punk::SAML::_b64_decode('-_==', 1), undef,
        'and the xml variant still refuses the url alphabet';
}

# ---- raw DEFLATE, stored blocks --------------------------------------

SKIP: {
    eval { require IO::Uncompress::RawInflate; 1 }
        or skip 'IO::Uncompress::RawInflate required', 4;

    for my $case (
        ['empty',            ''],
        ['short',            'hello'],
        ['a block boundary', 'x' x 65535],
        ['past one block',   'y' x 70000],
    ) {
        my ($name, $bytes) = @$case;
        my $out;
        my $z = Punk::SAML::_deflate($bytes);
        # Transparent => 0: IO::Uncompress passes plain data straight
        # through when it does not recognise a stream, which would turn
        # a broken encoder into a passing test.
        no warnings 'once';
        IO::Uncompress::RawInflate::rawinflate(\$z => \$out, Transparent => 0)
            or do {
                fail "deflate: $name "
                   . "($IO::Uncompress::RawInflate::RawInflateError)";
                next;
            };
        is $out, $bytes, "deflate round trip through the oracle: $name";
    }
}

# ---- the XML escape --------------------------------------------------

is Punk::SAML::_xml_escape(q{a&b<c>d"e'f}),
   'a&amp;b&lt;c&gt;d&quot;e&apos;f', 'every escaped character';
is Punk::SAML::_xml_escape('plain'), 'plain', 'and nothing else is touched';
is Punk::SAML::_xml_escape(''), '', 'empty';

# ---- xs:dateTime -----------------------------------------------------

{
    my $t = Time::Local::timegm(30, 45, 13, 8, 8, 2026);   # 2026-09-08T13:45:30Z
    is Punk::SAML::_time_parse('2026-09-08T13:45:30Z'), $t, 'parses a Z time';
    is Punk::SAML::_time_format($t), '2026-09-08T13:45:30Z', 'and formats it back';

    is Punk::SAML::_time_parse('2026-09-08T13:45:30.123456Z'), $t,
        'the fraction is parsed and discarded';
    is Punk::SAML::_time_parse('2026-09-08T14:45:30+01:00'), $t,
        'a positive offset is applied';
    is Punk::SAML::_time_parse('2026-09-08T12:45:30-01:00'), $t,
        'and a negative one';

    # the branches a random corpus never selects
    is Punk::SAML::_time_parse('2024-02-29T00:00:00Z'),
       Time::Local::timegm(0, 0, 0, 29, 1, 2024), 'a leap day';
    is Punk::SAML::_time_parse('2026-01-01T00:00:00Z'),
       Time::Local::timegm(0, 0, 0, 1, 0, 2026), 'a year boundary';
    is Punk::SAML::_time_parse('2026-12-31T23:59:59Z'),
       Time::Local::timegm(59, 59, 23, 31, 11, 2026), 'the other end of one';
    is Punk::SAML::_time_parse('1970-01-01T00:00:00Z'), 0, 'the epoch itself';
    ok defined Punk::SAML::_time_parse('1969-12-31T23:59:59Z'),
        'and before it';
    is Punk::SAML::_time_parse('1969-12-31T23:59:59Z'), -1, 'which is negative';
}

for my $bad (
    ['no timezone',      '2026-09-08T13:45:30'],
    ['a date only',      '2026-09-08'],
    ['24:00',            '2026-09-08T24:00:00Z'],
    ['a leap second',    '2026-09-08T23:59:60Z'],
    ['month 13',         '2026-13-01T00:00:00Z'],
    ['day 32',           '2026-01-32T00:00:00Z'],
    ['Feb 30',           '2026-02-30T00:00:00Z'],
    ['Feb 29 non-leap',  '2026-02-29T00:00:00Z'],
    ['a trailing byte',  '2026-09-08T13:45:30Zx'],
    ['a short year',     '926-09-08T13:45:30Z'],
    ['a dot, no digits', '2026-09-08T13:45:30.Z'],
    ['a bad offset',     '2026-09-08T13:45:30+15:00'],
    ['an offset, no colon', '2026-09-08T13:45:30+0100'],
    ['empty',            ''],
    ['nonsense',         'yesterday'],
) {
    my ($name, $str) = @$bad;
    is Punk::SAML::_time_parse($str), undef, "dateTime refuses $name";
}

done_testing();
