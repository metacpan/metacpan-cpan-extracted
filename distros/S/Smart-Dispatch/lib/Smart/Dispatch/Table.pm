package Smart::Dispatch::Table;

BEGIN {
	*_TYPES = $ENV{PERL_SMART_DISPATCH_TYPE_CHECKS}==42
		? sub () { 1 }
		: sub () { 0 };
};

use 5.010;
use Moo;
use Carp;
use Scalar::Util qw/ refaddr blessed /;
use if _TYPES, 'MooX::Types::MooseLike::Base', ':all';

sub _swap
{
	my ($x, $y, $swap) = @_;
	$swap ? ($y, $x) : ($x, $y);
}

use namespace::clean;

BEGIN {
	$Smart::Dispatch::Table::AUTHORITY = 'cpan:TOBYINK';
	$Smart::Dispatch::Table::VERSION   = '0.006';
}

use overload
	'&{}'    => sub { my $x=shift; sub { $x->action($_[0]) } },
	'+'      => sub { __PACKAGE__->make_combined(reverse _swap(@_)) },
	'.'      => sub { __PACKAGE__->make_combined(_swap(@_)) },
	'+='     => 'prepend',
	'.='     => 'append',
	'~~'     => 'exists',
	'bool'   => sub { 1 },
;

has match_list => (
	(_TYPES?(isa=>ArrayRef()):()),
	is        => 'rw',
	required  => 1,
);

sub BUILD
{
	my ($self) = @_;
	$self->validate_match_list;
}

sub make_combined
{
	my ($class, @all) = @_;
	my $self = $class->new(match_list => []);
	$self->append(@all);
}

sub validate_match_list
{
	my ($self) = @_;
	my @otherwise = $self->unconditional_matches;
	if (scalar @otherwise > 1)
	{
		carp "Too many 'otherwise' matches. Only one allowed.";
	}
	if (@otherwise and refaddr($otherwise[0]) != refaddr($self->match_list->[-1]))
	{
		carp "The 'otherwise' match is not the last match.";
	}
}

sub all_matches
{
	my ($self) = @_;
	@{ $self->match_list };
}

sub unconditional_matches
{
	my ($self) = @_;
	grep { $_->is_unconditional } @{ $self->match_list };
}

sub conditional_matches
{
	my ($self) = @_;
	grep { !$_->is_unconditional } @{ $self->match_list };
}

sub exists
{
	my ($self, $value, $allow_fails) = @_;
	foreach my $cond (@{ $self->match_list })
	{
		if ($cond->value_matches($value))
		{
			if ($allow_fails or not $cond->is_failover)
			{
				return $cond;
			}
			else
			{
				return;
			}
		}
	}
	return;
}

sub action
{
	my ($self, $value, @args) = @_;
	my $cond = $self->exists($value, 1);
	return $cond->conduct_dispatch($value, @args) if $cond;
	return;
}

sub append
{
	my $self = shift;
	foreach my $other (@_)
	{
		next unless defined $other;
		carp "Cannot add non-reference to dispatch table"
			unless ref $other;
		carp "Cannot add non-blessed reference to dispatch table"
			unless blessed $other;
		
		if ($other->isa(__PACKAGE__))
		{
			$self->match_list([
				$self->conditional_matches,
				$other->conditional_matches,
				($self->unconditional_matches ? $self->unconditional_matches : $other->unconditional_matches),
			]);
		}
		elsif ($other->isa('Smart::Dispatch::Match')
		and not $other->is_unconditional)
		{
			$self->match_list([
				$self->conditional_matches,
				$other,
				$self->unconditional_matches,
			]);
		}
		elsif ($other->isa('Smart::Dispatch::Match')
		and $other->is_unconditional)
		{
			$self->match_list([
				$self->conditional_matches,
				($self->unconditional_matches ? $self->conditional_matches : $other),
			]);
		}
		else
		{
			carp sprintf("Cannot add object of type '%s' to dispatch table", ref $other);
		}
	}
	
	$self->validate_match_list;
	return $self;
}

sub prepend
{
	my $self = shift;
	foreach my $other (@_)
	{
		next unless defined $other;
		carp "Cannot add non-reference to dispatch table"
			unless ref $other;
		carp "Cannot add non-blessed reference to dispatch table"
			unless blessed $other;
		
		if ($other->isa(__PACKAGE__))
		{
			$self->match_list([
				$other->conditional_matches,
				$self->conditional_matches,
				($other->unconditional_matches ? $other->unconditional_matches : $self->unconditional_matches),
			]);
		}
		elsif ($other->isa('Smart::Dispatch::Match')
		and not $other->is_unconditional)
		{
			$self->conditions([
				$other,
				$self->conditional_matches,
				$self->unconditional_matches,
			]);
		}
		elsif ($other->isa('Smart::Dispatch::Match')
		and $other->is_unconditional)
		{
			$self->conditions([
				$self->conditional_matches,
				$other,
			]);
		}
		else
		{
			carp sprintf("Cannot add object of type '%s' to dispatch table", ref $other);
		}
	}
	
	$self->validate_match_list;
	return $self;
}

__PACKAGE__
__END__

=head1 NAME

Smart::Dispatch::Table - a dispatch table

=head1 DESCRIPTION

Smart::Dispatch::Table is a Moose class.
(Well, L<Moo> actually, but close enough.)

=head2 Constructors

=over

=item * C<< new(%attributes) >>

Create a new dispatch table.

=item * C<< make_combined($table1, $table2, ...) >> 

Combine existing tables into a new one.

=back

=head2 Attributes

=over

=item * C<match_list>

is 'rw', isa 'ArrayRef[Smart::Dispatch::Match]'.

=back

=head2 Methods

=over

=item * C<< exists($value, $include_failovers) >>

Searches for a Smart::Dispatch::Match that matches C<$value>. Ignores
failover matches, unless optional argument C<$include_failovers> is
true. Returns Smart::Dispatch::Match if it finds a match; returns nothing
otherwise.

TL;DR: checks if value C<$value> can be dispatched.

=item * C<< action($value, @additional) >>

Calls C<exists> with C<$include_failovers> set to true, then, if there
is a result, calls C<< conduct_dispatch($value, @additional) >> on that
result.

TL;DR: dispatches value C<$value>.

=item * C<conditional_matches>

Returns a list of conditional matches. (Smart::Dispatch::Match objects.)

=item * C<unconditional_matches>

Returns a list of unconditional matches. (Smart::Dispatch::Match objects.)

Should only ever be zero or one items in the list.

=item * C<all_matches>

Returns the list which is the union of the above two lists.

=item * C<< append(@things) >>

Each thing must be a Smart::Dispatch::Table or a Smart::Dispatch::Match.

Handles conflicts between unconditional matches automatically.

=item * C<< prepend(@things) >>

Each thing must be a Smart::Dispatch::Table or a Smart::Dispatch::Match.

Handles conflicts between unconditional matches automatically.

=item * C<validate_match_list>

Checks that match_list looks OK (a maximum of unconditional match;
checks that all conditional matches preceed unconditional matches).

This is done automatically after construction, prepending and
appending, but if you've manipulated the match_list manually, it's
good practice to all this method to check you've not broken it.

=back

=begin private

=item BUILD

=end private

=head2 Overloads

Smart::Dispatch::Table overloads various operations. (See L<overload>.)

=over

=item * B<< code derefernce >> C<< &{} >> - funky stuff with C<action>.

=item * B<< concatenation >> C<< . >> - funky stuff with C<make_combined>.

=item * B<< addition >> C<< + >> - funky stuff with C<make_combined>.

=item * B<< concatenation assignment >> C<< .= >> - C<append>.

=item * B<< addition assignment >> C<< += >> - C<prepend>.

=item * B<< smart match >> C<< ~~ >> - C<exists> (with C<$ignore_failover> false).

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Smart-Dispatch>.

=head1 SEE ALSO

L<Smart::Dispatch>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

