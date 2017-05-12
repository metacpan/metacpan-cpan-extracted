package Prancer::Session::Store::Storable;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.05';

use Plack::Session::Store::File;
use parent qw(Plack::Session::Store::File);

1;

=head1 NAME

Prancer::Session::Store::Storable

=head1 SYNOPSIS

This package implements a session handler based on files written using the
L<Storable> package. Session files are saved in the configured directory.
This backend can be used in production environments but two things should be
kept in mind: the content of the session files is in plain text and session
files still need to be periodically purged.

To use this session storage handler, add this to your configuration file:

    session:
        store:
            driver: Prancer::Session::Store::Storable
            options:
                dir: /tmp/prancer/sessions

=head1 OPTIONS

=over 4

=item dir

B<REQUIRED> This indicates the path where sessions will be written. This path
must be writable by the same user that is running the application server. If
this is not set or the configured path is not writable then the session handler
will not be initialized and sessions will not work.

=back

=cut
