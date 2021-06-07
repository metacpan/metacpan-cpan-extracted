package Mojo::Promise::Role::None;
use Mojo::Base '-role';

use strict;

our $VERSION = '1.005';

=encoding utf8

=head1 NAME

Mojo::Promise::Role::Any - Fulfill when all of the promises are rejected

=head1 SYNOPSIS

	use Mojo::Promise;

	my $none_promise = Mojo::Promise
		->with_roles( '+None' )
		->none( @promises );

=head1 DESCRIPTION

Make a new promise that fulfills when all promises are rejected, and
rejects otherwise.

=over 4

=item none( @promises )

Takes a lists of promises (or thenables) and returns another promise
that fulfills when all of the promises are rejected.

If none of the promises reject, the none promise rejects. If all of the
promises resolve then this is rejected.

If you pass no promises, the none promise fulfills.

=cut

sub none {
	my( $self, @promises ) = @_;
	my $none = $self->new;

	my $count = 0;
	$_->then(
		sub { $none->reject( @_ ); return },
		sub { $count++; $none->resolve if $count == @promises; return }
		) foreach @promises;

	return @promises ? $none : $none->resolve;
	}

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Promise>, L<Role::Tiny>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/mojo-promise-role-higherorder

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2018-2021, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
