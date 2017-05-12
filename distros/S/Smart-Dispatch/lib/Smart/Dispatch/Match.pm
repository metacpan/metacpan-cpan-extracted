package Smart::Dispatch::Match;

BEGIN {
	*_TYPES = $ENV{PERL_SMART_DISPATCH_TYPE_CHECKS}==42
		? sub () { 1 }
		: sub () { 0 };
};

use 5.010;
use Moo;
use Carp;
use if _TYPES, 'MooX::Types::MooseLike::Base', ':all';

use namespace::clean;

BEGIN {
	$Smart::Dispatch::Match::AUTHORITY = 'cpan:TOBYINK';
	$Smart::Dispatch::Match::VERSION   = '0.006';
}

use constant {
	FLAG_HAS_VALUE         =>  2,
	FLAG_HAS_DISPATCH      =>  4,
	FLAG_IS_FAILOVER       =>  8,
	FLAG_IS_UNCONDITIONAL  => 16,
};

use overload
	'&{}'    => sub { my $x=shift; sub { $x->conduct_dispatch($_[0]) } },
	'~~'     => 'value_matches',
	bool     => sub { 1 },
;

has test => (
	(_TYPES?(isa=>Any()):()),
	is        => 'ro',
	required  => 1,
);

has dispatch => (
	(_TYPES?(isa=>CodeRef()):()),
	is        => 'ro',
	required  => 0,
	predicate => 'has_dispatch',
);

has value => (
	(_TYPES?(isa=>Any()):()),
	is        => 'ro',
	required  => 0,
	predicate => 'has_value',
);

has note => (
	(_TYPES?(isa=>Str()):()),
	is        => 'ro',
	required  => 0,
);

has bitflags => (
	(_TYPES?(isa=>Num()):()),
	is        => 'lazy',
	init_arg  => undef,
);

has is_failover => (
	(_TYPES?(isa=>Bool()):()),
	is        => 'ro',
	required  => 1,
	default   => sub { 0 },
);

has is_unconditional => (
	(_TYPES?(isa=>Bool()):()),
	is        => 'ro',
	required  => 1,
	default   => sub { 0 },
);

sub _build_bitflags
{
	my ($self) = @_;
	my $rv = 1;
	$rv += FLAG_HAS_VALUE         if $self->has_value;
	$rv += FLAG_HAS_DISPATCH      if $self->has_dispatch;
	$rv += FLAG_IS_FAILOVER       if $self->is_failover;
	$rv += FLAG_IS_UNCONDITIONAL  if $self->is_unconditional;
	return $rv;
}

sub value_matches
{
	my ($self, $value) = @_;
	local $_ = $value;
	no warnings; # stupid useless warnings below
	return ($value ~~ $self->test);
}

sub conduct_dispatch
{
	my ($self, $value, @args) = @_;
	local $_ = $value;
	if ($self->has_dispatch)
	{
		return $self->dispatch->($value, @args);
	}
	elsif ($self->has_value)
	{
		return $self->value;
	}
	else
	{
		return;
	}
}

__PACKAGE__
__END__

=head1 NAME

Smart::Dispatch::Match - an entry in a dispatch table

=head1 DESCRIPTION

Smart::Dispatch::Match is a Moose class.
(Well, L<Moo> actually, but close enough.)

=head2 Constructor

=over

=item * C<< new(%attributes) >>

Create a new entry.

=back

=head2 Attributes

=over

=item * C<test>

is 'ro', required.

=item * C<dispatch>

is 'ro', isa 'CodeRef', predicate C<has_dispatch>.

=item * C<value>

is 'ro', predicate C<has_value>.

=item * C<note>

is 'ro', isa 'Str'.

=item * C<is_failover>

is 'ro', isa 'Bool', required, default false.

=item * C<is_unconditional>

is 'ro', isa 'Bool', required, default false.

=back

=head2 Methods

=over

=item * C<< value_matches($value) >>

Perform a smart match between C<$value> and the C<test> attribute.

=item * C<< conduct_dispatch(@args) >>

If the Match object has a dispatch coderef, then calls it, passing
C<< @args >> as arguments, and passing through the return value.

Else if the Match object has a value, just returns it.

Otherwise returns nothing.

=item * C<bitflags>

Returns a number representing what sort of match this is (conditional,
failover, etc), suitable for bitwise operations with the constants
defined by this module.

=back

=head2 Constants

=over

=item * C<FLAG_HAS_VALUE>

=item * C<FLAG_HAS_DISPATCH>

=item * C<FLAG_IS_FAILOVER>

=item * C<FLAG_IS_UNCONDITIONAL>

=back

=head2 Overloads

Smart::Dispatch::Match overloads various operations. (See L<overload>.)

=over

=item * B<< code derefernce >> C<< &{} >> - C<conduct_dispatch>.

=item * B<< smart match >> C<< ~~ >> - C<value_matches>.

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

