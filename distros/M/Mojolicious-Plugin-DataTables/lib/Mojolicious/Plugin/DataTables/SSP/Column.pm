
package Mojolicious::Plugin::DataTables::SSP::Column;

use Mojo::Base -base;

our $VERSION = '1.01';

has 'data';
has 'database';
has 'formatter';
has 'label';
has 'name';
has 'orderable';
has 'search';
has 'searchable';
has 'row';

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::DataTables::SSP::Column - DataTables SSP Column Helper

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('DataTables');

    # Mojolicious::Lite
    plugin 'DataTables';

=head1 DESCRIPTION

L<Mojolicious::Plugin::DataTables::SSP::Column> is a L<Mojolicious> plugin to add DataTables SSP (Server-Side Protocol) support in your Mojolicious application.


=head1 METHODS

L<Mojolicious::Plugin::DataTables::SSP::Column> implements the following methods.


=head2 data

=head2 database

=head2 formatter

=head2 label

=head2 name

=head2 orderable

=head2 search

=head2 searchable

=head2 row


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<Mojolicious::Plugin::DataTables>.

=cut
