package MooseX::RemoteHelper::Meta::Trait::Role::Composite;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.001021'; # VERSION

use Moose::Role;

around apply_params => sub {
	my $orig = shift;
	my $self = shift;

	$self->$orig(@_);

	$self = Moose::Util::MetaRole::apply_metaroles(
		for => $self,
		role_metaroles => {
			application_to_class =>
				['MooseX::RemoteHelper::Meta::Trait::Role::ApplicationToClass'],
			application_to_role =>
				['MooseX::RemoteHelper::Meta::Trait::Role::ApplicationToRole'],
		}
	);
	return $self;
};

1;

# ABSTRACT: called by MooseX::RemoteHelper::Meta::Trait::Role

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::RemoteHelper::Meta::Trait::Role::Composite - called by MooseX::RemoteHelper::Meta::Trait::Role

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
