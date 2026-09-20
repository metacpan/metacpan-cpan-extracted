#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::Scalar;
use Struct::Codec qw(struct_encode struct_decode);

# A POINTER OBJECT: a blessed scalar holding only an integer, in a class whose
# DESTROY is an XSUB. It is how the typemap hands out a handle, the integer is
# an address, and a decoded copy's DESTROY would free it. The encoder refuses
# one, or drops it under strip_pointers => 1; the decoder refuses one before
# the bless, so the DESTROY never runs on the copy.
#
# The XS DESTROY here is Struct::Codec::import, an XSUB that does nothing when
# called with one argument. A DESTROY that freed its integer would take the
# process with it, so the process living through the decode refusals below is
# an assertion too.

my %destroyed;
{
    no warnings 'once';
    package Handle;
    sub new { my ($class, $addr) = @_; my $p = $addr; bless \$p, $class }
    *DESTROY = \&Struct::Codec::import;
    package Handle::Sub;
    our @ISA = ('Handle');
    package Plain;
    sub new { my ($class, $addr) = @_; my $p = $addr; bless \$p, $class }
    package Counted;
    sub new { my ($class, $addr) = @_; my $p = $addr; bless \$p, $class }
    sub DESTROY { $destroyed{Counted}++ }
}

sub rt { struct_decode(struct_encode(@_)) }

# ---- refused on encode, and the message names the class ------------------------
{
    my $h = Handle->new(0x1234);
    my $err = do { local $@; eval { struct_encode($h) }; $@ };
    like($err, qr/^Struct::Codec: cannot encode a Handle object that holds a pointer \(strip_pointers => 1 drops it\)/,
         'a blessed integer in a class with an XS DESTROY is refused');

    $err = do { local $@; eval { struct_encode({ deep => [ 1, { h => $h } ] }) }; $@ };
    like($err, qr/cannot encode a Handle object/, 'refused deep in a structure');

    $err = do { local $@; eval { struct_encode(Handle::Sub->new(1)) }; $@ };
    like($err, qr/cannot encode a Handle::Sub object/, 'an inherited DESTROY counts');

    my $big = 2**40 + 7;
    $err = do { local $@; eval { struct_encode(Handle->new($big)) }; $@ };
    like($err, qr/holds a pointer/, 'a wide integer is still refused');

    # Printing an integer leaves the digits in the same scalar, and before
    # 5.36 perl marks them public POK, so POK alone cannot say "string".
    my $d = do { my $v = 7; my $x = "$v"; bless \$v, 'Handle' };
    $err = do { local $@; eval { struct_encode($d) }; $@ };
    like($err, qr/holds a pointer/, 'an address that has been printed is still an address');

    # The shape that pays for it, on every perl: a decimal string that has
    # been used as a number has the flags and the bytes of a printed integer.
    my $n = do { my $v = "7"; my $sum = $v + 0; bless \$v, 'Handle' };
    $err = do { local $@; eval { struct_encode($n) }; $@ };
    like($err, qr/holds a pointer/, 'a decimal string used as a number is refused with it');

    my $w = do { my $v = " 7"; my $sum = $v + 0; bless \$v, 'Handle' };
    is(${ rt($w) }, " 7", 'a string that spells anything else is data');

    is(struct_decode(struct_encode(5)), 5, 'a refusal leaves the next call unaffected');
}

# ---- what is NOT a pointer object round-trips as before ------------------------
{
    my $p = Plain->new(0x1234);
    my $o = rt($p);
    is(ref $o, 'Plain', 'a blessed integer in a class with no DESTROY comes back');
    is($$o, 0x1234, '  with its integer');

    my $c = Counted->new(0x1234);
    $o = rt($c);
    is(ref $o, 'Counted', 'a blessed integer in a class with a Perl DESTROY comes back');
    is($$o, 0x1234, '  with its integer');
    undef $o;
    is($destroyed{Counted}, 1, '  and its DESTROY ran on the copy, as any DESTROY does');

    tie my $t, 'Tie::StdScalar', 7;
    my $tt = rt(\$t);
    is(ref tied($$tt), 'Tie::StdScalar', 'a scalar tied through Tie::StdScalar is still tied');
    is($$tt, 7, '  and still answers: its tie object is a blessed integer with a Perl DESTROY');

    my $s = do { my $v = "0x1234"; bless \$v, 'Handle' };
    is(${ rt($s) }, "0x1234", 'a blessed string in a class with an XS DESTROY is data');
    my $f = do { my $v = 1.5; bless \$v, 'Handle' };
    is(${ rt($f) }, 1.5, 'a blessed float is data');
    my $r = do { my $v = [1]; bless \$v, 'Handle' };
    is_deeply(${ rt($r) }, [1], 'a blessed reference is data');
    my $u = do { my $v; bless \$v, 'Handle' };
    ok(!defined ${ rt($u) }, 'a blessed undef is data');
    my $hv = bless { fd => 3 }, 'Handle';
    is(rt($hv)->{fd}, 3, 'a blessed hash holding an integer is data');
    my $av = bless [3], 'Handle';
    is(rt($av)->[0], 3, 'a blessed array holding an integer is data');
}

# ---- strip_pointers => 1 writes undef in its place -------------------------------
{
    my $h = Handle->new(0x1234);
    my $in = { a => 1, h => $h, list => [ $h, 2, $h ], nest => { h => $h } };
    my $out = rt($in, strip_pointers => 1);
    is_deeply($out, { a => 1, h => undef, list => [ undef, 2, undef ], nest => { h => undef } },
              'every reference to the pointer object is undef, the rest intact');
    ok(!defined rt($h, strip_pointers => 1), 'a pointer object at the root is undef');

    my $err = do { local $@; eval { struct_encode($in, strip_pointers => 0) }; $@ };
    like($err, qr/holds a pointer/, 'strip_pointers => 0 is the default');

    $err = do { local $@; eval { struct_encode($in, strip_pointers => 0, strip_pointers => 1) }; $@ };
    is($err, '', 'the last value of a repeated option wins');

    my $bytes = struct_encode($in, strip_pointers => 1);
    my $same  = struct_encode({ a => 1, h => undef, list => [ undef, 2, undef ], nest => { h => undef } });
    is(length $bytes, length $same, 'the stripped stream is the size of one written with undef');

    is(Struct::Codec::encode($h, strip_pointers => 1), struct_encode(undef),
       'encode under the short name takes the option too');
}

# ---- the options are checked ------------------------------------------------------
{
    my $err = do { local $@; eval { struct_encode(1, strip_pointers => 1, bogus => 1) }; $@ };
    like($err, qr/^Struct::Codec: unknown option 'bogus'/, 'an unknown option is an error');
    $err = do { local $@; eval { struct_encode(1, 'strip_pointers') }; $@ };
    like($err, qr/^Struct::Codec: options come in pairs/, 'an odd option list is an error');
    is(struct_decode(struct_encode(5)), 5, 'no options is still fine');
}

# ---- refused on decode, before the bless ----------------------------------------
#
# A stream written before the class had its DESTROY is exactly the stream an
# older encoder wrote. Install the XS DESTROY, decode, and the copy is refused
# with the byte it was found at.
{
    my $late = do { my $v = 0xBEEF; bless \$v, 'Late' };
    my $bytes = struct_encode({ k => $late, after => 'still here' });
    my $ok = struct_decode($bytes);
    is(ref $ok->{k}, 'Late', 'without a DESTROY the class decodes');
    undef $ok;

    no strict 'refs';
    *{'Late::DESTROY'} = \&Struct::Codec::import;
    my $err = do { local $@; eval { struct_decode($bytes) }; $@ };
    like($err, qr/^Struct::Codec: a Late object that holds a pointer at byte \d+/,
         'the same stream is refused once the class has an XS DESTROY');
    is(struct_decode(struct_encode('next')), 'next', 'and the decoder is intact after it');
}

# ---- a real one --------------------------------------------------------------------
SKIP: {
    skip 'Compress::Raw::Zlib not available', 3 unless eval { require Compress::Raw::Zlib; 1 };
    my ($z, $st) = Compress::Raw::Zlib::Inflate->new;
    skip 'no inflate stream', 3 unless $z;
    like(ref $z, qr/^Compress::Raw::Zlib::/, 'an inflate stream is a blessed scalar');
    my $err = do { local $@; eval { struct_encode({ gz => $z }) }; $@ };
    like($err, qr/cannot encode a Compress::Raw::Zlib::inflateStream object that holds a pointer/,
         'and is refused by name');
    my $out = rt({ gz => $z, body => 'x' }, strip_pointers => 1);
    is_deeply($out, { gz => undef, body => 'x' }, 'or dropped, leaving the rest');
}

done_testing;
