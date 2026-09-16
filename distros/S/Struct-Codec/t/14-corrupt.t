#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Struct::Codec qw(struct_encode struct_decode);

# INPUT THAT LIES.
#
# Every rule in the decoder exists to turn a corrupt stream into a croak rather
# than a crash, and each one here is exercised with bytes that would have hit
# the crash. The random and bit-flip loops run in forked children: the test is
# that the process is still alive afterwards, and only an exit status can say
# that about a crash.

my $HDR = "S1\x08";
sub dies_with { my ($bytes, $re, $name) = @_; my $err = '';
                eval { my $x = struct_decode($bytes); 1 } or $err = $@;
                like($err, $re, $name) }

# ---- the header -----------------------------------------------------------
dies_with('',        qr/truncated/,          'an empty string is truncated');
dies_with('S1',      qr/truncated/,          'and so is a short header');
dies_with("X1\x08\x05", qr/not a Struct::Codec stream/, q{a wrong magic});
dies_with("S2\x08\x05", qr/unknown format version/, q{a wrong version});
dies_with("S1\x10\x05", qr/unknown float encoding/, q{a float encoding this build does not know});
dies_with($HDR . "\x22\x00\x00\x00\x00\x00\x00\xF8", qr/truncated/, q{a float short of its eight bytes});
dies_with($HDR,      qr/truncated/,          'a header with no value');

# ---- every truncation of every fixture dies -------------------------------
{
    my $s = [1, 'two'];
    require Tie::Hash;
    tie my %th, 'Tie::StdHash'; $th{a} = 1;
    sub trunc_named { 1 }
    # no regexp SVs before 5.12, and the codec refuses one there
    my @fixtures = (5, -300, 1.5, 'x' x 40, "caf\x{e9}", [1, [2, [3]]],
                    { a => { b => 'c' } }, bless({ k => 1 }, 'Trunc'), [$s, $s], \\5,
                    ($] >= 5.012 ? (qr/a.b/i) : ()), \%th, \&trunc_named, \*STDOUT, [*STDERR]);
    my $tried = 0;
    my $survived = 0;
    for my $f (@fixtures) {
        my $b = struct_encode($f);
        for my $len (0 .. length($b) - 1) {
            $tried++;
            my $ok = eval { my $x = struct_decode(substr($b, 0, $len)); 1 };
            $survived++ if $ok;
        }
    }
    is($survived, 0, "every one of $tried truncations died");
}

# ---- trailing bytes ---------------------------------------------------------
dies_with(struct_encode(5) . 'x', qr/trailing bytes/, 'a byte after the value');
dies_with(struct_encode([1]) . "\x00", qr/trailing bytes/, 'even a zero');

# ---- integers ------------------------------------------------------------------
dies_with($HDR . "\x20" . ("\x80" x 10) . "\x01", qr/integer too long/, q{an eleven-byte varint});
dies_with($HDR . "\x20" . ("\xFF" x 9) . "\x7F", qr/integer too wide/, 'bits past the 64th')
    if $Config{uvsize} == 8;
dies_with($HDR . "\x21" . ("\xFF" x 9) . "\x01", qr/negative integer too wide/, 'a negative past IV_MIN')
    if $Config{uvsize} == 8;

# ---- strings --------------------------------------------------------------------
dies_with($HDR . "\x61\xFF",        qr/malformed UTF-8/, 'a utf8 string that is not UTF-8');
dies_with($HDR . "\x27\x02\xC3\x28", qr/malformed UTF-8/, 'a long one too');
dies_with($HDR . "\x28\x2A\x01\x03\xFF\x01", qr/malformed UTF-8/, 'and a utf8 key');
dies_with($HDR . "\x26\xFF\xFF\x7F", qr/truncated/, 'a length longer than the input');

# ---- tags -----------------------------------------------------------------------------
dies_with($HDR . "\x39",     qr/unknown tag/, 'a reserved tag');
dies_with($HDR . "\x3F",     qr/unknown tag/, 'and the last reserved one');

# ---- a wide float's decimal digits ------------------------------------------------
# 0x38 carries a varint length and that many bytes of decimal. The decoder copies
# them to a fixed stack buffer to get the NUL that Atof needs, so a length past
# that buffer has to be refused before the copy and not clamped to fit it.
dies_with($HDR . "\x38\x40" . ('9' x 0x40), qr/float too long/, 'a float decimal past the buffer');
dies_with($HDR . "\x38\xFF\x7F", qr/float too long/, 'and an absurd length');
dies_with($HDR . "\x38\x08" . '1.5', qr/truncated/, 'a float decimal shorter than its length');
dies_with($HDR . "\x38", qr/truncated/, 'and one with no length at all');
dies_with($HDR . "\x2B\x00", qr/container without a reference/, 'a bare ARRAY');
dies_with($HDR . "\x2A\x00", qr/container without a reference/, 'a bare HASH');
dies_with($HDR . "\x31\x05", qr/container without a reference/, 'a bare TIED_HASH');
dies_with($HDR . "\x28\xAB\x00", qr/tracked container tag/, 'TRACK on a container tag');
dies_with($HDR . "\x28\xB1\x05", qr/tracked container tag/, 'and on a tied one');
dies_with($HDR . "\x29\x00\x2A\x00", qr/empty class name/, 'an object with no class');

# ---- the kinds that are not data: every payload that lies -------------------------------
sub varint { my ($v) = @_; my $b = ''; while ($v >= 0x80) { $b .= chr(($v & 0x7F) | 0x80); $v >>= 7 } $b . chr($v) }
sub key { my ($s) = @_; varint(2 * length($s)) . $s }
dies_with($HDR . "\x2E" . key('x') . key(''), qr/referent without a reference/, 'a bare REGEXP');
dies_with($HDR . "\x28\xAE" . key('x') . key(''), qr/tracked referent tag/, 'TRACK on a REGEXP');
SKIP: {
    # Below 5.12 every one of these is refused earlier, as "a regexp needs perl
    # 5.12 or later", before the payload is looked at.
    skip 'no regexp SVs before 5.12', 6 if $] < 5.012;
    dies_with($HDR . "\x28\x2E" . key('x') . key('q'), qr/unknown regexp flag at byte/, 'a flag letter outside the alphabet');
    dies_with($HDR . "\x28\x2E" . key('x') . key('z'), qr/unknown regexp flag/, 'is corrupt input, whatever it is');
    dies_with($HDR . "\x28\x2E" . key('(') . key(''), qr/^Struct::Codec: Unmatched \(.* at byte \d+/,
              'a pattern that does not compile croaks with the engine\'s reason and the byte');
    dies_with($HDR . "\x28\x2E" . key('(?{ die "ran" })') . key(''), qr/Eval-group not allowed at runtime/,
              'a code block in a pattern is refused by the engine, and never runs');
    dies_with($HDR . "\x28\x2E" . key('x'), qr/truncated/, 'a regexp missing its flags is truncated');
    dies_with($HDR . "\x28\x2E\xFF\xFF\x7F", qr/truncated/, 'a pattern length past the end is truncated');
}

dies_with($HDR . "\x28\x31\x05", qr/tie object is not a reference/, 'a tie object that is a plain number');
dies_with($HDR . "\x28\x2F\x23", qr/tie object is not a reference/, 'or undef');
dies_with($HDR . "\x28\x30\x28\x2B\x02\x01", qr/truncated/, 'a tie object cut short');

dies_with($HDR . "\x28\x32" . key(''), qr/empty sub name/, 'a sub with no name');
dies_with($HDR . "\x28\x32" . key('main::no_such_sub_here'), qr/sub main::no_such_sub_here is not defined at byte/,
          'a sub that does not exist is refused and not created');
ok(!defined &main::no_such_sub_here, 'and still does not exist');
{
    local $Struct::Codec::Eval = 0;
    dies_with($HDR . "\x28\x33" . key(q[{ 1 }]), qr/a sub by source needs \$Struct::Codec::Eval at byte/,
              q{with $Struct::Codec::Eval false a sub by source is refused});
}
{
    no warnings 'once';
    local $Struct::Codec::Eval = 1;
    # Before 5.14 the compiler's reason is lost between eval_sv returning and
    # $@ being read: perl's own `eval "sub { !!!!! }"` sets $@ to "syntax
    # error at (eval 1) line 1, at EOF" on 5.10 and 5.12 exactly as on 5.14,
    # and 5.14 is the first that passes it through this path; before it the
    # decoder finds $@ empty and can only say the source produced no sub.
    # Observed in the docker matrix, 12 September 2026, with no old perl to
    # hand to trace it: the same stream through struct_decode gave
    #   5.10, 5.12: Struct::Codec: the source did not produce a sub at byte 15
    #   5.14:       Struct::Codec: syntax error at (eval 5) line 1, at EOF
    my $reason = ($] < 5.014)
        ? qr/^Struct::Codec: (?:syntax error|the source did not produce a sub)/
        : qr/^Struct::Codec: syntax error/;
    dies_with($HDR . "\x28\x33" . key('{ !!!!! }'), $reason,
              'and with it, source that does not compile croaks with the compiler\'s reason');
}
dies_with($HDR . "\x28\x37" . key('main::no_such_format'), qr/format main::no_such_format is not defined/,
          'a format that does not exist');
dies_with($HDR . "\x28\x34" . key(''), qr/empty glob name/, 'a glob with no name');
dies_with($HDR . "\x28\x35Z\x01", qr/unknown filehandle mode/, 'a filehandle mode outside the alphabet');
dies_with($HDR . "\x28\x35<\xFF\x01", qr/cannot reopen descriptor 255: .* at byte/,
          'a descriptor nothing is open on');
dies_with($HDR . "\x28\x35<" . ("\xFF" x 9) . "\x01", qr/descriptor too large/, 'a descriptor wider than an int');
dies_with($HDR . "\x28\x35<", qr/truncated/, 'a filehandle missing its descriptor');
dies_with($HDR . "\x36<\x01", qr/referent without a reference/, 'a bare FD_IO');

# rule 8, widened: an ALIAS may only place a scalar. A REFP to the same regexp
# is a second reference and fine.
SKIP: {
    skip 'no regexp SVs before 5.12', 2 if $] < 5.012;
    dies_with($HDR . "\x28\x2B\x02\xA8\x2E" . key('x') . key('') . "\x2D\x06", qr/alias of a container/,
              'an ALIAS to a regexp is refused rather than placed');
    ok(eval { struct_decode($HDR . "\x28\x2B\x02\xA8\x2E" . key('x') . key('') . "\x2C\x06"); 1 },
       'while a REFP to it is a second reference');
}
dies_with($HDR . "\x28\x2B\x02\xA8\x34" . key('main::STDOUT') . "\x2D\x06", qr/alias of a container/,
          'and an ALIAS to a glob referent likewise');

# ---- references that name nothing, or the wrong thing ----------------------------------
dies_with($HDR . "\x2C\x03",                 qr/not tracked/, 'a REFP at the root names nothing');
dies_with($HDR . "\x28\x2B\x02\x01\x2C\x04", qr/not tracked/, 'a REFP to a value that was not tracked');
dies_with($HDR . "\x28\x2B\x02\x01\x2C\x40", qr/not tracked/, 'a REFP to an offset past the end');
dies_with($HDR . "\x28\x2B\x02\x01\x2D\x04", qr/not tracked/, 'and an ALIAS likewise');
dies_with($HDR . "\x2D\x03",                 qr/not tracked/, 'an ALIAS at the root');
dies_with($HDR . "\x28\x2B\x02\x81\xAC\x06", qr/tracked reference tag/, 'TRACK on a REFP');
dies_with($HDR . "\x28\x2B\x02\x81\xAD\x06", qr/tracked alias tag/, 'TRACK on an ALIAS');

# rule 8: an ALIAS to a tracked REF whose referent is a container would put an
# AV where an SV belongs. The bytes: an array of two, the first a TRACKed REF
# to an array, the second an ALIAS to it.
dies_with($HDR . "\x28\x2B\x02\xA8\x2B\x00\x2D\x06", qr/alias of a container/,
          'an ALIAS to an array is refused rather than placed');
dies_with($HDR . "\x28\x2B\x02\xA8\x2A\x00\x2D\x06", qr/alias of a container/,
          'and an ALIAS to a hash');
# ...while a REFP to the same tag is fine, and an ALIAS to a scalar referent is fine
ok(eval { struct_decode($HDR . "\x28\x2B\x02\xA8\x2B\x00\x2C\x06"); 1 }, 'a REFP to it is a new reference');
ok(eval { struct_decode($HDR . "\x28\x2B\x02\xA8\x05\x2D\x06"); 1 }, 'an ALIAS to a scalar referent is the scalar');

# rule 6: a duplicate key is refused before anything is freed. The value under
# the first copy is TRACKed and named again after the duplicate.
dies_with($HDR . "\x28\x2A\x02\x02a\xA8\x2B\x00\x02a\x2C\x07", qr/duplicate hash key/,
          'a duplicate key is refused');
dies_with($HDR . "\x28\x2A\x02\x02a\x01\x02a\x02", qr/duplicate hash key/, 'even without tracking');

# ---- depth ---------------------------------------------------------------------------------
dies_with($HDR . ("\x28\x2B\x01" x 5000) . "\x05", qr/structure too deep/, 'nesting past the limit');
ok(eval { struct_decode($HDR . ("\x28\x2B\x01" x 2000) . "\x05"); 1 }, 'while 2000 deep is fine');

# ---- a croak leaves the interpreter usable, with nothing half-built -----------------------
{
    my $d = { a => [1, 2, { b => 'c' }], d => bless({}, 'Fine') };
    is_deeply(struct_decode(struct_encode($d)), $d, 'a good value decodes after all of that');
}

# ---- bit flips and random bytes, in children ------------------------------------------------
#
# A crash here would take the test file with it, which the harness reports as a
# missing plan rather than the failure it is. So each batch runs in a child and
# the parent asserts the exit status. Skipped where fork is emulated with
# threads, where a child's exit ends the file.
SKIP: {
    skip 'fork is POSIX-only here', 4 if $^O eq 'MSWin32';
    require POSIX;

    my $s = [1, 'two'];
    tie my %fh, 'Tie::StdHash'; $fh{k} = 'v';
    my @fixtures = map { struct_encode($_) }
        ({ a => [1, 2.5, 'three', undef], b => { c => [$s, $s] }, o => bless({ k => 'v' }, 'Flip') },
         'x' x 100, [ map { $_ } 1 .. 50 ], "caf\x{e9}",
         [ ($] >= 5.012 ? (qr/a.b/msix) : ()), \%fh, \&trunc_named, \*STDOUT ]);

    my $run = sub {
        my ($code) = @_;
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) { my $rc = eval { $code->() }; POSIX::_exit($@ ? 99 : $rc) }
        waitpid $pid, 0;
        return $?;
    };

    my $flips = $run->(sub {
        my $died = 0;
        for my $b (@fixtures) {
            for my $i (3 .. length($b) - 1) {
                for my $bit (0 .. 7) {
                    my $c = $b;
                    substr($c, $i, 1) = chr(ord(substr($c, $i, 1)) ^ (1 << $bit));
                    eval { my $x = struct_decode($c); 1 } or $died++;
                }
            }
        }
        return 0;
    });
    is($flips, 0, 'every single-bit flip of every fixture either decoded or croaked, and none crashed');

    my $random = $run->(sub {
        srand(42);
        for (1 .. 20_000) {
            my $len = 1 + int rand 64;
            my $c = $HDR . join '', map { chr int rand 256 } 1 .. $len;
            eval { my $x = struct_decode($c); 1 };
        }
        return 0;
    });
    is($random, 0, '20,000 random streams with a valid header never crashed');

    my $structured = $run->(sub {
        # Random streams built from valid tags, which reach the reference
        # paths far more often than random bytes do.
        srand(7);
        my @tags = ("\x28", "\x2B", "\x2A", "\x2C", "\x2D", "\xA8", "\x81", "\x00", "\x01", "\x02", "\x05", "\x43abc", "\x29\x06Foo",
                    "\x2E\x02x\x00", "\x2F", "\x30", "\x31", "\x32\x10main::x", "\x33\x0A{ 1 }", "\x34\x18main::STDOUT",
                    "\x35<\x01", "\x36<\x01", "\x37\x10main::x");
        for (1 .. 20_000) {
            my $c = $HDR . join '', map { $tags[int rand @tags] } 1 .. (1 + int rand 12);
            eval { my $x = struct_decode($c); 1 };
        }
        return 0;
    });
    is($structured, 0, '20,000 random tag sequences never crashed');

    my $after = $run->(sub {
        my $d = { fine => [1, 2, 3] };
        my $x = struct_decode(struct_encode($d));
        return $x->{fine}[2] == 3 ? 0 : 1;
    });
    is($after, 0, 'and a child that did all that still round-trips a value');
}

done_testing;
