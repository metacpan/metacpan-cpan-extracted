package Prancer::Plugin;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.05';

use Prancer::Core;

sub config {
    die "core has not been initialized\n" unless Prancer::Core->initialized();
    return Prancer::Core->new->config();
}

1;

=head1 NAME

Prancer::Plugin

=head1 SYNOPSIS

This should be the base class for all plugins used with Prancer. It provides
the convenience methods shown below to plugins that inherit from it.

=head1 METHODS

=over

=item config

Returns the application's current configuration. See L<Prancer::Config> for
more details on how to use this method. This method be called statically or
as an instance method. This method will C<die> if L<Prancer::Core> has not
been initialized.

=back

=cut
