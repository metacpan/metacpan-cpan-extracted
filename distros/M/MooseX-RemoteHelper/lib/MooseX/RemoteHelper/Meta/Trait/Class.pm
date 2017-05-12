package MooseX::RemoteHelper::Meta::Trait::Class;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.001021'; # VERSION

use Moose::Role;

around _inline_slot_initializer => sub {
	my $orig = shift;
	my $self = shift;
	my ( $attr, $index ) = @_;

	my @orig_source = $self->$orig(@_);

	return @orig_source
		unless $attr->meta->can('does_role')
			&& $attr->meta->does_role('MooseX::RemoteHelper::Meta::Trait::Attribute')
			;

	return $self->$orig(@_)
		unless $attr->has_remote_name ## no critic ( ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions )
			&& $attr->has_init_arg
			&& $attr->remote_name ne $attr->init_arg
			;

	my $init_arg = $attr->init_arg;

	return (
		' $params->{' . $init_arg . '} '
		. ' = delete $params->{' .  $attr->remote_name . '} '
		. ' if defined $params->{' . $attr->remote_name . '}; '
		, @orig_source
		)
		;
};

1;
# ABSTRACT: meta class for immutable objects

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::RemoteHelper::Meta::Trait::Class - meta class for immutable objects

=head1 VERSION

version 0.001021

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
