package Mojolicious::Plugin::DataTables::SSP::Params;

use Mojo::Base -base;

our $VERSION = '1.01';

has 'columns';
has 'draw';
has 'length';
has 'order';
has 'search';
has 'columns';
has 'timestamp';
has 'start';

sub db_columns {

    my ($self) = @_;

    my @columns;

    foreach ( @{ $self->columns } ) {
        push @columns, $_->database if ( $_->database );
    }

    return @columns;

}

sub db_order {

    my ($self) = @_;

    my $order = {};

    foreach ( @{ $self->order } ) {
        if ( $_->{column}->{database} ) {
            $order->{ $_->{column}->{database} } = $_->{dir};
        }
    }

    return $order;

}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::DataTables::SSP::Params - DataTables SSP Params Helper

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('DataTables');

    # Mojolicious::Lite
    plugin 'DataTables';

    [...]

    my $dt_params = $c->datatable->ssp_params(
        [
            {
                label     => 'UID',
                db        => 'uid',
                dt        => 0,
                formatter => sub {
                    my ($value, $column) = @_;
                    return '<a href="/user/' . $value . '">' . $value . '</a>';
                }
            },
            {
                label => 'e-Mail',
                db    => 'mail',
                dt    => 1,
            },
            {
                label => 'Status',
                db    => 'status',
                dt    => 2,
            },
        ]
    ));

=head1 DESCRIPTION

L<Mojolicious::Plugin::DataTables::SSP::Params> is a L<Mojolicious> plugin to add DataTables SSP (Server-Side Protocol) support in your Mojolicious application.


=head1 CONTRUCTOR

=head2 Mojolicious::Plugin::DataTables::SSP::Params->new ( @options )

Create a new instance of L<Mojolicious::Plugin::DataTables::SSP::Params> class.

Options:

=over 4

=item C<label>: Column label

=item C<db>: Database column name

=item C<dt>: DataTable column ID

=item C<formatter>: Formatter sub

=back


=head1 METHODS

L<Mojolicious::Plugin::DataTables::SSP::Params> implements the following methods.

=head2 columns

=head2 draw

=head2 length

=head2 order

=head2 search

=head2 columns

=head2 timestamp

=head2 start



=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<Mojolicious::Plugin::DataTables>, L<Mojolicious::Plugin::DataTables::SSP::Results>.

=cut
