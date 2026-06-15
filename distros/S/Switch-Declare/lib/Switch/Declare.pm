package Switch::Declare;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Switch::Declare', $VERSION);

sub import   { $^H{'Switch::Declare'} = 1 }
sub unimport { delete $^H{'Switch::Declare'} }

1;

__END__

=head1 NAME

Switch::Declare - compile-time, lexically-scoped C<switch>/C<case>

=head1 SYNOPSIS

	use Switch::Declare;

	# statement form
	switch ($value) {
		case 200           { handle_ok()    }   # numeric   -> ==
		case "GET"         { handle_get()   }   # string    -> eq
		case /^\d+$/       { all_digits()   }   # regex     -> =~
		case [400 .. 499]  { client_error() }   # range     -> >= && <=
		case ["a","b","c"] { in_set()       }   # list      -> membership
		case \&is_weekend  { weekend()      }   # predicate -> $code->($topic)
		case ref(ARRAY)    { handle_aref()  }   # reference type (exact)
		case reftype(HASH) { handle_href()  }   # underlying type (through blessing)
		case isa("Plan")   { handle_plan()  }   # blessed object derived from class
		case MAX_RETRIES   { exhausted()    }   # named constant (use constant)
		case == $limit     { at_limit()     }   # numeric compare vs a variable
		case eq $name      { named()        }   # string  compare vs a variable
		case =~ $pattern   { matched()      }   # regex match vs a runtime pattern
		case undef         { missing()      }   # the topic is undef
		default            { fallback()     }
	}

	# expression form - yields the matched arm's value
	my $label = switch ($status) {
		case 200 { "ok" }
		case 404 { "missing" }
		default  { "other" }
	};

=head1 DESCRIPTION

C<Switch::Declare> installs a C<switch> keyword that parses an entire
C<switch (EXPR) { ... }> construct at B<compile time> and lowers it to an
ordinary Perl optree. All of the parsing work happens once, at compile time 
- nothing of the parser remains at runtime.

The construct is a real B<lexical pragma>: the C<switch> keyword is recognised
only within the lexical scope of a C<use Switch::Declare> (and can be switched
off again with C<no Switch::Declare>). Outside such a scope C<switch> is an
ordinary identifier, so the keyword never collides with unrelated code.

The scrutinee is evaluated B<exactly once>. The first matching C<case> wins;
there is no implicit fallthrough. A trailing C<default> matches when no C<case>
did. Used as an expression the construct yields the value of the executed block
(C<undef> if nothing matched and there is no C<default>); used as a statement
it simply runs the matched block.

=head2 Pattern kinds

Each C<case> pattern is recognised at compile time and lowered to the cheapest
matching op:

=over 4

=item * a B<number literal> compiles to numeric C<==>

=item * a B<string literal> (C<'...'> or C<"...">) compiles to string C<eq>

=item * a B</.../> B<regex> (with optional C<imsx> flags) matches the topic

=item * a C<[ LO .. HI ]> B<range> compiles to an inclusive bounds test
(numeric or string depending on the bound literals)

=item * a C<[ a, b, c ]> B<list> compiles to a membership test (an C<OR> chain
of equality tests, each numeric or string per element)

=item * a B<predicate> - either C<\&name> (optionally package-qualified,
C<\&Pkg::name>) or an inline C<sub { ... }> - is called with the topic as its
argument; a true return matches. An inline sub closes over the enclosing
lexicals:

	my $limit = 100;
	switch ($n) {
	    case sub { $_[0] > $limit } { "over" }
	    default                     { "ok"   }
	}

=item * C<ref(TYPE)> matches when C<ref($topic) eq "TYPE"> - the usual
C<ARRAY>/C<HASH>/C<CODE>/C<SCALAR>/C<Regexp>/... names, or a class name for
exact-class dispatch (C<ref($obj) eq "My::Class">). Bare C<ref> matches any
reference. C<TYPE> may be a bareword or a quoted string.

=item * C<reftype(TYPE)> is like C<ref(TYPE)> but reports the B<underlying>
reference type, seeing through blessing - so a blessed arrayref matches
C<reftype(ARRAY)> (where C<ref(ARRAY)> would not). Bare C<reftype> matches any
reference.

=item * C<isa(Class)> matches a B<blessed object> derived from C<Class> (a fast
C<@ISA> check). It does not match plain class-name strings or unblessed
references, and never dies on a non-object. It is a direct C<@ISA> walk, so it
does not invoke an overridden C<isa()>/C<DOES> method.

=item * C<undef> matches when the topic is undefined (see L</Undef and type
safety>).

=item * a B<named constant> - a bareword naming an inlinable C<use constant>
(optionally package-qualified, C<Pkg::FOO>) - is folded to its value at compile
time and classified exactly like the literal it holds: a numeric constant
compiles to C<==>, a string constant to C<eq> (and is dispatch-eligible). It
costs nothing at runtime - C<case FOO> is byte-for-byte C<case 1>.

=item * a B<variable comparison> C<== $x> or C<eq $x> compares the topic against
a runtime scalar. Because a variable's type is unknown at compile time, the
comparison operator is written out: C<== $x> is numeric (C<==>, C<looks_like_number>
-guarded on both sides), C<eq $x> is string (C<eq>) - exactly as in Perl itself.
The operand is a plain scalar (C<$name> or C<$Pkg::name>); both are undef-safe (an
undef topic I<or> an undef/non-numeric variable simply does not match, and never
warns):

	my $limit = 100;
	my $tag   = "draft";
	switch ($value) {
	    case == $limit { "at the limit" }
	    case eq $tag   { "a draft"      }
	    default        { "other"        }
	}

=item * a B<runtime regex match> C<=~ $rx> matches the topic against a pattern
held in a scalar - a C<qr//> object (recommended) or a string used as a pattern.
This complements the compile-time C<< /literal/ >> form for the case where the
pattern is only known at run time. It is undef-safe (an undef topic or undef
pattern simply does not match, without warning). Being a runtime match outside a
real C<m//> op, it is a pure membership test and does B<not> set the capture
variables (C<$1>, C<@+>); if you need captures from a variable pattern, use a
predicate arm, C<< case sub { $_[0] =~ $rx } >>. The operand is a plain scalar
(C<$name> or C<$Pkg::name>):

	my $rx = qr/^\d{4}-\d{2}-\d{2}$/;
	switch ($field) {
	    case =~ $rx { "looks like a date" }
	    default     { "something else"    }
	}

=back

=head2 Undef and type safety

Every pattern is undef and type-safe: a topic never produces a warning, and
only matches a pattern the comparison is actually meaningful for.

=over 4

=item * An B<undef> topic matches only an explicit C<case undef>; otherwise it
falls through to C<default>. It never warns, and it never accidentally matches
C<case 0> or C<case "">.

=item * A B<numeric> pattern (number literal, range, or numeric list element)
matches only a topic that C<looks_like_number>. A non-numeric topic neither
matches nor warns - so C<< switch("one") { case 1 {...} } >> is silent (and,
unlike a hand-written C<< "one" == 0 >>, never mis-matches C<case 0>).

=back

This is a deliberate difference from a naive hand-written C<==>/C<eq> chain,
which would warn (C<Use of uninitialized value>, C<Argument isn't numeric>) on
the same inputs. C<Switch::Declare> behaves like a I<correctly guarded> chain.

Patterns are deliberately a small, predictable grammar rather than arbitrary
expressions, so classification is unambiguous and the emitted code is as tight
as a hand-written conditional.

=head1 PERFORMANCE

The keyword plugin emits the op tree directly in place of the keyword, so there
is no wrapper subroutine call per evaluation. The chain of C<case> tests lowers
to a native conditional expression - the very same C<==>/C<eq>/C<=~>/bounds ops
you would write by hand.

For a B<string>, regex, predicate, or reference switch over a plain variable or
constant scrutinee with single-expression arms, the construct compiles to
B<exactly> a hand-written C<if>/C<elsif> (ternary) chain: no temporary, no
enclosing scope, no extra ops. In the bundled benchmark (C<xt/bench.pl>) these
run within measurement noise of a hand-rolled chain (0-2%).

A B<numeric> switch pays for its type safety (see L</Undef and type safety>):
each numeric comparison is guarded by C<looks_like_number>, computed B<once> per
evaluation and shared across the arms. It therefore runs on par with an
I<equivalently guarded> hand-written chain (within ~3% in C<xt/bench.pl>), and
roughly 40-45% slower than a naive I<unguarded> C<$x == N> chain - which is the
cost of not warning or mis-matching on non-numeric input. If you know the topic
is always numeric and want the last drop of speed, a string switch or a
hand-rolled chain avoids the guard.

=head2 Dispatch mode

When a switch is effectively a lookup table - every C<case> maps a B<string>
literal to a B<constant> value, with at least a handful of arms - it is lowered
to a single O(1) hash lookup against a hash built once at compile time, instead
of an O(n) chain of C<eq> tests:

	# compiles to a single hash lookup, not 6 string comparisons
	my $name = switch ($code) {
		case "GET"    { "read"   }
		case "PUT"    { "update" }
		case "POST"   { "create" }
		case "DELETE" { "remove" }
		case "PATCH"  { "modify" }
		case "HEAD"   { "peek"   }
		default       { "?"      }
	};

In the bundled benchmark a 20-arm string switch in dispatch mode runs about
2.5x faster than the equivalent hand-written C<if>/C<elsif> chain. The table is
constructed once at compile time (not per call), so there is no per-evaluation
build cost. Dispatch mode is chosen automatically; it never changes behaviour
(numeric switches keep C<==> semantics and stay as a chain; any non-constant arm
or duplicate key falls back to the chain), so you never opt in or out.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
