package Net::Curl::Promiser::Mojo;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Curl::Promiser::Mojo - support for L<Mojolicious>

=head1 SYNOPSIS

    my $promiser = Net::Curl::Promiser::Mojo->new();

    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );

    $promiser->add_handle_p($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url failed: " . shift },
    )->wait();

=head1 DESCRIPTION

This module provides a L<Mojolicious>-compatible subclass of
L<Net::Curl::Promiser>.

See F</examples> in the distribution, as well as the tests,
for fleshed-out demonstrations.

=head1 MOJOLICIOUS SPECIALTIES

This module implements the following tweaks to make it
more Mojo-friendly:

=over

=item * This module uses L<Mojo::Promise> rather than L<Promise::ES6>
as its promise implementation.

=item * C<add_handle_p()> is an alias for the base class’s C<add_handle()>.
This alias conforms to Mojo’s convention of postfixing C<_p> onto the end
of promise-returning functions.

=back

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Promiser::LoopBase';

use Net::Curl::Promiser::Backend::Mojo;

#----------------------------------------------------------------------

*add_handle_p = __PACKAGE__->can('add_handle');

#----------------------------------------------------------------------

sub _INIT {
    return Net::Curl::Promiser::Backend::Mojo->new();
}

1;
