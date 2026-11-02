package Pipe::Declare;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Pipe::Declare', $VERSION);

sub import   { $^H{'Pipe::Declare'} = 1 }
sub unimport { delete $^H{'Pipe::Declare'} }

1;

__END__

=head1 NAME

Pipe::Declare - compile time, lexically scoped C<< |> >> pipelines

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Pipe::Declare;

	# block form: assemble a value via left-to-right steps
	my $total = pipe {
	    [1, 2, 3, 4, 5]
	        |> grep { $_ % 2 }            # keep odd     -> [1,3,5]
	        |> map  { $_ * $_ }           # square them  -> [1,9,25]
	        |> sum_aref                   # bareword sub -> 35
	};

	# infix form: use |> as a real binary operator anywhere in the
	# lexical scope (perl 5.38+)
	my $title = $user |> fetch_profile |> profile_title;
	my $tot   = sum_of(values %h) |> normalise |> round_2dp;

	# statement form: drive side effects
	pipe { $request
	        |> validate
	        |> tap { warn "ok: $_->{id}" }
	        |> dispatch };

	# all the step shapes (block form)
	pipe { $h
	        |> ->{users}                  # hash deref
	        |> ->[0]                      # array deref
	        |> ->name                     # method call (nullary)
	        |> uc                         # bareword nullary
	        |> wrap(_, '[', ']')          # bareword + _ placeholder
	        |> \&trim                     # \&name
	        |> sub { "$_[0]!" }           # inline anonymous sub
	        |> $formatter                 # any expr yielding a coderef
	};

=head1 DESCRIPTION

C<Pipe::Declare> installs an F#/Elixir style C<< |> >> pipeline operator
in two complementary spellings:

=over 4

=item *

A B<block keyword> C<pipe { HEAD |> step |> step ... }> that works on
B<perl 5.14 and later> and supports every step shape (bareword,
C<-E<gt>method>, C<-E<gt>{key}>, C<-E<gt>[idx]>, C<\&name>, C<sub {...}>,
C<$cv>, C<map>/C<grep>/C<tap> blocks, and the C<_> placeholder).

=item *

A real B<global infix operator> C<< |> >> usable anywhere in the lexical
scope, on B<perl 5.38 and later> (which provides C<PL_infix_plugin>). The
infix form supports bareword calls, method calls, coderefs and chained
C<< |> >>; the block-style steps (C<map>/C<grep>/C<tap>, C<_> placeholder)
are block-form only.

=back

Both forms are parsed at B<compile time> and lowered to an ordinary Perl
optree. The common case (every step takes the topic exactly once)
lowers to a fully nested call expression with zero per-step overhead -
benchmarked at parity with hand-written nested calls (see
L</PERFORMANCE>).

It is a real B<lexical pragma>: both spellings are recognised only
inside the lexical scope of C<use Pipe::Declare>, and are disabled again
by C<no Pipe::Declare>. Outside such a scope C<pipe> resolves to the
core C<CORE::pipe> built-in unchanged, and C<< |> >> is a parse error
(perl sees C<|> as bitwise-or and C<< > >> as the start of something
else).

=head1 SEMANTICS

A C<pipe { HEAD |> step |> step ... }> block is one expression made of
two parts: a B<head term> that supplies the initial value, and a
sequence of B<steps> each separated by C<< |> >>.

	my $topic = HEAD;             # evaluated exactly once
	$topic = step_1($topic);
	$topic = step_2($topic);
	...
	step_N($topic)                # final step: no assignment, so its
	                              # calling context flows through

The hidden C<$topic> is a fresh pad lexical, invisible to user code.

=over 4

=item * The B<head expression is evaluated exactly once>, no matter how
many steps follow.

=item * B<Intermediate steps run in scalar context> (the topic is one
scalar slot). The B<final step inherits the calling context> of the
whole C<pipe { ... }> expression - scalar, list, or void.

=item * Steps run B<strictly left to right>; there is no reordering.

=item * Exceptions B<propagate> out of the pipe; there is no implicit
C<eval>.

=back

=head1 HEAD FORMS

	$var, $Pkg::var          scalar variable
	NUMBER, "STR", 'STR'     literals
	[ LIST ]                 anonymous arrayref literal
	name, name(args),
	Foo::Bar::name(args)     bareword call (qualified or not)
	( ANY EXPRESSION )       parens delimit a full expression

For anything else, wrap in parens: C<< pipe { ( $obj->factory->build ) |> ... } >>.

=head1 STEP FORMS

	|> name                  bareword nullary    -> name($topic)
	|> name(a, b)            bareword with args  -> name($topic, a, b)
	|> name(a, _, b)         _ placeholder       -> name(a, $topic, b)
	|> name(_, _, _)         multiple _          -> name($topic, $topic, $topic)
	|> Foo::Bar::name        qualified           -> Foo::Bar::name($topic)
	|> \&name                ref form            -> name($topic)
	|> sub { BLOCK }         inline coderef      -> (sub { BLOCK })->($topic)
	|> $cv                   scalar coderef      -> $cv->($topic)
	|> ->method              method nullary      -> $topic->method
	|> ->method(args)        method with args    -> $topic->method(args)
	|> ->{KEY}               hash deref          -> $topic->{KEY}
	|> ->[IDX]               array deref         -> $topic->[IDX]
	|> map  { BLOCK }        block map           -> [ map  { BLOCK } @{$topic} ]
	|> grep { BLOCK }        block grep          -> [ grep { BLOCK } @{$topic} ]
	|> tap  { BLOCK }        side-effect tap     -> do { my $t = $topic; for ($t) { BLOCK } $t }

The C<_> placeholder in a bareword-call arglist is replaced by the topic
at B<every occurrence>, suppressing the default first-argument threading.
Inside C<map> / C<grep> / C<tap> blocks, C<$_> is the iteration element
(for map/grep) or the topic (for tap), exactly as the underlying Perl
operators behave. The three block steps compile to perl's own C<map>,
C<grep> and C<foreach>, not to a sub call, so C<return> inside one of
them returns from the enclosing sub, as it would in a plain C<map>
block. A C<tap> block sees a private copy of the topic in C<$_>:
assigning to C<$_> changes what flows to the next step, nothing else.

=head1 INFIX FORM (perl 5.38+)

On perl 5.38 and later, C<< |> >> is also registered as a real
left-associative infix operator usable anywhere in the lexical scope of
C<use Pipe::Declare>, with no surrounding C<pipe { }> required:

	use Pipe::Declare;

	my $tidy = $name |> trim |> lc;
	my $sz   = $bytes + 1024 |> humanize;       # ($bytes + 1024) |> humanize
	my $name = $user |> fetch_profile |> profile_name(_, 'short');

=head2 Precedence

C<< |> >> binds at C<INFIX_PREC_LOGICAL_OR> - the same precedence as
C<||>: B<tighter than> C<=>, C<,>, C<or>, C<and>, but B<looser than>
C<+>, C<-> and everything arithmetic. The common expectations all hold:

	my $r = $x |> f;            # my $r = ($x |> f)
	$x + 1 |> f;                # ($x + 1) |> f
	$x |> f or warn 'nope';     # ($x |> f) or warn 'nope'
	$x |> f |> g |> h;          # ((($x |> f) |> g) |> h)

=head2 Splice rules

The infix form mirrors the block form's step-shape recognition:

=over 4

=item * B<Bareword / sub call:> LHS becomes the B<first> positional arg.

	$x |> f          # f($x)
	$x |> f(a, b)    # f($x, a, b)

=item * B<Method call:> LHS becomes the B<second> positional - inserted
after the invocant, before any explicit args.

	$x |> $obj->m         # $obj->m($x)
	$x |> $obj->m(a, b)   # $obj->m($x, a, b)

=item * B<Coderef expression> (C<\&name>, C<sub { ... }>, scalar holding
a coderef, anything else): RHS is called with LHS as the sole arg.

	$x |> \&f         # f->($x)
	$x |> sub { ... } # (sub { ... })->($x)
	$x |> $cv         # $cv->($x)

=back

The block-only step forms (C<map>/C<grep>/C<tap> blocks, C<_>
placeholder, C<< -E<gt>method >> as a standalone step, C<< -E<gt>{key} >>
/ C<< -E<gt>[idx] >> deref steps) are B<not> available in the infix
form: write them in a C<pipe { ... }> block instead. Perl B<built-ins>
(C<ref>, C<length>, C<defined>, ...) don't parse as C<OP_ENTERSUB> and so
fall into the coderef path, which fails at runtime - wrap them in an
anon sub if you need them in the infix form.

=head1 SUMMARY TABLE

	scrutinee / head           evaluated exactly once
	intermediate-step context  scalar
	final-step context         inherits the pipe expression's context
	match order                strict left-to-right
	exceptions                 propagate; no implicit eval
	value of the whole pipe    value of the final step

=head1 COMPARISON WITH Func::Util::pipeline

L<Func::Util> already ships a runtime, value-level C<pipeline()>:

	my $result = pipeline($data, \&fetch, \&transform, \&process);

C<Pipe::Declare> is the B<compile-time, syntactic> form of the same idea.
They coexist; pick whichever reads more naturally for the call site.

	                          Func::Util::pipeline      Pipe::Declare
	when threading happens    runtime                    compile time
	step shape                coderef only               any of the step forms above
	extra args per step       via wrapper closures       inline: |> f(a, b, _)
	optree per pipeline       one entersub + array walk  one call per step
	reads as                  data-style                 code-style (left-to-right)
	method / deref step       via wrapper closures       natively (->method, ->{k}, ->[i])

=head1 LIMITATIONS

=over 4

=item * The topic is always a single scalar. Pipelines that need
list-context threading must encode it as an arrayref (which is the
natural input/output shape for the C<map> / C<grep> block steps).

=item * The block-step set is closed: C<map>, C<grep>, C<tap>.
Adding more (e.g. C<reduce>, C<sort>) is a v1.1 option.

=item * The C<_> placeholder is recognised only when it stands alone in
an arglist position (followed by C<,> or C<)>). Complex expressions
involving the topic should be written using a coderef step.

=item * The infix form (C<< |> >> outside a C<pipe { }> block) requires
perl B<5.38 or later> for C<PL_infix_plugin>. The block form works on
5.14+.

=item * In the infix form, perl built-ins (C<ref>, C<length>, ...) don't
parse as C<OP_ENTERSUB> and fall into the coderef path, failing at
runtime. Wrap them in C<sub { ref $_[0] }> or use the block form.

=back

=head1 PERFORMANCE

The whole pipe lowers to one nested expression:

	step_N( ... step_2( step_1( HEAD ) ) ... )

No hidden temp, no statement sequence: the optree is what you would
write by hand. A step that uses C<_> more than once gets a hidden
scalar assigned in its first C<_> and read in the others, which is how
you would write C<name($t = step_1(HEAD), $t)> yourself, and keeps the
documented "intermediate steps are scalar context" semantics.

Measured against hand-written nested calls (F<xt/bench.pl>; perl 5.42 on
Apple Silicon):

	3-step bareword chain     within 1% of hand-nested
	5-step bareword chain     within 1% of hand-nested
	call-with-args + _        within 2% of hand-nested
	name(_, _) step           within 5% of a hand-written temp
	->method chain (4 steps)  within 2% of hand-nested
	map | grep (100 elems)    ~15% slower (the head copies the array)
	tap between two calls     ~11% slower (a do-block around a foreach)

A run of consecutive C<map> / C<grep> steps is B<fused>: only the last
step of the run builds an arrayref, the earlier ones feed their list
straight into the next, exactly as C<[ grep { B2 } map { B1 } @$topic ]>
would. The remaining C<map>/C<grep> cost against the hand-written chain
is the head: C<[@big]> copies the array into a fresh arrayref where the
hand-written form reads C<@big> in place.

C<tap> lowers to a C<foreach> over a private copy of the topic, so a
tap step costs one loop iteration, with no closure built and no sub
called.

=head1 SEE ALSO

L<Switch::Declare> - compile-time C<switch>/C<case> by the same author,
sharing the keyword-plugin and C<$^H> lexical pragma scaffolding.

L<Func::Util> - the runtime, value-level cousin of this module
(C<pipeline>, C<compose>, C<tap>, etc.).

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pipe-declare at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pipe-Declare>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pipe::Declare

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Pipe-Declare>

=item * Search CPAN

L<https://metacpan.org/release/Pipe-Declare>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Pipe::Declare
