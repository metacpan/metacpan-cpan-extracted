#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Struct::Codec qw(struct_encode struct_decode);

# Nothing leaks, on the success path or the croak path. Resident size before
# and after, with the unit measured rather than assumed: `ps` reports KiB on
# Linux and macOS, but a test that trusted that would scale its threshold by
# 1024 on a platform that reports bytes and still say PASS.

plan skip_all => 'needs ps' if $^O eq 'MSWin32';

# A container image may have no ps at all, and a backtick to a missing
# program warns before it fails.
my ($PS) = grep { -x $_ } qw(/bin/ps /usr/bin/ps);

sub rss {
    return undef unless $PS;
    my $out = `$PS -o rss= -p $$ 2>/dev/null`;
    return undef unless defined $out && $out =~ /(\d+)/;
    return $1;
}

my $base = rss();
plan skip_all => 'cannot read the resident size here' unless defined $base;

# Measure the unit: allocate and touch 64 MiB and see how far the number moves.
my $unit;
{
    my $block = 'x' x (64 * 1024 * 1024);
    substr($block, $_ * 4096, 1) = 'y' for 0 .. (64 * 256) - 1;
    my $now = rss();
    my $moved = $now - $base;
    $unit = $moved > 32 * 1024 * 1024 ? 1 : $moved > 32 * 1024 ? 1024 : 0;
    undef $block;
}
plan skip_all => 'resident size did not move for a 64 MiB block; cannot measure' unless $unit;
diag("rss unit: $unit bytes");

my $s = [1, 2];
my $big = { map { ("key$_" => { id => $_, name => "item $_", tags => [qw(a b c)], score => $_ * 1.5, s => $s }) } 1 .. 50 };
my $obj = bless { a => [1, 2, 3], u => "caf\x{e9}" }, 'Leak::Obj';
require Tie::Hash;
tie my %th, 'Tie::StdHash'; $th{k} = 'v';
sub leak_named { 1 }
# a regexp is compiled on every decode, a tie is magic on a fresh container,
# a sub by name is a lookup: each is its own allocation path. The codec
# refuses a regexp below 5.12 (t/32 skips it there for the same reason), so
# it joins $odd only where it can be encoded at all.
my $odd = [ ($] >= 5.012 ? (qr/a.b/i) : ()), \%th, \&leak_named, \*STDOUT ];
my $bytes = struct_encode($big);
my $trunc = substr($bytes, 0, length($bytes) - 7);
my $dup   = 'S1' . chr(8) . "\x28\x2A\x02\x02a\x01\x02a\x02";
my $src   = struct_encode(sub { 42 });                 # refused below, with $Struct::Codec::Eval off
my $badre = 'S1' . chr(8) . "\x28\x2E\x02(\x00";        # a pattern that does not compile
my $lexical = 1;

sub settle { struct_decode(struct_encode($big)) for 1 .. 2000 }
settle();
my $before = rss();

struct_decode(struct_encode($big)) for 1 .. 20_000;
struct_decode(struct_encode($obj)) for 1 .. 100_000;
struct_decode(struct_encode($odd)) for 1 .. 50_000;
my $mid = rss();
cmp_ok(($mid - $before) * $unit, '<', 8 * 1024 * 1024,
       sprintf('170,000 round trips grew RSS by %d KiB, under 8 MiB', ($mid - $before) * $unit / 1024));

for (1 .. 50_000) {
    eval { my $x = struct_decode($trunc); 1 };
    eval { my $x = struct_decode($dup); 1 };
    eval { my $x = struct_encode([1, sub { $lexical }]); 1 };
    { local $Struct::Codec::Eval = 0; eval { my $x = struct_decode($src); 1 }; }
    eval { my $x = struct_decode($badre); 1 };
}
my $after = rss();
cmp_ok(($after - $mid) * $unit, '<', 8 * 1024 * 1024,
       sprintf('250,000 croaking calls grew RSS by %d KiB, under 8 MiB', ($after - $mid) * $unit / 1024));

done_testing;
