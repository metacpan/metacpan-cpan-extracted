package Sash::Table;
use strict;
use warnings;

# Nice adapter and decorator pattern implementations here.

use Text::ASCIITable;
use base qw( Data::Table );
use Carp;

sub new {
    my $class = shift;
    my $data = shift;
    my $header = shift;
    my $attributes = shift || $header;

    # The zero as the last attribute indicates we want row based table and not
    # a column based one.
    my $self = $class->SUPER::new( $data, $header, 0 );

    
    bless $self, 'Sash::Table';

    $self->attributes( $attributes );

    return $self;
}

sub attributes {
    my $self = shift;
    $self->{attributes} = ( shift || $self->{attributes} );
}

sub clone {
    my $self = shift;

    # This is one way to do it without introspecting on the parent
    # and knowing anything about it's implementation details.
    my $data = $self->rowRefs;
    
    my $clone = $self->SUPER::new( $data, $self->{header}, 0 );
    
    $clone->attributes( $self->attributes );
    
    return $clone;
}

sub sort {
    my $self = shift;

    # Override the default behavior of doing an in place manipulation
    # on the data to be consistent with the other table operations in
    # the api.
    my $clone = $self->clone;

    # If you think $self is correct here than you really do not understand
    # deep recursion in perl
    my $sorted = $clone->SUPER::sort( @_ );

    croak 'Unable to sort data' unless $sorted;

    return $clone;
}

sub match_string {
    my $self = shift;
    
    # Pay attention and be crafty here in that we want Sash::Table not Data::Table.
    my $result = $self->SUPER::match_string( @_ );
    
    return bless $result, ( ref $self || $self );
}

sub display {
    my $self = shift;
    my $elapsed = shift;

    my $table = Text::ASCIITable->new;

    $table->setCols( $self->header );

    # This represents the total number of rows in the result set.
    my $row_count = scalar( @{$self->rowRefs} );

    # This is the total number of attributes that make up a single
    # row in the result set.
    my $attribute_count = scalar( @{$self->attributes} );

    # We keep track of "vertical" rows because if you don't take
    # into account attributes then the row count is off.
    my $row_counter = 1;
    my $vertical_row_counter = 1;

    if ( Sash::Properties->output eq Sash::Properties->vertical ) {
        # accounted
        $row_count = $row_count / scalar( @{$self->attributes} );

        # Puts a pretty border around the row data.
        $table->addRow( 'row', $vertical_row_counter );
        $table->addRowLine;
    }

    foreach ( @{$self->rowRefs} ) {
        # Must have
        $table->addRow( @$_ );

        # Make the vertical output correct and with its row counter
        # line visible in a pretty border
        if (
            ( $row_counter++ % $attribute_count == 0 ) && 
            ( $row_counter/$attribute_count <= $row_count ) &&
            ( Sash::Properties->output eq Sash::Properties->vertical )
        ) {
            $vertical_row_counter++;

            $table->addRowLine;
            $table->addRow( 'row', $vertical_row_counter );
            $table->addRowLine;
        }
    }

    # Table layout to emulate mysql
    print $table->draw(
        ['+','+','-','+'],
        ['|','|','|'],
        ['+','+','-','+'],
        ['|','|','|'],
        ['+','+','-','+'],
    ) . "\n";

    my $message = $row_count . ' rows in set ';
    $message .= $elapsed if $elapsed;

    print "$message\n";

    return;
}

1;
