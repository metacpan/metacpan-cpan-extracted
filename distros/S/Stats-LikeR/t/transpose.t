#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # die_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Hash-of-Hashes — return type

ok( ref(transpose({ a => { 'x' => 1 } })) eq 'HASH', 'transpose HoH: returns a hash ref' );

# Hash-of-Hashes — shapes & data

my $hoh = { a => { 'x' => 1, 'y' => 2 }, b => { 'x' => 3, 'y' => 4 } };
is_deeply(
  transpose($hoh),
  { 'x' => { a => 1, b => 3 }, 'y' => { a => 2, b => 4 } },
  'transpose HoH: basic square'
);

is_deeply(
  transpose({ a => { 'x' => 10 }, b => { 'x' => 20 }, c => { 'x' => 30 } }),
  { 'x' => { a => 10, b => 20, c => 30 } },
  'transpose HoH: tall (more rows than cols)'
);

is_deeply(
  transpose({ a => { 'x' => 1, 'y' => 2, z => 3 } }),
  { 'x' => { a => 1 }, 'y' => { a => 2 }, z => { a => 3 } },
  'transpose HoH: wide (more cols than rows)'
);

# sparse: row 'a' has {x,y}, row 'b' has {x,z} — no shared expectation of uniform keys
is_deeply(
  transpose({ a => { 'x' => 1, 'y' => 2 }, b => { 'x' => 3, z => 4 } }),
  { 'x' => { a => 1, b => 3 }, 'y' => { a => 2 }, z => { b => 4 } },
  'transpose HoH: non-uniform (sparse) inner keys'
);

is_deeply(
  transpose({ r1 => { c1 => 'foo', c2 => 'bar' }, r2 => { c1 => 'baz', c2 => 'qux' } }),
  { c1 => { r1 => 'foo', r2 => 'baz' }, c2 => { r1 => 'bar', r2 => 'qux' } },
  'transpose HoH: string values preserved'
);

{
    # undef in a slot should round-trip
    is_deeply(
        transpose({ a => { 'x' => 1, 'y' => undef }, b => { 'x' => undef, 'y' => 4 } }),
        { 'x' => { a => 1, b => undef }, 'y' => { a => undef, b => 4 } },
        'transpose HoH: undef values preserved'
    );
}

is_deeply( transpose({}),                  {},  'transpose HoH: empty outer hash' );
is_deeply( transpose({ a => {}, b => {} }), {}, 'transpose HoH: empty inner hashes collapse to empty output' );

{
    my $hoh = { a => { 'x' => 1, 'y' => 2 }, b => { 'x' => 3, 'y' => 4 } };
    is_deeply( transpose(transpose($hoh)), $hoh, 'transpose HoH: double transpose is identity' );
}

{
    my $input = { a => { 'x' => 1 }, b => { 'x' => 2 } };
    my $snap  = { a => { 'x' => 1 }, b => { 'x' => 2 } };
    transpose($input);
    is_deeply( $input, $snap, 'transpose HoH: input not mutated' );
}

# Hash-of-Hashes — errors

dies_ok { transpose(42)              } 'transpose: scalar input dies';
dies_ok { transpose(\"foo")          } 'transpose: scalar ref input dies';
dies_ok { transpose({ a => 1 })      } 'transpose HoH: inner scalar dies';
dies_ok { transpose({ a => [1, 2] }) } 'transpose HoH: inner array ref dies';

# Array-of-Arrays — return type

ok( ref(transpose([[1,2],[3,4]])) eq 'ARRAY', 'transpose AoA: returns an array ref' );

# Array-of-Arrays — shapes & data

is_deeply( transpose([[1,2,3],[4,5,6]]),           [[1,4],[2,5],[3,6]],         'transpose AoA: 2x3' );
is_deeply( transpose([[1,2],[3,4],[5,6]]),         [[1,3,5],[2,4,6]],           'transpose AoA: 3x2' );
is_deeply( transpose([[1,2,3],[4,5,6],[7,8,9]]),   [[1,4,7],[2,5,8],[3,6,9]],   'transpose AoA: 3x3 square' );
is_deeply( transpose([[1,2,3]]),                   [[1],[2],[3]],               'transpose AoA: single row' );
is_deeply( transpose([[1],[2],[3]]),               [[1,2,3]],                   'transpose AoA: single column' );
is_deeply( transpose([[42]]),                      [[42]],                      'transpose AoA: 1x1' );
is_deeply( transpose([]),                          [],                          'transpose AoA: empty outer array' );
is_deeply( transpose([[],[]]),                     [],                          'transpose AoA: empty inner arrays' );

{
    is_deeply(
        transpose([['foo','bar'],['baz','qux']]),
        [['foo','baz'],['bar','qux']],
        'transpose AoA: string values preserved'
    );
}

{
    # undef in a slot should round-trip, not be fabricated as 0 or ''
    is_deeply(
        transpose([[1, undef],[2, 3]]),
        [[1, 2],[undef, 3]],
        'transpose AoA: undef values preserved'
    );
}

{
    # Physical array holes (uninitialized slots, where av_fetch returns NULL)
    my @row1; $row1[2] = 3; # [undef, undef, 3]
    my @row2; $row2[2] = 6; # [undef, undef, 6]
    is_deeply( 
        transpose([\@row1, \@row2]), 
        [[undef, undef], [undef, undef], [3, 6]], 
        'transpose AoA: inner array physical holes coalesce to undef' 
    );
}

{
    my $aoa = [[1,2,3],[4,5,6]];
    is_deeply( transpose(transpose($aoa)), $aoa, 'transpose AoA: double transpose is identity' );
}

{
    my $input = [[1,2],[3,4]];
    my $snap  = [[1,2],[3,4]];
    transpose($input);
    is_deeply( $input, $snap, 'transpose AoA: input not mutated' );
}

# Shallow Copy / Aliasing validation

{
    my $deep_ref = { val => 1 };
    my $input    = [[ $deep_ref ]];
    my $output   = transpose($input);
    
    # Modifying the deep reference in the transposed structure...
    $output->[0][0]{val} = 42;
    
    # ...should affect the original, because transpose does a shallow copy of values.
    is( $input->[0][0]{val}, 42, 'transpose: performs a shallow copy of nested reference values' );
}

# Perl Magic & Objects

{
    # Triggering Perl 'magic' on scalar extraction
    my $str1 = "abc"; my $str2 = "def";
    my $str3 = "ghi"; my $str4 = "jkl";
    
    my $aoa = [
        [ substr($str1, 1, 1), substr($str2, 1, 1) ],
        [ substr($str3, 1, 1), substr($str4, 1, 1) ]
    ];
    
    # If SvGETMAGIC is missing, this might fetch garbage SVs instead of 'b', 'e', etc.
    is_deeply( 
        transpose($aoa), 
        [['b','h'], ['e','k']], 
        'transpose AoA: properly evaluates magical scalars' 
    );
}

# Array-of-Arrays — errors

dies_ok { transpose([1, 2, 3])            } 'transpose AoA: inner scalars die';
dies_ok { transpose([{a => 1},{b => 2}])  } 'transpose AoA: inner hash refs die';
dies_ok { transpose([[1,2],[3]])          } 'transpose AoA: ragged array (short row) dies';
dies_ok { transpose([[1],[2,3]])          } 'transpose AoA: ragged array (long row) dies';

{
    my @bad_arr;
    $bad_arr[1] = [1, 2]; # Hole at index 0
    dies_ok { transpose(\@bad_arr) } 'transpose AoA: missing outer row (physical hole) dies';
}

# Tied input, and the second read that used to be taken on trust

# A tied array's elements do not exist until FETCH has run, so every read of
# one is a fresh call that may hand back something different.  Up to 0.317 the
# AoA branch walked the input twice -- once to validate every row, once per
# output column to copy it -- and the copying pass dereferenced what the second
# read returned without re-testing it:
#
#   if (elem && *elem) { SvGETMAGIC(*elem); }
#   AV *in_row_av = (AV *)SvRV(*elem);        // *elem NULL or not a ref here
#
# so a FETCH that stopped returning an array ref took SvRV() to the PV's string
# buffer and the interpreter down with it -- SIGSEGV, which eval does not catch.
# The single pass validates and copies the same read.

{
	package TransposeTiedAoA;      # a well-behaved tied array over an arrayref
	sub TIEARRAY  { my ($class, $data) = @_; return bless { d => $data }, $class }
	sub FETCHSIZE { return scalar @{ $_[0]{d} } }
	sub FETCH     { return $_[0]{d}[ $_[1] ] }

	package TransposeTiedOnce;     # rows 0 and 1 only survive the first read
	sub TIEARRAY  { my $n = 0; return bless \$n, $_[0] }
	sub FETCHSIZE { return 2 }
	sub FETCH     { my $s = shift; ${$s}++; return ${$s} <= 2 ? [1, 2] : 'not a ref' }

	package TransposeTiedHoH;      # a tied hash: its keys iterate as SVs, not HEKs
	sub TIEHASH   { my ($class, $data) = @_;
	                return bless { d => $data, k => [ sort keys %$data ] }, $class }
	sub FETCH     { return $_[0]{d}{ $_[1] } }
	sub FIRSTKEY  { $_[0]{i} = 0; return $_[0]{k}[0] }
	sub NEXTKEY   { return $_[0]{k}[ ++$_[0]{i} ] }
	sub EXISTS    { return exists $_[0]{d}{ $_[1] } }
}

{
	tie my @outer, 'TransposeTiedAoA', [ [1,2,3], [4,5,6] ];
	is_deeply( transpose(\@outer), [[1,4],[2,5],[3,6]],
		'transpose AoA: tied outer array' );

	tie my @row, 'TransposeTiedAoA', [ 7, 8, 9 ];
	is_deeply( transpose([ \@row, [1,2,3] ]), [[7,1],[8,2],[9,3]],
		'transpose AoA: tied inner row' );

	tie my @flaky, 'TransposeTiedOnce';
	dies_ok { transpose(\@flaky) }
		'transpose AoA: tied row that stops being an array ref dies, not SIGSEGV';
}

{
	tie my %hoh, 'TransposeTiedHoH', { a => { x => 1, y => 2 }, b => { x => 3, y => 4 } };
	is_deeply(
		transpose(\%hoh),
		{ x => { a => 1, b => 3 }, y => { a => 2, b => 4 } },
		'transpose HoH: tied outer hash (keys iterate as SVs)'
	);
}

# utf8 keys, as both row and column labels

# The hash branch reads each key straight out of its HEK -- bytes, utf8 flag
# and hash -- and hands all three to hv_store() rather than building a key SV.
# A utf8 key that perl can hold as bytes is downgraded on the way in, which
# changes the hash perl needs, so this is the case that says the handover is
# right.
{
	my $wide  = "\x{263A}";        # 3 utf8 bytes, no byte form
	my $latin = "\x{e9}";          # utf8 on the way in, downgradeable to one byte
	is_deeply(
		transpose({ $wide => { $latin => 1, z => 2 }, b => { $latin => 3, z => 4 } }),
		{ $latin => { $wide => 1, b => 3 }, z => { $wide => 2, b => 4 } },
		'transpose HoH: utf8 row and column keys'
	);
	my $hoh = { $wide => { $latin => 1 }, $latin => { $wide => 2 } };
	is_deeply( transpose(transpose($hoh)), $hoh,
		'transpose HoH: utf8 keys survive a double transpose' );
}

# A croak part-way through a wide frame

# The output columns are allocated at their final length and filled straight
# into AvARRAY, so a row that turns out to be ragged throws with most of the
# result already written.  Nothing written before the croak may leak, and
# nothing unwritten may be read as a live SV.
{
	my @rows = map { [ (1) x 20 ] } 1 .. 50;
	push @rows, [ (1) x 19 ];                       # the 51st row is one short
	dies_ok { transpose(\@rows) } 'transpose AoA: ragged row 50 of a 20-wide frame dies';
}

# Memory leaks

no_leaks_ok {
	eval { transpose({ a => { 'x' => 1, 'y' => 2 }, b => { 'x' => 3, 'y' => 4 } }) }
} 'transpose HoH: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { transpose({ a => { 'x' => 1, 'y' => 2 }, b => { 'x' => 3, z => 4 } }) }
} 'transpose HoH: no leaks with sparse inner keys' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { transpose([[1,2,3],[4,5,6],[7,8,9]]) }
} 'transpose AoA: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
    # Testing leaks with explicitly scoped assignment to catch RETVAL mortal leaks
    my $result;
	eval { $result = transpose([[1,2],[3,4]]); };
} 'transpose AoA: no memory leaks on scoped assignment (RETVAL check)' unless $INC{'Devel/Cover.pm'};

# On the croak paths, clear $@ inside the traced block: the exception object
# (a plain string, or a stack-trace object if a $SIG{__DIE__} handler such as
# Carp/Devel::Confess is installed) otherwise survives in $@ and is counted as
# a leak by Test::LeakTrace on some older perls.  Releasing it here keeps the
# check version-independent while still catching a real leak in transpose().
no_leaks_ok {
	eval { transpose(42) }; $@ = '';
} 'transpose: no leaks on invalid input' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { transpose({ a => 42 }) }; $@ = '';
} 'transpose HoH: no leaks on invalid inner value' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { transpose([[1,2],[3]]) }; $@ = '';
} 'transpose AoA: no leaks on ragged array' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my @rows = map { [ (1) x 8 ] } 1 .. 20;
	push @rows, [ (1) x 7 ];
	eval { transpose(\@rows) }; $@ = '';
} 'transpose AoA: no leaks when a wide frame croaks part-filled' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { transpose({ "\x{263A}" => { "\x{e9}" => 1, z => 2 },
	                   b          => { "\x{e9}" => 3, z => 4 } }) };
} 'transpose HoH: no leaks with utf8 keys' unless $INC{'Devel/Cover.pm'};

done_testing();
