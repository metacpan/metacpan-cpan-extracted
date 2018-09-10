package Mojo::Promise::Role::Some;
use Mojo::Base '-role';

use strict;

our $VERSION = '1.001';

=encoding utf8

=head1 NAME

Mojo::Promise::Role::Some - Fulfill when a certain number of promises are fulfilled

=head1 SYNOPSIS

	use Mojo::Promise;
	use Mojo::Util qw(dumper);

	my @promises = map { Mojo::Promise->new } 0 .. 5;
	my $some_promise = Mojo::Promise
		->with_roles( '+Some' )
		->some( \@promises, $count_to_fulfill );

	$some_promise->then(
		sub { say dumper( @_ ) }
		sub { say "Failed!" }
		);

	$some_promise->wait;

=head1 DESCRIPTION

Make a new promise that fulfills with a certain number of its promises
fulfill. Fire off several tasks and fulfill when a minimum number of them
work out.

This should be the Perl expression of the same idea in
bluebirdjs (L<http://bluebirdjs.com/docs/api/promise.some.html>).

=over 4

=item some( \@promises, $count )

Takes a lists of promises (or thenables) and returns another promise
that fulfills when C<$count> promises fulfill. The result is list of
array references for the arguments for the fulfilled promises in the
order that they were fulfilled.

If less than C<$count> promises fulfill then the some promise rejects.
The result is list of array references for the arguments for the
rejected promises in the order that they were rejected. The number of elements
in that list should be the PROMISES - COUNT + 1 since the extra reject
is the response that makes it impossible to get to COUNT fulfills.

If you pass no promises, the some promise fulfills if you specify
C<$count = 0> and rejects otherwise.

=cut

sub some {
	my( $self, $promises, $n ) = @_;
	my $some = $self->new;

	return $n == 0 ? $some->resolve : $some->reject if @$promises == 0;
	return $some->reject if $n > @$promises;

	my $remaining = @$promises;

	my( @resolved, @rejected );
	foreach my $p ( @$promises ) {
		$p->then(
			sub {
				$remaining--;
				push @resolved, [ @_ ];
				$some->resolve( @resolved ) if @resolved == $n;
				},
			sub {
				# I keep trying to come up with a situation where
				# you'd reject $some with fewer rejections, but as
				# long as the sum of the pending and fulfilled is at
				# least the minimum count, there's always a chance.
				# The only way for that to not be true is for there
				# to be enough rejections to make pending small enough.
				# That's PROMISES - N + 1. Let's see if I can understand
				# that the next time I come through this. I still don't
				# believe it.
				$remaining--;
				push @rejected, [ @_ ];
				$some->reject( @rejected ) if @rejected > @$promises - $n
				},
			)
		}

	return $some;
	}

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Promise>, L<Role::Tiny>

L<http://bluebirdjs.com/docs/api/promise.some.html>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/mojo-promise-any-none-some

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
