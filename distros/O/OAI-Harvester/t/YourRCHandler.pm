package YourRCHandler; 

# custom handler for testing that we can drop in our own recorddata
# handler in t/03.getrecord.t and t/50.listrecords.t

use base qw( MyRCHandler );

sub result_i { 
    my $self = shift;
    return( $self->{ OAIdentifier } );
}

sub result_t { 
    my $self = shift;
    return( $self->{ title } );
}

1;
