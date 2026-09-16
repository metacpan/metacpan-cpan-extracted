#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Struct::Codec ();

# The C ABI: the table has a stable address, the selftest drives a structure
# through every entry in C and produces the same bytes the Perl surface does
# for the same data, and the provider config points a consumer at the
# installed header.

my $p = Struct::Codec::_abi_ptr();
ok($p, '_abi_ptr returns a non-zero address');
is($p, Struct::Codec::_abi_ptr(), 'and the same one every call');
like($p, qr/^\d+$/, 'and an unsigned integer: where the loader maps the object decides the sign bit');

# ---- the selftest ---------------------------------------------------------
my ($step, $bytes, $data) = Struct::Codec::_abi_selftest();
is($step, 0, 'every entry in the table answered as its declaration says')
    or diag("check number $step in sc_abi_selftest failed; the numbers are "
          . "the SC_STEP comments in include/sc/sc_abi_impl.h");
ok(defined $bytes && length $bytes, 'and it encoded on the way through');
ok(!utf8::is_utf8($bytes), 'which is bytes');

# The second opinion: the Perl surface does not go through the table, so it
# cannot be wrong in the same direction as a table that is self-consistently
# wrong.
is($bytes, Struct::Codec::struct_encode($data),
   'the bytes the C side produced equal the Perl surface\'s for the same structure');
is_deeply(Struct::Codec::struct_decode($bytes), $data, 'and decode back to it');

# And the structure really is the one the checks describe.
is(ref $data, 'HASH', 'the selftest built a hash');
is($data->{s}, 'hello', 'with the string the checks look for');
is($data->{a}, $data->{a2}, 'and the shared referent they assert');
is(ref $data->{obj}, 'Struct::Codec::SelfTest', 'and the object');
ok($data->{w} == 1/3, 'and the float no double holds, which the table carried intact');

# ---- the two ends of the version -----------------------------------------
# Unchanged by the 0.02 float fix: that added a tag to the format, and the
# table's entries and their signatures are what this number describes.
is(Struct::Codec::_abi_version(), 1, 'the table is at version 1');

{
    require Struct::Codec::Install::Files;
    no warnings 'once';
    my $core = $Struct::Codec::Install::Files::CORE;
    ok(defined $core && -d $core, 'Install::Files records where the header went')
        or diag 'CORE: ' . ($core // 'undef');

    my $h = defined $core ? "$core/sc_abi.h" : undef;
    ok(defined $h && -f $h, 'and sc_abi.h is there for a consumer to include');

    my $header;
    if (defined $h && open my $fh, '<', $h) {
        while (<$fh>) { $header = $1, last if /^\#define\s+SC_ABI_VERSION\s+(\d+)/ }
        close $fh;
    }
    is($header, Struct::Codec::_abi_version(),
       'the installed header and the compiled table name the same ABI version');

    # ---- what a consumer is promised ---------------------------------------
    SKIP: {
        skip 'no installed header to read', 2 unless defined $h && -f $h;
        open my $fh, '<', $h or skip "cannot read the header: $!", 2;
        my (@members, $in);
        while (<$fh>) {
            $in = 1 if /^typedef struct sc_abi \{/;
            next unless $in;
            last if /^\} sc_abi;/;
            push @members, $1 if /\(\s*\*(\w+)\s*\)\s*\(/;
        }
        close $fh;
        is_deeply(\@members, [qw(encode encode_to decode)],
                  'the entries are in the order version 1 publishes them');

        my %trap = map { $_ => 1 } qw(
            open close read write stat link unlink send recv socket select
            time exit abort malloc calloc realloc free getpid kill access
            chmod dup lseek rename mkdir chdir rmdir opendir readdir
        );
        is_deeply([grep { $trap{$_} } @members], [],
                  'and none of them is a name XSUB.h turns into a macro');
    }
}

done_testing;
