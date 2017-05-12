use strict;
use warnings;

package Net::Trac::TicketSearch;
use Any::Moose;
use Params::Validate qw(:all);
use URI::Escape qw(uri_escape);

use Net::Trac::Ticket;

=head1 NAME

Net::Trac::TicketSearch - A ticket search (custom query) in Trac

=head1 SYNOPSIS

    my $search = Net::Trac::TicketSearch->new( connection => $trac );
    
    $search->query(
        owner       => 'hiro',
        status      => { 'not' => [qw(new reopened)] },
        summary     => { 'contains' => 'yatta!' },
        reporter    => [qw( foo@example.com bar@example.com )]
    );
    
    print $_->id, "\n" for @{$search->results};

=head1 DESCRIPTION

This class allows you to run ticket searches on a remote Trac instance.

=head1 ACCESSORS

=head2 connection

=head2 limit [NUMBER]

Get/set the maximum number of results to fetch.  Default is 500.  This may
also be limited by the Trac instance itself.

=head2 results

Returns an arrayref of L<Net::Trac::Ticket>s for the current query.

=head2 url

Returns the relative URL for the current query (note the format will be CSV).

=cut

has connection => (
    isa => 'Net::Trac::Connection',
    is  => 'ro'
);

has limit   => ( isa => 'Int',      is => 'rw', default => sub { 500 } );
has results => ( isa => 'ArrayRef', is => 'rw', default => sub { [] } );
has url     => ( isa => 'Str',      is => 'rw' );

=head1 METHODS

=head2 query [PARAMHASH]

Performs a ticket search with the given search conditions.  Specify a hash of
C<column => value> pairs for which to search.  Values may be a simple scalar,
a hashref, or an arrayref.  Specifying a hashref allows you to select a different
operator for comparison (see below for a list).  An arrayref allows multiple values
to be B<or>'d for the same column.  Unfortunately Trac has no way of B<and>ing
multiple values for the same column.

Valid operators are C<is> (default), C<not>, C<contains>, C<lacks>, C<startswith>,
and C<endswith>.

Returns undef on error and the L<results> otherwise.

=cut

sub query {
    my $self  = shift;
    my %query = @_;

    my $no_objects = delete $query{'_no_objects'};

    # Clear current results
    $self->results([]);

    # Build a URL from the fields we want and the query
    my $base = '/query?format=tab&order=id&max=' . $self->limit;
    $base .= '&' . join '&', map { "col=$_" } Net::Trac::Ticket->valid_props;

    $self->url( $self->_build_query( $base, \%query ) );

    my $content = $self->connection->_fetch( $self->url )
        or return;

    my $data = $self->connection->_tsv_to_struct( data => \$content);

    unless ( $no_objects ) {
        my @tickets = ();
        for my $ticket_data ( @{$data || []} ) {
            my $ticket = Net::Trac::Ticket->new( connection => $self->connection );
            $ticket->_tweak_ticket_data_for_load($ticket_data);
            my $id = $ticket->load_from_hashref( $ticket_data );
            push @tickets, $ticket if $id;
        }
        return $self->results( \@tickets );
    }
    else {
        return $self->results( $data );
    }
}

our %OPERATORS = (
    undef       => '',
    ''          => '',
    is          => '',
    not         => '!',
    contains    => '~',
    lacks       => '!~',
    startswith  => '^',
    endswith    => '$',
);

sub _build_query {
    my $self  = shift;
    my $base  = shift;
    my $query = shift || {};
    my $defaultop = $OPERATORS{ shift || 'is' } || '';

    for my $key ( keys %$query ) {
        my $value = $query->{$key};

        if ( ref $value eq 'ARRAY' ) {
            $base .= "&$key=" . uri_escape( $defaultop . $_ ) for @$value;
        }
        elsif ( ref $value eq 'HASH' ) {
            my ($op, $v) = %$value;
            $base .= $self->_build_query( '', { $key => $v }, $op );
        }
        elsif ( not ref $value ) {
            $base .= "&$key=" . uri_escape( $defaultop . $value );
        }
        else {
            warn "Skipping '$key = $value' in ticket search: value not understood.";
        }
    }

    return $base;
}

=head1 LICENSE
    
Copyright 2008-2009 Best Practical Solutions.
    
This package is licensed under the same terms as Perl 5.8.8.
    
=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

