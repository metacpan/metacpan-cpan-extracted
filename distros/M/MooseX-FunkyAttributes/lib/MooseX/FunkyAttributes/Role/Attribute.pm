package MooseX::FunkyAttributes::Role::Attribute;

use 5.008;
use strict;
use warnings;

BEGIN {
	$MooseX::FunkyAttributes::Role::Attribute::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::FunkyAttributes::Role::Attribute::VERSION   = '0.003';
}

use Moose::Role;

use aliased 'MooseX::FunkyAttributes::Meta::Accessor';
use namespace::autoclean;

has custom_get => (
	is         => 'ro',
	isa        => 'CodeRef',
	required   => 1,
);

has custom_set => (
	is         => 'ro',
	isa        => 'CodeRef',
	required   => 1,
);

has custom_has => (
	is         => 'ro',
	isa        => 'CodeRef',
	required   => 1,
);

has custom_clear => (
	is         => 'ro',
	isa        => 'CodeRef',
	predicate  => 'has_custom_clear',
);

has custom_weaken => (
	is         => 'ro',
	isa        => 'CodeRef',
	predicate  => 'has_custom_weaken',
);

has custom_init => (
	is         => 'ro',
	isa        => 'CodeRef',
	predicate  => 'has_custom_init',
);

my @i = qw( set get weaken has clear );
for my $i (@i)
{
	my $non_inline = "custom_$i";
	my $custom     = "custom_inline_$i";
	my $has_custom = "has_$custom";
	has $custom => (
		is        => 'ro',
		isa       => 'CodeRef',
		predicate => $has_custom,
	);
	
	my $guts_method =
		( $i =~ /^(weaken|clear)$/ )
			? "_inline_${i}_value"
			: "_inline_instance_${i}";
	
	around $guts_method => sub
	{
		my $next = shift;
		my $self = shift;
		my ($instance_var, $param_var) = @_;
		
		return $self->$custom->($self, @_) if $self->$has_custom;
		
		return sprintf(
			'do { my $attr = Moose::Util::find_meta(ref(%s))->get_attribute(%s); local $_ = %s; $attr->%s->($attr'.join('',map(',%s',@_)).') }',
			$instance_var,
			B::perlstring($self->name),
			$instance_var,
			$non_inline,
			@_,
		);
	};
}

around _inline_weaken_value => sub
{
	my ($orig, $self, @args) = @_;
	return unless $self->is_weak_ref;
	$self->$orig(@args);
};

has has_all_inliners => (
	is         => 'ro',
	isa        => 'Bool',
	lazy_build => 1,
);

sub _build_has_all_inliners
{
	my $self = shift;
	for (@i) {
		my $predicate = "has_custom_inline_$_";
		return unless $self->$predicate;
	}
	return 1;
}

sub accessor_should_be_inlined
{
	shift->has_all_inliners;
}

after _process_options => sub
{
	my ($class, $name, $options) = @_;
	
	if (defined $options->{clearer}
	and not defined $options->{custom_clear})
	{
		confess "can't set clearer without custom_clear";
	}

	if ($options->{weak_ref}
	and not defined $options->{custom_weaken})
	{
		confess "can't set weak_ref without custom_weaken";
	}
};

override accessor_metaclass => sub { Accessor };

override get_raw_value => sub
{
	my ($attr) = @_;
	local $_ = $_[1];
	return $attr->custom_get->(@_);
};

override set_raw_value => sub
{
	my ($attr) = @_;
	local $_ = $_[1];
	return $attr->custom_set->(@_);
};

override has_value => sub
{
	my ($attr) = @_;
	local $_ = $_[1];
	return $attr->custom_has->(@_);
};

override clear_value => sub
{
	my ($attr) = @_;
	local $_ = $_[1];
	return $attr->custom_clear->(@_);
};

override _weaken_value => sub
{
	my ($attr) = @_;
	local $_ = $_[1];
	return $attr->custom_weaken->(@_);
};

override set_initial_value => sub
{
	my ($attr) = @_;
	local $_ = $_[1];
	if ($attr->has_custom_init) {
		return $attr->custom_init->(@_);
	}
	return $attr->custom_set->(@_);
};

1;

__END__

=head1 NAME

MooseX::FunkyAttributes::Role::Attribute - custom get/set/clear/has coderefs

=head1 SYNOPSIS

   package Circle;
   
   use Moose;
   use MooseX::FunkyAttributes;
   
   has radius => (
      is          => 'rw',
      isa         => 'Num',
      predicate   => 'has_radius',
   );
   
   has diameter => (
      traits      => [ FunkyAttribute ],
      is          => 'rw',
      isa         => 'Num',
      custom_get  => sub { 2 * $_->radius },
      custom_set  => sub { $_->radius( $_[-1] / 2 ) },
      custom_has  => sub { $_->has_radius },
   );

=head1 DESCRIPTION

This is the base trait which the other MooseX::FunkyAttribute traits inherit
from. It allows you to provide coderefs to handle the business of storing and
retrieving attribute values.

So instead of storing your attribute values in the object's blessed hashref,
you could calculate them on the fly, or store them in a file or database, or
an external hashref, or whatever.

=head2 Options

If your attribute uses this trait, then you I<must> provide at least the
following three coderefs:

=over

=item C<< custom_set => CODE ($meta, $instance, $value) >>

The code which implements setting an attribute value. Note that this code
does I<not> need to implement type constraint checks, etc. C<< $meta >> is a
L<Moose::Meta::Attribute> object describing the attribute; C<< $instance >>
is the object itself.

C<< $_ >> is available as an alias for the instance.

=item C<< custom_get => CODE ($meta, $instance) >>

The code which implements getting an attribute value. 

It should return the value.

=item C<< custom_has => CODE ($meta, $instance) >>

The code which implements the predicate functionality for an attribute. That
is, it should return true if the attribute has been set, and false if the
attribute is unset. (Note that Moose does allow attribute values to be set to
undefined, so settedness is not the same as definedness.)

=back

The following three additional coderefs are optional:

=over

=item C<< custom_clear => CODE ($meta, $instance) >>

The code which clears an attribute value, making it unset.

If you do not provide this, then your attribute cannot be cleared once set.

=item C<< custom_init => CODE ($meta, $instance, $value) >>

Like C<custom_set> but used during object construction.

If you do not provide this, then the C<custom_set> coderef will be used in its
place.

=item C<< custom_weaken => CODE ($meta, $instance) >>

The code which weakens an attribute value that is a reference.

If you do not provide this, then your attribute cannot be a weak ref.

=back

Moose attempts to create inlined attribute accessors whenever possible. The
following coderefs can be defined which must return strings of Perl code
suitable for inlining the accessors. They are each optional, but unless all
of them are defined, your attribute will not be inlined.

=over

=item C<< custom_inline_set => CODE ($meta, $instance_string, $value_string) >>

C<< $instance_string >> is a string representing the name of the instance
variable, such as C<< "\$self" >>. C<< $value_string >> is a string which
evaluates to the value.

An example for the C<diameter> example in the SYNOPSIS

   custom_inline_set => sub {
      my ($meta, $i, $v) = @_;
      return sprintf('%s->{radius} = (%s)/2', $i, $v);
   },

=item C<< custom_inline_get => CODE ($meta, $instance_string) >>

An example for the C<diameter> example in the SYNOPSIS

   custom_inline_get => sub {
      my ($meta, $i) = @_;
      return sprintf('%s->{radius} * 2', $i);
   },

=item C<< custom_inline_has => CODE ($meta, $instance_string) >>

An example for the C<diameter> example in the SYNOPSIS

   custom_inline_has => sub {
      my ($meta, $i) = @_;
      return sprintf('exists %s->{radius}', $i);
   },

=item C<< custom_inline_clear => CODE ($meta, $instance_string) >>

An example for the C<diameter> example in the SYNOPSIS

   custom_inline_has => sub {
      my ($meta, $i) = @_;
      return sprintf('delete %s->{radius}', $i);
   },

=item C<< custom_inline_weaken => CODE ($meta, $instance_string) >>

An example for the C<diameter> example in the SYNOPSIS

   custom_inline_has => sub {
      my ($meta, $i) = @_;
      return sprintf('Scalar::Util::weaken(%s->{radius})', $i);
   },

(Not that weakening a Num makes any sense...)

=back

Your attribute metaobject has the following methods (in addition to the
standard L<Moose::Meta::Attribute> stuff):

=over

=item C<custom_get>

=item C<custom_set>

=item C<custom_has>

=item C<custom_clear>, C<has_custom_clear>

=item C<custom_weaken>, C<has_custom_weaken>

=item C<custom_init>, C<has_custom_init>

=item C<custom_inline_get>, C<has_custom_inline_get>

=item C<custom_inline_set>, C<has_custom_inline_set>

=item C<custom_inline_has>, C<has_custom_inline_has>

=item C<custom_inline_clear>, C<has_custom_inline_clear>

=item C<custom_inline_weaken>, C<has_custom_inline_weaken>

=item C<accessor_should_be_inlined>

=item C<has_all_inliners>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-FunkyAttributes>.

=head1 SEE ALSO

L<MooseX::FunkyAttributes>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

