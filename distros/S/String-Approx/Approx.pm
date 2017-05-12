package String::Approx;

require v5.8.0;

$VERSION = '3.28';

use strict;
local $^W = 1;

use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw(amatch asubstitute aindex aslice arindex
		adist adistr adistword adistrword);

bootstrap String::Approx $VERSION;

my $CACHE_MAX = 1000;	# high water mark
my $CACHE_PURGE = 0.75;	# purge this much of the least used
my $CACHE_N_PURGE;	# purge this many of the least used

sub cache_n_purge () {
    $CACHE_N_PURGE = $CACHE_MAX * $CACHE_PURGE;
    $CACHE_N_PURGE = 1 if $CACHE_N_PURGE < 1;
    return $CACHE_N_PURGE;
}

cache_n_purge();

sub cache_max (;$) {
    if (@_ == 0) {
	return $CACHE_MAX;
    } else {
	$CACHE_MAX = shift;
    }
    $CACHE_MAX = 0 if $CACHE_MAX < 0;
    cache_n_purge();
}

sub cache_purge (;$) {
    if (@_ == 0) {
	return $CACHE_PURGE;
    } else {
	$CACHE_PURGE = shift;
    }
    if ($CACHE_PURGE < 0) {
	$CACHE_PURGE = 0;
    } elsif ($CACHE_PURGE > 1) {
	$CACHE_PURGE = 1;
    }
    cache_n_purge();
}

my %_simple;
my %_simple_usage_count;

sub _cf_simple {
    my $P = shift;

    my @usage =
	sort { $_simple_usage_count{$a} <=> $_simple_usage_count{$b} }
             grep { $_ ne $P }
                  keys %_simple_usage_count;
	    
    # Make room, delete the least used entries.
    $#usage = $CACHE_N_PURGE - 1;
	    
    delete @_simple_usage_count{@usage};
    delete @_simple{@usage};
}

sub _simple {
    my $P = shift;

    my $_simple = new(__PACKAGE__, $P);

    if ($CACHE_MAX) {
	$_simple{$P} = $_simple unless exists $_simple{$P};

	$_simple_usage_count{$P}++;

	if (keys %_simple_usage_count > $CACHE_MAX) {
	    _cf_simple($P);
	}
    }

    return ( $_simple );
}

sub _parse_param {
    use integer;

    my ($n, @param) = @_;
    my %param;

    foreach (@param) {
        while ($_ ne '') {
	    s/^\s+//;
            if (s/^([IDS]\s*)?(\d+)(\s*%)?//) {
                my $k = defined $3 ? (($2-1) * $n) / 100 + ($2 ? 1 : 0) : $2;

		if (defined $1) {
		    $param{$1} = $k;
		} else {
		    $param{k}  = $k;
		}
	    } elsif (s/^initial_position\W+(\d+)\b//) {
		$param{'initial_position'} = $1;
	    } elsif (s/^final_position\W+(\d+)\b//) {
		$param{'final_position'} = $1;
	    } elsif (s/^position_range\W+(\d+)\b//) {
		$param{'position_range'} = $1;
	    } elsif (s/^minimal_distance\b//) {
		$param{'minimal_distance'} = 1;
            } elsif (s/^i//) {
                $param{ i } = 1;
            } elsif (s/^g//) {
                $param{ g } = 1;
            } elsif (s/^\?//) {
                $param{'?'} = 1;
            } else {
                warn "unknown parameter: '$_'\n";
                return;
            }
        }
    }

    return %param;
}

my %_param_key;
my %_parsed_param;

my %_complex;
my %_complex_usage_count;

sub _cf_complex {
    my $P = shift;

    my @usage =
	sort { $_complex_usage_count{$a} <=>
		   $_complex_usage_count{$b} }
             grep { $_ ne $P }
                  keys %_complex_usage_count;
	    
    # Make room, delete the least used entries.
    $#usage = $CACHE_N_PURGE - 1;
	    
    delete @_complex_usage_count{@usage};
    delete @_complex{@usage};
}

sub _complex {
    my ($P, @param) = @_;
    unshift @param, length $P;
    my $param = "@param";
    my $_param_key;
    my %param;
    my $complex;
    my $is_new;

    unless (exists $_param_key{$param}) {
	%param = _parse_param(@param);
	$_parsed_param{$param} = { %param };
	$_param_key{$param} = join(" ", %param);
    } else {
	%param = %{ $_parsed_param{$param} };
    }

    $_param_key = $_param_key{$param};

    if ($CACHE_MAX) {
	if (exists $_complex{$P}->{$_param_key}) {
	    $complex = $_complex{$P}->{$_param_key};
	}
    }

    unless (defined $complex) {
	if (exists $param{'k'}) {
	    $complex = new(__PACKAGE__, $P, $param{k});
	} else {
	    $complex = new(__PACKAGE__, $P);
	}
	$_complex{$P}->{$_param_key} = $complex if $CACHE_MAX;
	$is_new = 1;
    }

    if ($is_new) {
	$complex->set_greedy unless exists $param{'?'};

	$complex->set_insertions($param{'I'})
	    if exists $param{'I'};
	$complex->set_deletions($param{'D'})
	    if exists $param{'D'};
	$complex->set_substitutions($param{'S'})
	    if exists $param{'S'};
	
	$complex->set_caseignore_slice
	    if exists $param{'i'};

	$complex->set_text_initial_position($param{'initial_position'})
	    if exists $param{'initial_position'};

	$complex->set_text_final_position($param{'final_position'})
	    if exists $param{'final_position'};

	$complex->set_text_position_range($param{'position_range'})
	    if exists $param{'position_range'};

	$complex->set_minimal_distance($param{'minimal_distance'})
	    if exists $param{'minimal_distance'};
    }

    if ($CACHE_MAX) {
	$_complex_usage_count{$P}->{$_param_key}++;

	# If our cache overfloweth.
	if (scalar keys %_complex_usage_count > $CACHE_MAX) {
	    _cf_complex($P);
	}
    }

    return ( $complex, %param );
}

sub cache_disable {
    cache_max(0);
}

sub cache_flush_all {
    my $old_purge = cache_purge();
    cache_purge(1);
    _cf_simple('');
    _cf_complex('');
    cache_purge($old_purge);
}

sub amatch {
    my $P = shift;
    return 1 unless length $P; 
    my $a = ((@_ && ref $_[0] eq 'ARRAY') ?
		 _complex($P, @{ shift(@_) }) : _simple($P))[0];

    if (@_) {
        if (wantarray) {
            return grep { $a->match($_) } @_;
        } else {
            foreach (@_) {
                return 1 if $a->match($_);
            }
             return 0;
        }
    } 
    if (defined $_) {
        if (wantarray) {
            return $a->match($_) ? $_ : undef;
        } else {
	    return 1 if $a->match($_);
        }
    } 
    return $a->match($_) if defined $_;

    warn "amatch: \$_ is undefined: what are you matching?\n";
    return;
}

sub _find_substitute {
    my ($ri, $rs, $i, $s, $S, $rn) = @_;

    push @{ $ri }, $i;
    push @{ $rs }, $s;

    my $pre = substr($_, 0, $i);
    my $old = substr($_, $i, $s);
    my $suf = substr($_, $i + $s);
    my $new = $S;

    $new =~ s/\$\`/$pre/g;
    $new =~ s/\$\&/$old/g;
    $new =~ s/\$\'/$suf/g;

    push @{ $rn }, $new;
}

sub _do_substitute {
    my ($rn, $ri, $rs, $rS) = @_;

    my $d = 0;
    my $n = $_;

    foreach my $i (0..$#$rn) {
	substr($n, $ri->[$i] + $d, $rs->[$i]) = $rn->[$i];
	$d += length($rn->[$i]) - $rs->[$i];
    }

    push @{ $rS }, $n;
}

sub asubstitute {
    my $P = shift;
    my $S = shift;
    my ($a, %p) =
	(@_ && ref $_[0] eq 'ARRAY') ?
	    _complex($P, @{ shift(@_) }) : _simple($P);

    my ($i, $s, @i, @s, @n, @S);

    if (@_) {
	if (exists $p{ g }) {
	    foreach (@_) {
		@s = @i = @n = ();
		while (($i, $s) = $a->slice_next($_)) {
		    if (defined $i) {
			_find_substitute(\@i, \@s, $i, $s, $S, \@n);
		    }
		}
		_do_substitute(\@n, \@i, \@s, \@S) if @n;
	    }
	} else {
	    foreach (@_) {
		@s = @i = @n = ();
		($i, $s) = $a->slice($_);
		if (defined $i) {
		    _find_substitute(\@i, \@s, $i, $s, $S, \@n);
		    _do_substitute(\@n, \@i, \@s, \@S);
		}
	    }
	}
	return @S;
    } elsif (defined $_) {
	if (exists $p{ g }) {
	    while (($i, $s) = $a->slice_next($_)) {
		if (defined $i) {
		    _find_substitute(\@i, \@s, $i, $s, $S, \@n);
		}
	    }
	    _do_substitute(\@n, \@i, \@s, \@S) if @n;
	} else {
	    ($i, $s) = $a->slice($_);
	    if (defined $i) {
		_find_substitute(\@i, \@s, $i, $s, $S, \@n);
		_do_substitute(\@n, \@i, \@s, \@S);
	    }
	}
	return $_ = $n[0];
    } else {
	warn "asubstitute: \$_ is undefined: what are you substituting?\n";
        return;
    }
}

sub aindex {
    my $P = shift;
    return 0 unless length $P; 
    my $a = ((@_ && ref $_[0] eq 'ARRAY') ?
		 _complex($P, @{ shift(@_) }) : _simple($P))[0];

    $a->set_greedy; # The *first* match, thank you.

    if (@_) {
	if (wantarray) {
	    return map { $a->index($_) } @_;
	} else {
	    return $a->index($_[0]);
	}
    }
    return $a->index($_) if defined $_;

    warn "aindex: \$_ is undefined: what are you indexing?\n";
    return;
}

sub aslice {
    my $P = shift;
    return (0, 0) unless length $P; 
    my $a = ((@_ && ref $_[0] eq 'ARRAY') ?
		 _complex($P, @{ shift(@_) }) : _simple($P))[0];

    $a->set_greedy; # The *first* match, thank you.

    if (@_) {
	return map { [ $a->slice($_) ] } @_;
    }
    return $a->slice($_) if defined $_;

    warn "aslice: \$_ is undefined: what are you slicing?\n";
    return;
}

sub _adist {
    my $s0 = shift;
    my $s1 = shift;
    my ($aslice) = aslice($s0, ['minimal_distance', @_], $s1);
    my ($index, $size, $distance) = @$aslice;
    my ($l0, $l1) = map { length } ($s0, $s1);
    return $l0 <= $l1 ? $distance : -$distance;
}

sub adist {
    my $a0 = shift;
    my $a1 = shift;
    if (length($a0) == 0) {
      return length($a1);
    }
    if (length($a1) == 0) {
      return length($a0);
    }
    my @m = ref $_[0] eq 'ARRAY' ? @{shift()} : ();
    if (ref $a0 eq 'ARRAY') {
	if (ref $a1 eq 'ARRAY') {
	    return [ map {  adist($a0, $_, @m) } @{$a1} ];
	} else {
	    return [ map { _adist($_, $a1, @m) } @{$a0} ];
	}
    } elsif (ref $a1 eq 'ARRAY') {
	return     [ map { _adist($a0, $_, @m) } @{$a1} ];
    } else {
	if (wantarray) {
	    return map { _adist($a0, $_, @m) } ($a1, @_);
	} else {
	    return _adist($a0, $a1, @m);
	}
    }
}

sub adistr {
    my $a0 = shift;
    my $a1 = shift;
    my @m = ref $_[0] eq 'ARRAY' ? shift : ();
    if (ref $a0 eq 'ARRAY') {
	if (ref $a1 eq 'ARRAY') {
	    my $l0 = length();
	    return $l0 ? [ map { adist($a0, $_, @m) }
			  @{$a1} ] :
		         [ ];
	} else {
	    return [ map { my $l0 = length();
			   $l0 ? _adist($_, $a1, @m) / $l0 : undef
		     } @{$a0} ];
	}
    } elsif (ref $a1 eq 'ARRAY') {
	my $l0 = length($a0);
	return [] unless $l0;
	return     [ map { _adist($a0, $_, @m) / $l0 } @{$a1} ];
    } else {
	my $l0 = length($a0);
	if (wantarray) {
	    return map { $l0 ? _adist($a0, $_, @m) / $l0 : undef } ($a1, @_);
	} else {
	    return undef unless $l0;
	    return _adist($a0, $a1, @m) / $l0;
	}
    }
}

sub adistword {
    return adist($_[0], $_[1], ['position_range=0']);
}

sub adistrword {
    return adistr($_[0], $_[1], ['position_range=0']);
}

sub arindex {
    my $P = shift;
    my $l = length $P;
    return 0 unless $l;
    my $R = reverse $P;
    my $a = ((@_ && ref $_[0] eq 'ARRAY') ?
		 _complex($R, @{ shift(@_) }) : _simple($R))[0];

    $a->set_greedy; # The *first* match, thank you.

    if (@_) {
	if (wantarray) {
	    return map {
		my $aindex = $a->index(scalar reverse());
		$aindex == -1 ? $aindex : (length($_) - $aindex - $l);
	    } @_;
	} else {
	    my $aindex = $a->index(scalar reverse $_[0]);
	    return $aindex == -1 ? $aindex : (length($_[0]) - $aindex - $l);
	}
    }
    if (defined $_) {
	my $aindex = $a->index(scalar reverse());
	return $aindex == -1 ? $aindex : (length($_) - $aindex - $l);
    }

    warn "arindex: \$_ is undefined: what are you indexing?\n";
    return;
}

1;
__END__
=pod

=head1 NAME

String::Approx - Perl extension for approximate matching (fuzzy matching)

=head1 SYNOPSIS

  use String::Approx 'amatch';

  print if amatch("foobar");

  my @matches = amatch("xyzzy", @inputs);

  my @catches = amatch("plugh", ['2'], @inputs);

=head1 DESCRIPTION

String::Approx lets you match and substitute strings approximately.
With this you can emulate errors: typing errorrs, speling errors,
closely related vocabularies (colour color), genetic mutations (GAG
ACT), abbreviations (McScot, MacScot).

NOTE: String::Approx suits the task of B<string matching>, not 
B<string comparison>, and it works for B<strings>, not for B<text>.

If you want to compare strings for similarity, you probably just want
the Levenshtein edit distance (explained below), the Text::Levenshtein
and Text::LevenshteinXS modules in CPAN.  See also Text::WagnerFischer
and Text::PhraseDistance.  (There are functions for this in String::Approx,
e.g. adist(), but their results sometimes differ from the bare Levenshtein
et al.)

If you want to compare things like text or source code, consisting of
B<words> or B<tokens> and B<phrases> and B<sentences>, or
B<expressions> and B<statements>, you should probably use some other
tool than String::Approx, like for example the standard UNIX diff(1)
tool, or the Algorithm::Diff module from CPAN.

The measure of B<approximateness> is the I<Levenshtein edit distance>.
It is the total number of "edits": insertions,

	word world

deletions,

	monkey money

and substitutions

	sun fun

required to transform a string to another string.  For example, to
transform I<"lead"> into I<"gold">, you need three edits:

	lead gead goad gold

The edit distance of "lead" and "gold" is therefore three, or 75%.

B<String::Approx> uses the Levenshtein edit distance as its measure, but
String::Approx is not well-suited for comparing strings of different
length, in other words, if you want a "fuzzy eq", see above.
String::Approx is more like regular expressions or index(), it finds
substrings that are close matches.>

=head1 MATCH

	use String::Approx 'amatch';

	$matched     = amatch("pattern") 
	$matched     = amatch("pattern", [ modifiers ])

	$any_matched = amatch("pattern", @inputs) 
	$any_matched = amatch("pattern", [ modifiers ], @inputs)

	@match       = amatch("pattern") 
	@match       = amatch("pattern", [ modifiers ])

	@matches     = amatch("pattern", @inputs) 
	@matches     = amatch("pattern", [ modifiers ], @inputs)

Match B<pattern> approximately.  In list context return the matched
B<@inputs>.  If no inputs are given, match against the B<$_>.  In scalar
context return true if I<any> of the inputs match, false if none match.

Notice that the pattern is a string.  Not a regular expression.  None
of the regular expression notations (^, ., *, and so on) work.  They
are characters just like the others.  Note-on-note: some limited form
of I<"regular expressionism"> is planned in future: for example
character classes ([abc]) and I<any-chars> (.).  But that feature will
be turned on by a special I<modifier> (just a guess: "r"), so there
should be no backward compatibility problem.

Notice also that matching is not symmetric.  The inputs are matched
against the pattern, not the other way round.  In other words: the
pattern can be a substring, a submatch, of an input element.  An input
element is always a superstring of the pattern.

=head2 MODIFIERS

With the modifiers you can control the amount of approximateness and
certain other control variables.  The modifiers are one or more
strings, for example B<"i">, within a string optionally separated by
whitespace.  The modifiers are inside an anonymous array: the B<[ ]>
in the syntax are not notational, they really do mean B<[ ]>, for
example B<[ "i", "2" ]>.  B<["2 i"]> would be identical.

The implicit default approximateness is 10%, rounded up.  In other
words: every tenth character in the pattern may be an error, an edit.
You can explicitly set the maximum approximateness by supplying a
modifier like

	number
	number%

Examples: B<"3">, B<"15%">.

Note that C<0%> is not rounded up, it is equal to C<0>.

Using a similar syntax you can separately control the maximum number
of insertions, deletions, and substitutions by prefixing the numbers
with I, D, or S, like this:

	Inumber
	Inumber%
	Dnumber
	Dnumber%
	Snumber
	Snumber%

Examples: B<"I2">, B<"D20%">, B<"S0">.

You can ignore case (B<"A"> becames equal to B<"a"> and vice versa)
by adding the B<"i"> modifier.

For example

	[ "i 25%", "S0" ]

means I<ignore case>, I<allow every fourth character to be "an edit">,
but allow I<no substitutions>.  (See L<NOTES> about disallowing
substitutions or insertions.)

NOTE: setting C<I0 D0 S0> is not equivalent to using index().
If you want to use index(), use index().

=head1 SUBSTITUTE

	use String::Approx 'asubstitute';

	@substituted = asubstitute("pattern", "replacement")
	@substituted = asubstitute("pattern", "replacement", @inputs) 
	@substituted = asubstitute("pattern", "replacement", [ modifiers ])
	@substituted = asubstitute("pattern", "replacement",
				   [ modifiers ], @inputs)

Substitute approximate B<pattern> with B<replacement> and return as a
list <copies> of B<@inputs>, the substitutions having been made on the
elements that did match the pattern.  If no inputs are given,
substitute in the B<$_>.  The replacement can contain magic strings
B<$&>, B<$`>, B<$'> that stand for the matched string, the string
before it, and the string after it, respectively.  All the other
arguments are as in C<amatch()>, plus one additional modifier, B<"g">
which means substitute globally (all the matches in an element and not
just the first one, as is the default).

See L<BAD NEWS> about the unfortunate stinginess of C<asubstitute()>.

=head1 INDEX

	use String::Approx 'aindex';

	$index   = aindex("pattern")
	@indices = aindex("pattern", @inputs)
	$index   = aindex("pattern", [ modifiers ])
	@indices = aindex("pattern", [ modifiers ], @inputs)

Like C<amatch()> but returns the index/indices at which the pattern
matches approximately.  In list context and if C<@inputs> are used,
returns a list of indices, one index for each input element.
If there's no approximate match, C<-1> is returned as the index.

NOTE: if there is character repetition (e.g. "aa") either in
the pattern or in the text, the returned index might start 
"too early".  This is consistent with the goal of the module
of matching "as early as possible", just like regular expressions
(that there might be a "less approximate" match starting later is
of somewhat irrelevant).

There's also backwards-scanning C<arindex()>.

=head1 SLICE

	use String::Approx 'aslice';

	($index, $size)   = aslice("pattern")
	([$i0, $s0], ...) = aslice("pattern", @inputs)
	($index, $size)   = aslice("pattern", [ modifiers ])
	([$i0, $s0], ...) = aslice("pattern", [ modifiers ], @inputs)

Like C<aindex()> but returns also the size (length) of the match.
If the match fails, returns an empty list (when matching against C<$_>)
or an empty anonymous list corresponding to the particular input.

NOTE: size of the match will very probably be something you did not
expect (such as longer than the pattern, or a negative number).  This
may or may not be fixed in future releases. Also the beginning of the
match may vary from the expected as with aindex(), see above.

If the modifier

	"minimal_distance"

is used, the minimal possible edit distance is returned as the
third element:

	($index, $size, $distance) = aslice("pattern", [ modifiers ])
	([$i0, $s0, $d0], ...)     = aslice("pattern", [ modifiers ], @inputs)

=head1 DISTANCE

	use String::Approx 'adist';

	$dist = adist("pattern", $input);
	@dist = adist("pattern", @input);

Return the I<edit distance> or distances between the pattern and the
input or inputs.  Zero edit distance means exact match.  (Remember
that the match can 'float' in the inputs, the match is a substring
match.)  If the pattern is longer than the input or inputs, the
returned distance or distances is or are negative.

	use String::Approx 'adistr';

	$dist = adistr("pattern", $input);
	@dist = adistr("pattern", @inputs);

Return the B<relative> I<edit distance> or distances between the
pattern and the input or inputs.  Zero relative edit distance means
exact match, one means completely different.  (Remember that the
match can 'float' in the inputs, the match is a substring match.)  If
the pattern is longer than the input or inputs, the returned distance
or distances is or are negative.

You can use adist() or adistr() to sort the inputs according to their
approximateness:

	my %d;
	@d{@inputs} = map { abs } adistr("pattern", @inputs);
	my @d = sort { $d{$a} <=> $d{$b} } @inputs;

Now C<@d> contains the inputs, the most like C<"pattern"> first.

=head1 CONTROLLING THE CACHE

C<String::Approx> maintains a LU (least-used) cache that holds the
'matching engines' for each instance of a I<pattern+modifiers>.  The
cache is intended to help the case where you match a small set of
patterns against a large set of string.  However, the more engines you
cache the more you eat memory.  If you have a lot of different
patterns or if you have a lot of memory to burn, you may want to
control the cache yourself.  For example, allowing a larger cache
consumes more memory but probably runs a little bit faster since the
cache fills (and needs flushing) less often.

The cache has two parameters: I<max> and I<purge>.  The first one
is the maximum size of the cache and the second one is the cache
flushing ratio: when the number of cache entries exceeds I<max>,
I<max> times I<purge> cache entries are flushed.  The default
values are 1000 and 0.75, respectively, which means that when
the 1001st entry would be cached, 750 least used entries will
be removed from the cache.  To access the parameters you can
use the calls

	$now_max = String::Approx::cache_max();
	String::Approx::cache_max($new_max);

	$now_purge = String::Approx::cache_purge();
	String::Approx::cache_purge($new_purge);

	$limit = String::Approx::cache_n_purge();

To be honest, there are actually B<two> caches: the first one is used
far the patterns with no modifiers, the second one for the patterns
with pattern modifiers.  Using the standard parameters you will
therefore actually cache up to 2000 entries.  The above calls control
both caches for the same price.

To disable caching completely use

	String::Approx::cache_disable();

Note that this doesn't flush any possibly existing cache entries,
to do that use

	String::Approx::cache_flush_all();

=head1 NOTES

Because matching is by I<substrings>, not by whole strings, insertions
and substitutions produce often very similar results: "abcde" matches
"axbcde" either by insertion B<or> substitution of "x".

The maximum edit distance is also the maximum number of edits.
That is, the B<"I2"> in

	amatch("abcd", ["I2"])

is useless because the maximum edit distance is (implicitly) 1.
You may have meant to say

	amatch("abcd", ["2D1S1"])

or something like that.

If you want to simulate transposes

	feet fete

you need to allow at least edit distance of two because in terms of
our edit primitives a transpose is first one deletion and then one
insertion.

=head2 TEXT POSITION

The starting and ending positions of matching, substituting, indexing, or
slicing can be changed from the beginning and end of the input(s) to
some other positions by using either or both of the modifiers

	"initial_position=24"
	"final_position=42"

or the both the modifiers

	"initial_position=24"
	"position_range=10"

By setting the B<"position_range"> to be zero you can limit
(anchor) the operation to happen only once (if a match is possible)
at the position.

=head1 VERSION

Major release 3.

=head1 CHANGES FROM VERSION 2

=head2 GOOD NEWS

=over 4

=item The version 3 is 2-3 times faster than version 2

=item No pattern length limitation

The algorithm is independent on the pattern length: its time
complexity is I<O(kn)>, where I<k> is the number of edits and I<n> the
length of the text (input).  The preprocessing of the pattern will of
course take some I<O(m)> (I<m> being the pattern length) time, but
C<amatch()> and C<asubstitute()> cache the result of this
preprocessing so that it is done only once per pattern.

=back

=head2 BAD NEWS

=over 4

=item You do need a C compiler to install the module

Perl's regular expressions are no more used; instead a faster and more
scalable algorithm written in C is used.

=item C<asubstitute()> is now always stingy

The string matched and substituted is now always stingy, as short
as possible.  It used to be as long as possible.  This is an unfortunate
change stemming from switching the matching algorithm.  Example: with
edit distance of two and substituting for B<"word"> from B<"cork"> and
B<"wool"> previously did match B<"cork"> and B<"wool">.  Now it does
match B<"or"> and B<"wo">.  As little as possible, or, in other words,
with as much approximateness, as many edits, as possible.  Because
there is no I<need> to match the B<"c"> of B<"cork">, it is not matched.

=item no more C<aregex()> because regular expressions are no more used

=item no more C<compat1> for String::Approx version 1 compatibility

=back

=head1 ACKNOWLEDGEMENTS

The following people have provided valuable test cases, documentation
clarifications, and other feedback:

Jared August, Arthur Bergman, Anirvan Chatterjee, Steve A. Chervitz,
Aldo Calpini, David Curiel, Teun van den Dool, Alberto Fontaneda,
Rob Fugina, Dmitrij Frishman, Lars Gregersen, Kevin Greiner,
B. Elijah Griffin, Mike Hanafey, Mitch Helle, Ricky Houghton,
'idallen', Helmut Jarausch, Damian Keefe, Ben Kennedy, Craig Kelley,
Franz Kirsch, Dag Kristian, Mark Land, J. D. Laub, John P. Linderman,
Tim Maher, Juha Muilu, Sergey Novoselov, Andy Oram, Ji Y Park,
Eric Promislow, Nikolaus Rath, Stefan Ram, Slaven Rezic,
Dag Kristian Rognlien, Stewart Russell, Slaven Rezic, Chris Rosin,
Pasha Sadri, Ilya Sandler, Bob J.A. Schijvenaars, Ross Smith,
Frank Tobin, Greg Ward, Rich Williams, Rick Wise.

The matching algorithm was developed by Udi Manber, Sun Wu, and Burra
Gopal in the Department of Computer Science, University of Arizona.

=head1 AUTHOR

Jarkko Hietaniemi <jhi@iki.fi>

=head1 COPYRIGHT AND LICENSE

Copyright 2001-2013 by Jarkko Hietaniemi

This library is free software; you can redistribute it and/or modify
under either the terms of the Artistic License 2.0, or the GNU Library
General Public License, Version 2.  See the files Artistic and LGPL
for more details.

Furthermore: no warranties or obligations of any kind are given, and
the separate file F<COPYRIGHT> must be included intact in all copies
and derived materials.

=cut
