package Mojo::Promise::Role::HigherOrder;
use Mojo::Base '-role';

use strict;

our $VERSION = '1.002';

=encoding utf8

=head1 NAME

Mojo::Promise::Role::HigherOrder - Fulfill with the first fulfilled promise

=head1 SYNOPSIS

	use Mojo::Promise;
	use Mojo::Promise::Role::HigherOrder;

	my $any_promise = Mojo::Promise
		->with_roles( '+Any' )  # or +None or +Some
		->any( @promises );

=head1 DESCRIPTION

This module is an umbrella for L<Mojo::Promise::Role::Any>,
L<Mojo::Promise::Role::None>, and L<Mojo::Promise::Role::Some>.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Promise>, L<Role::Tiny>

L<http://bluebirdjs.com/docs/api/promise.any.html>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/mojo-promise-role-higherorder

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
