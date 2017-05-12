package Dancer::Plugin::Nitesi::Backend::DBI;

use Moo;
use Dancer::Plugin::Database;

=head1 NAME

Dancer::Plugin::Nitesi::Backend::DBI - Dancer DBI backend for Nitesi Shop Machine

=head1 ATTRIBUTES

=head2 dbh

DBI database handle, which is usually retrieved through
L<Dancer::Plugin::Database>.

=cut

# database handle retrieved from Dancer::Plugin::Database
has dbh => (
    is => 'ro',
    default => sub {database},
    );

=head2 log_queries

Refererence to subroutine for logging database queries.

=cut

has log_queries => (
    is => 'rw',
);

=head1 METHODS

=head2 params

Returns backend parameters.

=cut

sub params {
    my $self = shift;
    my %params;

    $params{dbh} = $self->dbh;
    $params{log_queries} = $self->log_queries;

    return \%params;
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
