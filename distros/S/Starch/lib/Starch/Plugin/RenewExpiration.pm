package Starch::Plugin::RenewExpiration;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

use Moo;
use namespace::clean;

with qw(
    Starch::Plugin::Bundle
);

sub bundled_plugins {
    return [qw(
        ::RenewExpiration::Manager
        ::RenewExpiration::State
    )];
}

1;
__END__

=head1 NAME

Starch::Plugin::RenewExpiration - Trigger periodic writes to the store.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::RenewExpiration'],
        renew_threshold => 10 * 60, # 10 minutes
        ...,
    );

=head1 DESCRIPTION

If your state is used for reading more than writing you may find that your
states expire in the store when they are still being used since your code
has not triggered a write of the state data by changing it.

This plugin causes L<Starch::State/save> to save even if the state data is
not dirty (normally it would just silently return).  Typically you'll want
to set the L</renew_threshold> argument so that this write only happens after
the state has gotten a little stale rather than on every time it is used.

=head1 OPTIONAL MANAGER ARGUMENTS

These arguments are added to the L<Starch::Manager> class.

=head2 renew_threshold

How long to wait, since the last state write, before forcing save
to write to the store.

Defaults to zero which will renew the expiration every time save is
called.

=head2 renew_variance

In order to avoid multiple simultaneous requests from trying to renew
an expiration at the same time, stampeding the store, you can set this
attribute to add some randomness to the L</renew_threshold> check.

This must be a ratio between C<0.0> and C<1.0>.  A C<renew_variance>
of C<0.5> and a C<renew_threshold> of C<60> would cause the expiration
to be renewed somewhere between C<30> and C<60> seconds after it was
last modified.

Defaults to C<0.0> which means there will be no variance.

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHORS> and L<Starch/LICENSE>.

=cut

