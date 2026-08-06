#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

# Pure-Perl reference escaper.
my %ent = (
    '<' => '&lt;', '>' => '&gt;', '&' => '&amp;',
    '"' => '&quot;', "'" => '&#39;',
);
sub ref_escape {
    my $s = shift;
    $s =~ s/([<>&"'])/$ent{$1}/g;
    return $s;
}

# Exhaustive byte map 0..255 (bytes, no UTF-8 flag).
for my $byte (0 .. 255) {
    my $c = chr $byte;
    my $got = Template::Stencil::_escape($c);
    is($got, ref_escape($c), sprintf 'byte 0x%02x', $byte);
}

# Empty string.
is(Template::Stencil::_escape(''), '', 'empty string');

# Specials at every alignment offset 0..33 relative to the same PV -
# catches SIMD block-edge handling.
{
    my $s = join '', map { $_ % 7 ? chr(97 + $_ % 26) : (qw(< > & " '))[$_ % 5] }
        0 .. 200;
    for my $off (0 .. 33) {
        my $got  = Template::Stencil::_escape_off($s, $off);
        my $want = ref_escape(substr $s, $off);
        is($got, $want, "offset $off") or last;
    }
}

# Long strings crossing every block width, all clean and all dirty.
is(Template::Stencil::_escape('a' x 4096), 'a' x 4096, '4 KB clean');
is(Template::Stencil::_escape('<' x 4096), '&lt;' x 4096, '4 KB all specials');

# 1 MB deterministic mixed input (also exercises the pre-count reserve
# path for inputs > 1024 bytes).
{
    srand 42;
    my @pool = ((map { chr } 32 .. 126), '<', '>', '&', '"', "'");
    my $big  = join '', map { $pool[rand @pool] } 1 .. (1 << 20);
    is(Template::Stencil::_escape($big), ref_escape($big), '1 MB mixed');
}

# UTF-8: multibyte passthrough untouched, flag preserved, specials
# still escaped.
{
    my $u = "h\x{e9}llo \x{263a} <b>\"caf\x{e9}\"</b> & '\x{2603}'";
    my $got = Template::Stencil::_escape($u);
    is($got, ref_escape($u), 'utf8 content escaped correctly');
    ok(utf8::is_utf8($got), 'utf8 flag preserved');
}

# Re-run this whole file with the SIMD paths disabled so both variants
# are always tested (no-op when already forced).
unless ($ENV{STENCIL_FORCE_SWAR}) {
    local $ENV{STENCIL_FORCE_SWAR} = 1;
    my $out = qx{"$^X" @{[ map qq{"-I$_"}, @INC ]} "$0" 2>&1};
    my $ok  = $? == 0 && $out !~ /not ok/;
    ok($ok, 'suite green under forced SWAR')
        or diag $out;
}

done_testing;
