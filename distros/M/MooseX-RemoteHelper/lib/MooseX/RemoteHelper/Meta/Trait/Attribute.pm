package MooseX::RemoteHelper::Meta::Trait::Attribute;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.001021'; # VERSION

use Moose::Role;
Moose::Util::meta_attribute_alias 'RemoteHelper';

has remote_name => (
	predicate => 'has_remote_name',
	isa       => 'Str',
	is        => 'ro',
);

has serializer => (
	predicate => 'has_serializer',
	traits    => ['Code'],
	is        => 'ro',
	reader    => undef,
	handles   => {
		serializing => 'execute_method',
	},
);

sub serialized {
	my ( $self, $instance ) = @_;

	return $self->has_serializer
		? $self->serializing( $instance )
		: $self->get_value( $instance )
		;
}

around initialize_instance_slot => sub {
	my $orig = shift;
	my $self = shift;

	my ( $meta_instance, $instance, $params ) = @_;

	return $self->$orig(@_)
		unless $self->has_remote_name ## no critic ( ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions )
			&& $self->has_init_arg
			&& $self->remote_name ne $self->init_arg
			;

	$params->{ $self->init_arg }
		= delete   $params->{ $self->remote_name }
		if defined $params->{ $self->remote_name }
		;

	$self->$orig(@_);
};

1;

# ABSTRACT: role applied to meta attribute

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::RemoteHelper::Meta::Trait::Attribute - role applied to meta attribute

=head1 VERSION

version 0.001021

=head1 ATTRIBUTES

=head2 remote_name

the name of the attribute key on the remote host. if no C<remote_name> is
provided it should be assumed that the attribute is not used on the remote but
is instead local only. L<MooseX::RemoteHelper::CompositeSerialization> will
not serialize an attribute that doesn't have a C<remote_name>

	has perlish => (
		isa         => 'Str',
		remote_name => 'MyReallyJavaIshKey',
		is          => 'ro',
	);

=head2 serializer

a code ref for converting the real value to what the remote host expects. it
requires that you pass the attribute and the instance. e.g.

	has foo_bar => (
		isa         => 'Bool',
		remote_name => 'FooBar',
		serializer  => sub {
			my ( $attr, $instance ) = @_;
			return $attr->get_value( $insance ) ? 'T' : 'F';
		},
	);

=head1 METHODS

=head2 serialized

returns the attributed value by using the L<serializer|/serializer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/moosex-remotehelper/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::RemoteHelper|MooseX::RemoteHelper>

=back

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
