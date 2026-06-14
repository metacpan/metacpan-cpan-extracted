package Switch::Declare;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.02';

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
		case 200           { handle_ok()    }   # numeric  -> ==
		case "GET"         { handle_get()   }   # string   -> eq
		case /^\d+$/       { all_digits()   }   # regex    -> =~
		case [400 .. 499]  { client_error() }   # range    -> >= && <=
		case ["a","b","c"] { in_set()       }   # list     -> membership
		case \&is_weekend  { weekend()      }   # predicate-> $code->($topic)
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

=back

Range and list comparisons follow Perl's own C<==>/C<eq> rules per element, so
a C<[1, 2, 3]> list (numeric elements) compared against a non-numeric topic
warns under C<use warnings> exactly as the equivalent hand-written
C<$x == 1 || $x == 2> would. Keep list/range element types consistent with the
topic to avoid this.

Patterns are deliberately a small, predictable grammar of literals rather than
arbitrary expressions, so classification is unambiguous and the emitted code is
as tight as a hand-written conditional.

=head1 PERFORMANCE

The keyword plugin emits the op tree directly in place of the keyword, so there
is no wrapper subroutine call per evaluation. The chain of C<case> tests lowers
to a native conditional expression - the very same C<==>/C<eq>/C<=~>/bounds ops
you would write by hand.

For the common case - the scrutinee is a plain variable or constant and each arm
is a single-expression block - the construct compiles to B<exactly> a hand-written
C<if>/C<elsif> (ternary) chain: no temporary, no enclosing scope, no extra ops.
In the bundled benchmark (C<xt/bench.pl>) C<switch> and the equivalent hand-rolled
chain run within measurement noise of each other (0-2%).

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
