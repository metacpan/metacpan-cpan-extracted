package Mojolicious::Plugin::DataTables::SSP::Results;

use Mojo::Base -base;
use Mojo::JSON qw(encode_json);

our $VERSION = '1.01';

has 'draw';
has 'records_total';
has 'records_filtered';
has 'data';

sub TO_JSON {

    my ($self) = @_;

    return {
        draw            => $self->draw,
        recordsTotal    => $self->records_total,
        recordsFiltered => $self->records_filtered,
        data            => $self->data,
    };

}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::DataTables::SSP::Results - DataTables SSP Result Helper

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('DataTables');

    # Mojolicious::Lite
    plugin 'DataTables';

    [...]

    $c->render(json => $c->datatable->ssp_results(
        draw             => 1,
        data             => \@results,
        records_total    => 100,
        records_filtered => 0
    ));

=head1 DESCRIPTION

L<Mojolicious::Plugin::DataTables::SSP::Results> is a L<Mojolicious> plugin to add DataTables SSP (Server-Side Protocol) support in your Mojolicious application.


=head1 METHODS

L<Mojolicious::Plugin::DataTables::SSP::Results> implements the following methods.

=head2 draw

=head2 records_total

=head2 records_filtered

=head2 data

=head2 TO_JSON


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<Mojolicious::Plugin::DataTables>, L<Mojolicious::Plugin::DataTables::SSP::Params>.

=cut
