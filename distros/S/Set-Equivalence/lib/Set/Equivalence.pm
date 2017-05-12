use 5.008;
use strict;
use warnings;

package Set::Equivalence;

BEGIN {
	$Set::Equivalence::AUTHORITY = 'cpan:TOBYINK';
	$Set::Equivalence::VERSION   = '0.003';
}

use Carp qw( croak );
use List::Util qw( first );
use List::MoreUtils qw( any );
use Scalar::Util qw( blessed refaddr );

# avoid unnecessarily importing constant.pm
sub true()  { !!1 };
sub false() { !!0 };

use overload
	'""'     => 'as_string',
	'+'      => 'union',
	'*'      => 'intersection',
	'%'      => 'symmetric_difference',
	'-'      => 'difference',
	'=='     => 'equal',
	'eq'     => 'equal',
	'!='     => 'not_equal',
	'ne'     => 'not_equal',
	'<'      => 'proper_subset',
	'>'      => 'proper_superset',
	'<='     => 'subset',
	'>='     => 'superset',
	'@{}'    => 'as_array',
	'bool'   =>  sub { 1 },
	fallback => 1;

sub new {
	my $class = shift;
	my %args  = @_;
	
	my $init = delete($args{members});
	my $self = bless {
		equivalence_relation => $class->_build_equivalence_relation(\%args),
		members              => [],
		mutable              => true,
		%args,
	} => $class;
	
	local $self->{mutable} = true;
	$self->insert(@$init) if $init;
	
	return $self;
}

sub equivalence_relation {
	shift->{equivalence_relation};
}

sub type_constraint {
	shift->{type_constraint};
}

sub should_coerce {
	my $self = shift;
	$self->{coerce} and $self->{type_constraint} and $self->{type_constraint}->has_coercion
}

sub is_mutable {
	!! shift->{mutable};
}

sub is_immutable {
	not shift->is_mutable;
}

sub make_immutable {
	my $self = shift;
	$self->{mutable} = false;
	return $self;
}

sub _default_equivalence_relation {
	no warnings 'uninitialized';
	my ($x, $y) = @_;
	
	# If 'eq' says they're not equal, then trust it.
	return false unless $x eq $y;
	
	# However, there are some situations where 'eq'
	# might provide a false positive.
	
	# Undef is not equal to ""
	return false unless !!defined($x) == !!defined($y);

	# A non-overloaded object can never be equal to a string!
	return false if !ref($x) && ref($y) && !overload::Overloaded($y);
	return false if !ref($y) && ref($x) && !overload::Overloaded($x);
	
	# OK then, they're equal!
	return true;
}

sub _build_equivalence_relation { \&_default_equivalence_relation };

sub insert {
	my $self = shift;
	croak "cannot call insert on immutable set"
		unless $self->is_mutable;
	
	my $eq = $self->equivalence_relation;
	my $tc = $self->type_constraint;
	my $sc = $self->should_coerce;
	
	my $count;
	ITEM: while (@_) {
		my $item = $sc ? $tc->coerce(shift @_) : (shift @_);
		$tc->check($item) || croak $tc->get_message($item) if $tc;
		next ITEM if any { $eq->($_, $item) } $self->members;
		push @{$self->{members}}, $item;
		$count++;
	}
	
	return $count;
}

sub _unshift {
	my $self = shift;
	croak "cannot call _unshift on immutable set"
		unless $self->is_mutable;
	
	my $eq = $self->equivalence_relation;
	my $tc = $self->type_constraint;
	my $sc = $self->should_coerce;
	
	my $count;
	ITEM: while (@_) {
		my $item = $sc ? $tc->coerce(pop @_) : (pop @_);
		$tc->check($item) || croak $tc->get_message($item) if $tc;
		next ITEM if any { $eq->($_, $item) } $self->members;
		unshift @{$self->{members}}, $item;
		$count++;
	}
	
	return $count;
}

sub contains {
	my $self = shift;
	
	my $eq = $self->equivalence_relation;
	
	return true unless @_;
	
	ITEM: while (@_) {
		my $item = shift @_;
		return false unless any { $eq->($_, $item) } $self->members;
	}
	
	return true;
}

sub member {
	my $self = shift;
	my $item = $_[0];
	my $eq = $self->equivalence_relation;
	for ($self->members) {
		return $_ if $eq->($_, $item)
	}
	return;
}

sub members {
	my $self = shift;
	@{$self->{members}};
}

sub size {
	my $self = shift;
	scalar @{$self->{members}};
}

sub remove {
	my $self = shift;
	croak "cannot call remove on immutable set"
		unless $self->is_mutable;
	
	my $eq = $self->equivalence_relation;
	
	return 0 unless @_;
	
	my ($count, @new_set) = 0;
	OLD_SET: for my $member ($self->members) {
		REMOVALS: for my $item (@_) {
			if ($eq->($member, $item)) {
				$count++;
				next OLD_SET;
			}
		}
		push @new_set, $member;
	}
	
	@{$self->{members}} = @new_set;
	return $count;
}

sub weaken {
	die "unimplemented";
}

sub is_weak {
	false;
}

sub strengthen {
	$_[0];
}

sub invert {
	my $self = shift;
	croak "cannot call invert on immutable set"
		unless $self->is_mutable;
	
	my ($hasnt, $has) = List::MoreUtils::part { $self->contains($_) } @_;
	
	if (@{$has||[]}) {
		$self->remove(@$has);
	}
	$self->insert(@$hasnt);
}

sub clear {
	my $self = shift;
	croak "cannot call clear on immutable set"
		unless $self->is_mutable;
	
	my $size = $self->size;
	@{$self->{members}} = ();
	return $size;
}

sub as_string {
	my $self = shift;
	"(" . join(" ", sort $self->members) . ")";
}

sub _args
{
	my $n = shift;
	my ($class, @eq, @tc);
	
	if (ref $_[0])
	{
		$class = ref($_[0]);
		@eq = (equivalence_relation => $_[0]->equivalence_relation);
		@tc = (type_constraint => $_[0]->type_constraint) if $_[0]->type_constraint;
	}
	else
	{
		$class = shift;
	}
	
	for (0 .. $n-1) {
		blessed($_[$_]) && $_[$_]->isa($class)
			or croak("expected $class; got $_[$_]");
	}
	
	return (
		sub {
			my @members = @_;
			$class->new(members => \@members, @eq, @tc);
		}, @_
	);
}

sub equal {
	my (undef, $this, $that) = _args 2, @_;
	return true if refaddr($this) == refaddr($that);
	$this->contains($that->members) and $that->contains($this->members);
}

sub not_equal {
	my (undef, $this, $that) = _args 2, @_;
	not $this->equal($that);
}

sub clone {
	my ($maker, $this) = _args 1, @_;
	return $maker->( $this->members );
}

sub intersection {
	my ($maker, $this, $that) = _args 2, @_;
	return $maker->(
		grep $that->contains($_), $this->members
	);
}

sub union {
	my ($maker, $this, $that) = _args 2, @_;
	return $maker->( $this->members, $that->members );
}

sub difference {
	my ($maker, $this, $that) = _args 2, @_;
	my $new = $maker->( $this->members );
	$new->remove($that->members);
	return $new;
}

sub symmetric_difference {
	my ($maker, $this, $that) = _args 2, @_;
	my $new = $maker->( $this->members );
	$new->invert($that->members);
	return $new;
}

sub subset {
	my (undef, $this, $that) = _args 2, @_;
	$that->contains($this->members);
}

sub proper_subset {
	my (undef, $this, $that) = _args 2, @_;
	$that->contains($this->members) and not $this->contains($that->members);
}

sub superset {
	my (undef, $this, $that) = _args 2, @_;
	$this->contains($that->members);
}

sub proper_superset {
	my (undef, $this, $that) = _args 2, @_;
	$this->contains($that->members) and not $that->contains($this->members);
}

sub is_null {
	my $self = shift;
	$self->size == 0;
}

sub compare {
	die "unimplemented";
}

sub is_disjoint {
	my (undef, $this, $that) = _args 2, @_;
	return $this->intersection($that)->is_null;
}

sub as_string_callback {
	die "unimplemented";
}

# Aliases
sub includes { shift->contains(@_) }
sub has      { shift->contains(@_) }
sub element  { shift->member(@_) }
sub elements { shift->members(@_) }
sub delete   { shift->remove(@_) }
sub is_empty { shift->is_null(@_) }

# Exports
BEGIN {
	require Exporter::Tiny;
	push our(@ISA), 'Exporter::Tiny';
	push our(@EXPORT_OK), 'set', 'typed_set';
};
sub set       {                 __PACKAGE__->new(members => \@_,                       ) };
sub typed_set { my $tc = shift; __PACKAGE__->new(members => \@_, type_constraint => $tc) };

# Extra fun
sub as_array {
	my $self = shift;
	my $array = $self->{_array} ||= do {
		require Set::Equivalence::_Tie;
		tie my @arr, 'Set::Equivalence::_Tie', $self;
		\@arr;
	};
	Scalar::Util::weaken($self->{_array}) unless Scalar::Util::isweak($self->{_array});
	return $array;
}

sub iterator {
	my $self = shift;
	my @elements = $self->members;
	return sub { shift @elements };
}

sub map {
	my ($maker, $this, $code) = _args 1, @_;
	shift unless blessed $_[0];
	return $maker->(map $code->($_), $this->members);
}

sub grep {
	my ($maker, $this, $code) = _args 1, @_;
	shift unless blessed $_[0];
	return $maker->(grep $code->($_), $this->members);
}

sub reduce {
	my (undef, $this, $code) = _args 1, @_;
	@_ = ($code, $this->members);
	goto \&List::Util::reduce;
}

sub part {
	my ($maker, $this, $code) = _args 1, @_;
	return map $maker->(@$_), &List::MoreUtils::part($code, $this->members);
}

sub pop {
	my $self = shift;
	croak "cannot call pop on immutable set"
		unless $self->is_mutable;
	return if $self->is_null;
	$self->remove( my $r = $self->{members}[-1] );
	return $r;
}

sub _shift {
	my $self = shift;
	croak "cannot call _shift on immutable set"
		unless $self->is_mutable;
	return if $self->is_null;
	$self->remove( my $r = $self->{members}[0] );
	return $r;
}

set -> is_null

__END__

=pod

=encoding utf-8

=for stopwords user-configurable booleans supersets superset invocant

=head1 NAME

Set::Equivalence - a set of objects or scalars with no duplicates and a user-configurable equivalence relation

=head1 SYNOPSIS

   use v5.12;
   use Set::Equivalence qw(set);
   
   my $numbers = set(1..4) + set(2, 4, 6, 8);
   say for $numbers->members; # 1, 2, 3, 4, 6, 8

=head1 DESCRIPTION

If you're familiar with L<Set::Object> or L<Set::Scalar>, then you should be
right at home with L<Set::Equivalence>.

In mathematical terms, a L<set|http://en.wikipedia.org/wiki/Set_(mathematics)>
is an unordered collection of zero or more members. In computer science, this
translates to a L<set data type|http://en.wikipedia.org/wiki/Set_(abstract_data_type)>
which is much like an array or list, but without ordering and without duplicates.
(Adding an item to a set that is already a member of the set is a no-op.)

Like L<Set::Object> and L<Set::Scalar>, L<Set::Equivalence> sets are 
mutable by default; that is, it's possible to add and remove items after
constructing the set. However, it is possible to mark sets as being
immutable; after doing so, any attempts to modify the set will throw an
exception.

The main distinguishing feature of L<Set::Equivalence> is that it is
possible to define an equivalence relation (a coderef taking two arguments)
which will be used to judge whether two set members are considered
duplicates.

Set::Equivalence expects your coderef to act as a true
L<equivalence relation|http://en.wikipedia.org/wiki/Equivalence_relation>
and may act unexpectedly if it is not. In particular, it expects:

=over

=item *

Reflexivity. In other words for any C<< $x >>, C<< $equiv->($x, $x) >>
is always true.

=item *

Symmetry. In other words for any C<< $x >> and C<< $y >>,
C<< $equiv->($x, $y) >> implies C<< $equiv->($y, $x) >>.

=item *

Transitivity. In other words for any C<< $x >>, C<< $y >> and C<< $z >>,
C<< $equiv->($x, $y) && $equiv->($y, $z) >> implies C<< $equiv->($x, $z) >>.

=item *

Determinism. For any C<< $x >> and C<< $y >>, C<< $equiv->($x, $y) >>
will always return the same thing, at least for the lifetime of the
set object. (If C<< $x >> and C<< $y >> are mutable objects, then
it's easy for an equivalence function to become non-deterministic.)

=back

This approach to implementing a set is unavoidably slow, because it means
we can't use a hash of incoming values to detect duplicates; instead the
equivalence relation needs to be called on each pair of members. However,
performance is generally tolerable for sets of a few dozen members.

The API documented below is roughly compatible with L<Set::Object> and
L<Set::Tiny>.

=begin private

=item element
=item elements
=item delete
=item is_immutable
=item includes
=item has
=item is_empty
=item not_equal
=item false
=item true

=end private

=head2 Constructors

A methods and a function for creating a new set from nothing.

=over

=item C<< new(%attrs) >>

Standard Moose-style constructor function (though this module does not use
Moose). Valid attributes are:

=over

=item I<members>

An initial collection of members to add to the set, provided as an arrayref.
Optional; defaults to none.

=item I<mutable>

Boolean, indicating whether the set should be mutable.
Optional; defaults to true.

=item I<equivalence_relation>

Coderef accepting to arguments.
Optional; defaults to a coderef that checks string equality, but treats
C<undef> differently to C<< "" >>, and handles overloaded objects properly.

=item I<type_constraint>

A type constraint for set members.
Optional; accepts L<Type::Tiny> and L<MooseX::Types> type constraints
(or indeed any object implementing L<Type::API::Constraint>).

=item I<coerce>

Boolean; whether type coercion should be attempted.
Optional; defaults to false. Ignored unless the set has a type constraint
which has coercions.

=back

=item C<< set(@members) >>, C<< typed_set($constraint, @members) >>

Exportable functions (i.e. not a method) that act as shortcuts for C<new>.

Note that this module uses L<Exporter::Tiny>, which allows exported
functions to be renamed.

=item C<< clone >>

Returns a shallow clone of an existing set, with the same members and the
same equivalence function. (The clone will be mutable.)

=back

=head2 Accessors

A methods for accessing the set's data.

=over

=item C<< members >>

Returns all members of the set, as a list.

Alias: C<elements>.

=item C<< size >>

Returns the set cardinality (i.e. a count of the members).

=item C<< member($member) >>

Returns $member if it is a member of the set; returns undef otherwise.
(Of course, undef may be a member of the set!) In list context, returns
an empty list if the member is not a member of the set.

Alias: C<element>.

=item C<< equivalence_relation >>

Returns the equivalence relation coderef.

=item C<< type_constraint >>

Returns the type constraint (if any).

=back

=head2 Predicates

Methods returning booleans.

=over

=item C<< is_mutable >>

Returns true iff the set is mutable.

Negated: C<is_immutable>.

=item C<< is_null >>

Returns true iff the set is empty.

Alias: C<is_empty>.

=item C<< is_weak >>

Implemented for compatibility with L<Set::Object>. Always returns false.

=item C<< contains(@members) >>

Returns a boolean indicating whether all C<< @members >> are members of the
set.

Alias: C<includes>, C<has>.

=item C<< should_coerce >>

Returns true iff this set will attempt type coercion of incoming members.

=back

=head2 Mutators

Methods that alter the contents or behaviour of the set.

=over

=item C<< insert(@members) >>

Adds members to the set. Returns the number of new members added (i.e.
that were not already members).

Throws an exception if the set is immutable.

=item C<< remove(@members) >>

Removes members from the set. Returns the number of members removed.
Any members not found in the set are ignored.

Throws an exception if the set is immutable.

Alias: C<delete>.

=item C<< invert(@members) >>

For each argument: if it already exists in the set, removes it; otherwise,
adds it.

Throws an exception if the set is immutable.

=item C<< clear >>

Empties the set. Significantly faster than C<remove>.

Throws an exception if the set is immutable.

=item C<< pop >>

Removes an arbitrary member from the set and returns it.

Throws an exception if the set is immutable.

=item C<< make_immutable >>

Converts the set to an immutable one.

Returns the invocant, which means this method is suitable for chaining.

   my $even_primes = set(2)->make_immutable;

=item C<< weaken >>

Unimplemented.

=item C<< strengthen >>

Ignored.

=back

=head2 Comparison

The following methods can be called as object methods with a single
parameter, or class methods with two parameters:

   $set1->equal($set2);
   # or:
   'Set::Equivalent'->equal($set1, $set2);

=over

=item C<< equal($set1, $set2) >> 

Returns true iff all members of C<< $set1 >> occur in C<< $set2 >> and
all members of C<< $set2 >> occur in C<< $set1 >>.

Negated: C<not_equal>.

=item C<< subset($set1, $set2) >>

Returns true iff all members of C<< $set1 >> occur in C<< $set2 >>. That is,
if C<< $set1 >> is a subset of C<< $set2 >>.

=item C<< superset($set1, $set2) >>

Returns true iff all members of C<< $set2 >> occur in C<< $set1 >>. That is,
if C<< $set2 >> is a subset of C<< $set1 >>.

=item C<< proper_subset($set1, $set2) >>, C<< proper_superset($set1, $set2) >>

Sets that are equal are trivially subsets and supersets of each other.
These methods return false if the sets are equal, but otherwise return
the same as C<subset> and C<superset>.

=item C<< is_disjoint($set1, $set2) >>

Returns true iff the sets have no elements in common.

=item C<< compare >>

Unimplemented.

=back

=head2 Arithmetic

The following methods can be called as object methods with a single
parameter, or class methods with two parameters:

   $set1->union($set2);
   # or:
   'Set::Equivalent'->union($set1, $set2);

They all return mutable sets. If called as an object method, the returned
sets have the same equivalence relation and type constraint as the set
given in the first argument; if called as a class method, the returned sets
have the default equivalence relation and no type constraint.

=over

=item C<< intersection($set1, $set2) >>

Returns the set which is the largest common subset of both sets.

=item C<< union($set1, $set2) >>

Returns the set which is the smallest common superset of both sets.

=item C<< difference($set1, $set2) >>

Returns a copy of C<< $set1 >> with all members of C<< $set2 >> removed.

=item C<< symmetric_difference($set1, $set2) >>

Returns a copy of the union with all members of the intersection removed.

=item C<< map($set1, $coderef) >>

Returns a new set created by passing each member of C<< $set1 >> through
a coderef.

See also C<map> in L<perlfunc>.

=item C<< grep($set1, $coderef) >>

Returns a new set created by filtering each member of C<< $set1 >> by
a coderef that should return a boolean.

See also C<grep> in L<perlfunc>.

=item C<< part($set1, $coderef) >>

Returns a list of sets created by partitioning C<< $set1 >> by a coderef
that should return an integer.

See also C<part> in L<List::MoreUtils>.

=back

=head2 Miscellaneous Methods

=over

=item C<< as_string >>

A basic string representation of the set.

=item C<< as_string_callback >>

Unimplemented.

=item C<< as_array >>

Returns a reference to a tied array that can be used to iterate through
the set members, C<push> new members onto, and C<pop> members off.

The order of members in the array is arbitrary.

L<Set::Equivalent::_Tie> does not implement the entire L<Tie::Array>
interface, so some bits will crash. In particular, STORE operations are
not implemented, so you can't do C<< $set->as_array->[1] = 42 >>.
C<splice>, C<exists> and C<delete> will probably also fail. (But
C<exists> and C<delete> on array elements are insane anyway.)

=item C<< iterator >>

Returns an iterator that will walk through the current members of the set.

=item C<< reduce($set, $coderef) >>

Reduces the set to a single value.

See also C<reduce> in L<List::Util>.

=back

=head2 Overloaded Operators

   '""'     => 'as_string',
   '+'      => 'union',
   '*'      => 'intersection',
   '%'      => 'symmetric_difference',
   '-'      => 'difference',
   '=='     => 'equal',
   'eq'     => 'equal',
   '!='     => 'not_equal',
   'ne'     => 'not_equal',
   '<'      => 'proper_subset',
   '>'      => 'proper_superset',
   '<='     => 'subset',
   '>='     => 'superset',
   '@{}'    => 'as_array',
   'bool'   =>  sub { 1 },

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Set-Equivalence>.

=head1 SEE ALSO

L<Types::Set>.

L<Set::Object>, L<Set::Scalar>, L<Set::Tiny>.

L<List::Objects::WithUtils>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

