package Set::Select;

use strict;
use warnings;
use Carp;

our $VERSION = '1.01';

sub new {
	my $class = shift;

	my $self = {};
	for my $i (0..$#_) {
		croak "Arguments must be array references (argument $i is not)" if not ref $_[$i] eq 'ARRAY';
		for my $elem (@{$_[$i]}) {
			my $key = $elem;
			$self->{$key}->[1] //= $elem;
			$self->{$key}->[0] //= '0' x @_;
			vec($self->{$key}->[0], $i, 8) = 0x31;
		}
	}
	bless $self, $class;
}

sub select {
    my ($self, $bits) = @_;
    return [map { $self->{$_}->[1] } grep { $self->{$_}->[0] =~ /^$bits$/ } keys %$self];
}

sub all_subsets {
	my $self = shift;
	my %keys;
	for my $e (values %$self) {
		push @{$keys{$e->[0]}}, $e->[1];
	}
	return \%keys;
}

1;

__END__

=head1 NAME

Set::Select - select common subsets from two or more sets

=head1 SYNOPSIS

  use Set::Select;
  use Data::Dumper;

  my $sets = Set::Select->new(
    [1, 3, 5, 7],
    [2, 3, 6, 7],
    [4, 5, 6, 7]
  );

  print Dumper $sets->select($_) for 
    '100',          # only in the first set: [1]
    '101',          # in the first and third sets: [5]
    '111',          # in all three sets, i.e. intersection: [7]
    '10.',          # in the first but not in the second sets, don't care about the 3rd: [1,5]
    '...',          # in any of the sets, i.e. union: [1,2,3,4,5,6,7]
    '100|010|001';  # in exactly one of the sets: [1,2,4]
    '.+',           # union of all sets, shorter syntax: [1,2,3,4,5,6,7]
    '1+';           # intersection of all, shorter syntax: [7]

  print Dumper $sets->all_subsets();

=head1 DESCRIPTION

This is an OO module that makes it possible to select common subsets (e.g.
unions, intersection, or any other combination) from two or more input sets
efficiently with a terse query syntax.

The input sets must be fed to the constructor as array references.
It is a fatal error if any of the arguments is not an array reference.

The returned object has a method called select, which accepts a selector
string argument and emits (an arrayref of) the elements that match the selector.
The selector strings consist of literal C<1>s and C<0>s, and they should be
as long as the number of input sets. For example, if we have 3 input sets,
then the '110' selector string selects all elements that are in the first
and second sets but not in the third.

However, it is important to note that the selector string is matched as a
regular expression, as shown in the synopsis. E.g. unions can be best
expressed with the C<.> metacharacter, but it is possible to use all arbitrarily
clever regex features. The selector string is passed into a regular
expression which is anchored at both ends (i.e. C</^$expression$/>).

A Venn diagram (matching the example above) that may or may not make the intent clearer:


       Elements:                 Selectors:
         .---.                     .---.
        /  1  \                   / 100 \
       |       |                 |       |
    .--+--. .--+--.           .--+--. .--+--.
   /   | 3 X 5 |   \         /   |110X101|   \
  |    |  / \  |    |       |    |  / \  |    |
  |  2  \/ 7 \/  4  |       | 010 \/111\/ 001 |
  |     |`---'|     |       |     |`---'|     |
  |      \ 6 /      |       |      \011/      |
   \      \ /      /         \      \ /      /
    `------^------'           `------^------'

Every distinct region of the Venn-diagram is addressable with a unique
selector string.

=head1 CONSTRUCTOR

=head2 Set::Select->new($aref1, $aref2, ...)

Build a new Set::Select object. The arguments must be array references.
The constructor croaks on non-arrayref arguments.

=head1 METHODS

=head2 select($string)

Expects a single string argument. In the simplest case this string contains
only the literal C<0> and C<1> characters, and it should be as long as
the number of input sets. However, the string is actually interpreted as
a regular expression, so any regular expression can be used that matches
some sequences of C<0>s and C<1>s.

Returns an array reference that contains all distinct elements from the
input sets that match the selector string. The order of elements is B<not>
preserved.

=head2 all_subsets()

Returns a hash reference whose keys are selector strings (sequences of C<0>s
and C<1>s), corresponding to distinct, non-empty regions of the Venn-diagram.
The values are array references, that is, the subsets that match the selector
string (the key).

In effect, this method enumerates all non-empty subsets: all elements in
the input arrays are categorized into one of the subsets, and each original
element appears once in exactly one of the subsets.

=head1 RATIONALE

If we have just two sets, it is considered a solved problem to get their union
or intersection or symmetric difference, there is even an entry in perlfaq4 about it.
The situation is slightly more complicated if we have more than two input sets,
because then it's a valid question to ask to e.g. get the set of elements
that are in the first or second set but not in the third and fourth etc.

The number of combinations grows rapidly with the number of input sets,
and just writing ad hoc solutions to each little problem becomes infeasible.

I think these selector strings as the primary (and only) user interface
are better than the possible alternatives that come to mind:
a verbose, ad hoc query language would have to be explained at length in the
documentation, tested carefully in the source, and parsed painfully at runtime,
while a forest of arbitrarily named methods to select this or that subset
would bloat the code needlessly and make the module harder to use.

Using regular expressions opens the door to abuse, but it also allows for
convenient and terse selector strings, makes the implementation efficient,
and it's something people already know.

=head1 SEE ALSO

A cursory search of CPAN brought up several (abandoned?) modules in the
Set::* namespace, but none of them was exactly what I needed.



=head1 AUTHOR

Peter Juhasz, E<lt>pjuhasz@rt.cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Peter Juhasz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.36.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
