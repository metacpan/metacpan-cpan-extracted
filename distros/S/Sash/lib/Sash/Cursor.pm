package Sash::Cursor;
use strict;
use warnings;

use base qw( Class::Accessor );
use Sash::Table;
use Carp;

Sash::Cursor->mk_accessors( qw(
    is_valid
    closed
    client
    size
    data
    header
    caller
    missing_id_field
    query
    batch_size
    result
    attributes
    message
) );

sub open {
    my $class = shift;
    my $args = shift;

    my $self = bless {
        is_valid => 1,
        closed => 0,
        client => $args->{client},
        query => $args->{query}, 
        caller => $args->{caller},
        batch_size => $args->{batch_size},
    }, ( ref $class || $class );

    return $self;
}

sub fetch {
    my $self = shift;

    croak 'Invalid Cursor - cursor has previously been closed and is no longer valid' if $self->closed;
    
    # Make sure we don't have an of these based on the last call to fetch.
    $self->result( undef );
    $self->attributes( undef );
    $self->data( undef );
    $self->header( undef );
    $self->message( undef );

    # for the love of convention and perl quirks
    my $caller = $self->caller;
    $self->$caller;
    
    $self->_end;
}

sub close {
    my $self = shift;
    $self->closed( 1 );
}

sub _end {
    my $self = shift;
    
    # Define the magic variable for the user to use.
    $Sash::Command::result = $self->result if defined $self->result;
    
    return $self->result if Sash::Properties->output eq Sash::Properties->perlval;
    
    if ( Sash::Properties->output eq Sash::Properties->vertical ) {
        my $vertical_data;
        my $header = $self->header;
        
        foreach ( @{$self->data} ) {
            my $i = 0;
            push @$vertical_data, [ $header->[$i++], $_ ] foreach ( @$_ );
        }
        
        $self->data( $vertical_data );
        $self->attributes( $header );
        $self->header( [ 'Attribute', 'Value' ] );
    }

    my $table = Sash::Table->new( $self->data, $self->header, $self->attributes );

    return $table;
}

sub _derive_header {
    my $self = shift;
    my $query = shift;

    # define defaults for the id field
    my $missing_id_field = 0;
    my $re = qr/[^type]/i;

    # Account for the fact the user included an id field in the query
    unless ( $query =~ /\bid\b/i ) {
        $missing_id_field = 1;
        $re = qr/[^type|id]/i;
    }


    # Create the header from the attributes of the query.
    $query =~ s/(\r|\n)+/ /g;
    my $header = [ split /\s*,\s*/, lc( $1 ) ] if $query =~ s/select\s*(.*?)\s*from.*/$1/ig;

    $self->header( $header );
    $self->missing_id_field( $missing_id_field );

    return ( $header, $missing_id_field );
}

sub _convert_rows {
    my $self = shift;
    my $rows = shift; #array ref

    croak 'self->header and self->missing_id_field need to be defined' unless $self->header;

    my $data = [ map {
        my $object = $_;

        # Make our lookup of the hash elements case insensitive in the next command.
        my $lookup = { map { lc( $_ ) => \$object->{$_} } keys %$object };

        # Using @$header here ensures the order of the attributes the user typed in.
        [ map { unless ( $self->missing_id_field && ( 'id' eq $_ ) ) { ${$lookup->{$_}} } else { } } @{$self->header} ];
    } @$rows ];

    $self->data( $data );

    return $self->_end;
}

1;
