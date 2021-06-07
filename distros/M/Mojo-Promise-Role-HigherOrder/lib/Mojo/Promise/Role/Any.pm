package Mojo::Promise::Role::Any;
use Mojo::Base '-role';

use strict;

our $VERSION = '1.005';

=encoding utf8

=head1 NAME

Mojo::Promise::Role::Any - Fulfill with the first fulfilled promise

=head1 SYNOPSIS

	use Mojo::Promise;

	my $any_promise = Mojo::Promise
		->with_roles( '+Any' )
		->any( @promises );

=head1 DESCRIPTION

NOTE: Mojolicious 8.73 adds C<any()> as a stable feature, so you don't
need this role.

Make a new promise that fulfills with the first fulfilled promise, and
rejects otherwise. The result is a flat list of the arguments for the
fulfilled promise (and not an anonymous array of values).

This should be the Perl expression of the same idea in bluebirdjs
(L<http://bluebirdjs.com/docs/api/promise.any.html>).

This is handy, for instance, for asking for several servers to provide
the same resource and taking the first one that responds.

=over 4

=item any( @promises )

Takes a lists of promises (or thenables) and returns another promise
that fulfills when any promise fulfills (and it ignores the
others after that).

If none of the promises fulfill, the any promise rejects.

If you pass no promises, the any promise rejects.

=cut

sub any {
	my( $self, @promises ) = @_;
	my $any = $self->new;

	my $count = 0;
	$_->then(
		sub { $any->resolve( @_ ); return },
		sub { $count++; $any->reject if $count == @promises; return }
		) foreach @promises;

	return @promises ? $any : $any->reject;
	}

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Promise>, L<Role::Tiny>

L<http://bluebirdjs.com/docs/api/promise.any.html>

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
