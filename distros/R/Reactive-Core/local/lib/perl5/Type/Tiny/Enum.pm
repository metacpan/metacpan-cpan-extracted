package Type::Tiny::Enum;

use 5.006001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::Enum::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::Enum::VERSION   = '1.000000';
}

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

use overload q[@{}] => 'values';

use Type::Tiny ();
our @ISA = 'Type::Tiny';

sub new
{
	my $proto = shift;
	
	my %opts = (@_==1) ? %{$_[0]} : @_;
	_croak "Enum type constraints cannot have a parent constraint passed to the constructor" if exists $opts{parent};
	_croak "Enum type constraints cannot have a constraint coderef passed to the constructor" if exists $opts{constraint};
	_croak "Enum type constraints cannot have a inlining coderef passed to the constructor" if exists $opts{inlined};
	_croak "Need to supply list of values" unless exists $opts{values};
	
	my %tmp =
		map { $_ => 1 }
		@{ ref $opts{values} eq "ARRAY" ? $opts{values} : [$opts{values}] };
	$opts{values} = [sort keys %tmp];
	
	if (Type::Tiny::_USE_XS and not grep /[^-\w]/, @{$opts{values}})
	{
		my $enum = join ",", @{$opts{values}};
		my $xsub = Type::Tiny::XS::get_coderef_for("Enum[$enum]");
		$opts{compiled_type_constraint} = $xsub if $xsub;
	}
	
	return $proto->SUPER::new(%opts);
}

sub values      { $_[0]{values} }
sub constraint  { $_[0]{constraint} ||= $_[0]->_build_constraint }

sub _build_display_name
{
	my $self = shift;
	sprintf("Enum[%s]", join q[,], @$self);
}

sub _build_constraint
{
	my $self = shift;
	
	my $regexp = join "|", map quotemeta, @$self;
	return sub { defined and m{\A(?:$regexp)\z} };
}

sub can_be_inlined
{
	!!1;
}

sub inline_check
{
	my $self = shift;
	
	if (Type::Tiny::_USE_XS)
	{
		my $enum = join ",", @{$self->values};
		my $xsub = Type::Tiny::XS::get_subname_for("Enum[$enum]");
		return "$xsub\($_[0]\)" if $xsub;
	}
	
	my $regexp = join "|", map quotemeta, @$self;
	$_[0] eq '$_'
		? "(defined and !ref and m{\\A(?:$regexp)\\z})"
		: "(defined($_[0]) and !ref($_[0]) and $_[0] =~ m{\\A(?:$regexp)\\z})";
}

sub _instantiate_moose_type
{
	my $self = shift;
	my %opts = @_;
	delete $opts{parent};
	delete $opts{constraint};
	delete $opts{inlined};
	require Moose::Meta::TypeConstraint::Enum;
	return "Moose::Meta::TypeConstraint::Enum"->new(%opts, values => $self->values);
}

sub has_parent
{
	!!1;
}

sub parent
{
	require Types::Standard;
	Types::Standard::Str();
}

sub validate_explain
{
	my $self = shift;
	my ($value, $varname) = @_;
	$varname = '$_' unless defined $varname;
	
	return undef if $self->check($value);
	
	require Type::Utils;
	!defined($value) ? [
		sprintf(
			'"%s" requires that the value is defined',
			$self,
		),
	] :
	@$self < 13 ? [
		sprintf(
			'"%s" requires that the value is equal to %s',
			$self,
			Type::Utils::english_list(\"or", map B::perlstring($_), @$self),
		),
	] :
	[
		sprintf(
			'"%s" requires that the value is one of an enumerated list of strings',
			$self,
		),
	];
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny::Enum - string enum type constraints

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

Enum type constraints.

This package inherits from L<Type::Tiny>; see that for most documentation.
Major differences are listed below:

=head2 Attributes

=over

=item C<values>

Arrayref of allowable value strings. Non-string values (e.g. objects with
overloading) will be stringified in the constructor.

=item C<constraint>

Unlike Type::Tiny, you I<cannot> pass a constraint coderef to the constructor.
Instead rely on the default.

=item C<inlined>

Unlike Type::Tiny, you I<cannot> pass an inlining coderef to the constructor.
Instead rely on the default.

=item C<parent>

Parent is always Types::Standard::Str, and cannot be passed to the
constructor.

=back

=head2 Overloading

=over

=item *

Arrayrefification calls C<values>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>.

L<Moose::Meta::TypeConstraint::Enum>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

