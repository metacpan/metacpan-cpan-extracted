package Set::FA;

use parent 'Set::Object';
use strict;
use warnings;

our $VERSION = '2.01';

# -----------------------------------------------

sub accept
{
	my($self, $input) = @_;
	my($set)          = (ref $self) -> new;

	for my $automaton ($self -> members)
	{
		$set -> insert($automaton) if ($automaton -> accept($input) );
	}

	return $set;

} # End of accept.

# -----------------------------------------------

sub advance
{
	my($self, $input) = @_;

	for my $automaton ($self -> members)
	{
		$automaton -> advance($input);
	}

} # End of advance.

# -----------------------------------------------

sub final
{
	my($self) = @_;
	my($set)  = (ref $self) -> new;

	for my $automaton ($self -> members)
	{
		$set -> insert($automaton) if ($automaton -> final);
	}

	return $set;

} # End of final.

# -----------------------------------------------

sub id
{
	my($self, $id) = @_;
	my($set)       = (ref $self) -> new;

	for my $automaton ($self -> members)
	{
		$set -> insert($automaton) if ($automaton -> id eq $id);
	}

	return $set;

} # End of id.

# -----------------------------------------------

sub in_state
{
	my($self, $state) = @_;
	my($set)          = (ref $self) -> new;

	for my $automaton ($self -> members)
	{
		$set -> insert($automaton) if ($automaton -> state eq $state);
	}

	return $set;

} # End of in_state.

# -----------------------------------------------

sub reset
{
	my($self) = @_;

	for my $automaton ($self -> members)
	{
		$automaton -> reset;
	}

} # End of reset.

# -----------------------------------------------

sub step
{
	my($self, $input) = @_;

	for my $automaton ($self -> members)
	{
		$automaton -> step($input);
	}

} # End of step.

# -----------------------------------------------

1;

=pod

=head1 NAME

Set::FA - A Set of Discrete Finite Automata

=head1 Synopsis

This is scripts/synopsis.1.pl:

	#!/usr/bin/perl

	use strict;
	use warnings;

	use Set::FA;
	use Set::FA::Element;

	# --------------------------

	my(@a) = map
	{
		Set::FA::Element -> new
		(
			accepting   => ['ping'],
			id          => "a.$_",
			start       => 'ping',
			transitions =>
			[
				['ping', 'a', 'pong'],
				['ping', '.', 'ping'],
				['pong', 'b', 'ping'],
				['pong', '.', 'pong'],
			],
		)
	} (0 .. 2);

	my(@b) = map
	{
		Set::FA::Element -> new
		(
			accepting   => ['pong'],
			id          => "b.$_",
			start       => 'ping',
			transitions =>
			[
				['ping', 'a', 'pong'],
				['ping', '.', 'ping'],
				['pong', 'b', 'ping'],
				['pong', '.', 'pong'],
			],
		)
	} (0 .. 4);

	my($set)   = Set::FA -> new(@a, @b);
	my($sub_a) = $set -> accept('aaabbaaabdogbbbbbababa');
	my($sub_b) = $set -> final;

	print 'Size of $sub_a: ', $sub_a -> size, ' (expect 3). ',
		'Size of @a: ', scalar @a, ' (expect 3). ',
		'Size of $sub_b: ', $sub_b -> size, ' (expect 5). ',
		'Size of @b: ', scalar @b, ' (expect 5). ', "\n",

=head1 Description

L<Set::FA> provides a mechanism to define and run a set of DFAs.

=head1 Installation

Install L<Set::FA> as you would for any C<Perl> module:

Run:

	cpanm Set::FA

or run:

	sudo cpan Set::FA

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

=head2 Parentage

This class extends L<Set::Object>, meaning L<Set::FA> is a subclass of L<Set::Object>.

For the (long) list of methods available and provided by L<Set::Object>, see that object's
documentation.

=head2 Using new()

L</new([@list_of_dfas])> is called as C<< my($set) = Set::FA -> new(@list_of_dfas) >>.

It returns a new object of type C<Set::FA>.

You may supply a list of L<Set::FA::Element> objects to L</new([@list_of_dfas])>.

If the list is empty, you will need to call $set -> insert(@list_of_dfas) to do anything meaningful
with $set.

The new object is a set whose members are all L<Set::FA::Element> objects.

This class allows you to operate on all members of the set simultaneously, as in the
synopsis.

=head1 Methods

=head2 accept($input)

Calls L<Set::FA::Element/accept($input)> on all members of the set. This in turn calls
L<Set::FA::Element/advance($input)> on each member.

Note: This does I<not> mean it calls C<advance()> on the set object.

Returns a L<Set::FA> object containing just the members of the original set which have ended up
in their respective accepting states.

=head2 advance($input)

Calls L<Set::FA::Element/advance($input)> on all members of the set.

Returns nothing.

=head2 final()

Calls L<Set::FA::Element/final()> on all members of the set.

Returns a L<Set::FA> object containing just the members of the original set which are
in their respective accepting states.

=head2 id($id)

Returns a L<Set::FA> object containing just the members of the original set whose ids
match the $id parameter.

=head2 in_state($state)

Returns a L<Set::FA> object containing just the members of the original set who current
state matches the $state parameter.

=head2 new([@list_of_dfas])

Here, the [] indicate an optional parameter.

The constructor. See L</Constructor and Initialization>.

=head2 reset()

Calls L<Set::FA::Element/reset()> on all members of the set.

Returns nothing.

=head2 step($input)

Calls L<Set::FA::Element/step($input)> on all members of the set.

Returns nothing.

=head1 FAQ

See L<Set::FA::Element/FAQ>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Credit

The code was rewritten to perform exactly as did earlier versions (pre-1.00) of L<Set::FA> and
L<Set::FA::Element>, and hence is essentially the same, line for line.

I've reformatted it, and changed the OO nature and the logging, obviously, but Mark Rogaski, the
author of L<Set::FA> gets the credit for the code.

I've rewritten the documentation from scratch.

=head1 See Also

Before adopting L<Set::FA> (for L<Graph::Easy::Marpa>'s lexer), here are some other DFA modules I
found on L<https://metacpan.org>:

=over 4

=item o L<DFA::Kleene>

The author definitely knows what he's doing, but this module addresses a different issue than I
face. It outputs regexps corresponding to the transitions you specify.

=item o L<DFA::Statemap>

This is a wrapper around the State Machine Compiler, to output a SM in Perl. SMC requires Java,
and can output in a range of languages. See L<http://smc.sourceforge.net/>.

SMC looks sophisticated, but it's a rather indirect way of doing things when Perl modules such
as L<Set::FA::Element> are already available.

=item o L<Dict::FSA>

This module is a perl wrapper around C<fsa>, a set of tools based on finite state automata.

See L<http://www.eti.pg.gda.pl/~jandac/fsa.html>.

=item o L<DMA::FSM>

Uses a very old-fashioned style of writing Perl.

=item o FLAT::DFA. See L<FLAT>

A toolkit for manipulating DFAs.

=item o L<FSA::Engine>

A Moose Role to convert an object into a Finite State Machine.

=item o L<FSA::Rules>

Build simple rules-based state machines in Perl.

=item o L<IDS::Algorithm::DFA>

Uses an old-fashioned style of writing Perl.

=item o L<MooseX::FSM>

Looks like an unfinished thought-bubble.

=item o L<Parse::FSM>

Outputs a Perl module implementing the FSM you define.

=item o L<The Ragel State Machine Compiler|http://www.complang.org/ragel/>

A non-Perl solution.

That page has lots of interesting links.

=item o L<Shishi>

Doesn't use a transition table, but does allow you to modify the SM while it's running.
You build up a transition network diagram, labouriously, with 1 line of code at a time.

=back

See also L<this Wikipedia article|http://en.wikipedia.org/wiki/Deterministic_finite-state_machine>.

=head1 Repository

L<https://github.com/ronsavage/Set-FA>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Set::FA>

=head1 Author

L<Set::FA> was written by Mark Rogaski and Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

My homepage: L<http://savage.net.au/index.html>

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
