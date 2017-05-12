package Sash::Plugin::VerticalResponse::Cursor;

use strict;
use warnings;

use base qw( Sash::Cursor );
use Carp;

# Apparently I will sell you the rope you are going to use to hang me with...
sub AUTOLOAD {
    our $AUTOLOAD;

    # No really what this does is allow sash to grow as the api grows and uses
    # the same type of data structures.
    if ( $AUTOLOAD =~ /::(\w*)\_meth$/ ) {
        my $self = shift;
        my $method = $1;
        
        # Just in case you didn't grok it, $1 is the name of the method from
        # the match above.
        my $result = $self->{client}->$method( $self->query );
        
        # Account for the fact that create methods just return the
        # id of the record.
        $result = { id => $result } if $method =~ /^create/;

        # In the delete methods case the query is a hash so we want the
        # return value to be the record id that was passed to us.
        $result = { id => ( %{$self->query} )[1] } if $method =~ /^delete/;

        $self->_define_header_data( $result );

        return;
    }
}

sub open {
    my $class = shift;
    my $args = shift;
    
    # We have a usage relationship with this singleton.
    $args->{client} = Sash::Plugin::VerticalResponse->client;

    my $self = $class->SUPER::open( $args );

    return $self;
}

sub _define_header_data {
    my $self = shift;
    my $result = shift;
    my $attributes = shift;
    
    my $header;
    my $data;

    # Help format VR Special Datatypes for simple output.
    my $format_data_attribute = sub {
        my $attribute = shift;

        my $joinby = ( Sash::Properties->output eq Sash::Properties->vertical ) ? "\n" : ', ';
        
        if ( ref $attribute eq 'ArrayOfString' ) {
            return undef unless scalar( @$attribute ) > 0;
            return join $joinby, @$attribute;
        }

        return $attribute;
    };

    # The real purpose of this method is to convert what otherwise would be nested
    # data into data that is at the same level so to speak for each attribute in
    # the nested structure.
    my $expand_record = sub {
        my $record = shift;

        my $expanded_record = { };
        my $header;

        foreach my $attribute ( sort keys %$record ) {
            if ( ref $record->{$attribute} eq 'NVDictionary' ) {
                $expanded_record = { %$expanded_record, map { $_->{name} => $_->{value} } @{$record->{$attribute}} };
            } elsif ( ref $record->{$attribute} eq 'StreetAddress' ) {
                $expanded_record = { %$expanded_record, map { $_ => $record->{$attribute}->{$_} } sort keys %{$record->{$attribute}} };
            } else {
                $expanded_record->{$attribute} = $record->{$attribute};
            } 
        }

        return $expanded_record;
    };

    my $use_result = $result;
    $use_result = [ $use_result ] unless uc( ref $use_result ) =~ /^ARRAY/;

    $data = [
        map {
            my $record = $expand_record->( $_ );
            $header = [ sort keys %$record ] unless defined $header;
            [ map { $format_data_attribute->( $record->{$_} ) } sort keys %$record ];
        } @$use_result
    ];
    
    $self->result( $result );
    $self->header( $header );
    $self->data( $data );

    return;
}

sub getCompany_meth {
    my $self = shift;
    
    my $company = [ $self->{client}->getCompany( $self->query ) ];

    my @users;

    if ( defined $company->[0]->{users} ) {
        @users = $company->{users};
        delete $company->{users};
        my @user_ids = map { $_->{id} } @users;
        $company->{user_ids} = @user_ids;
    }

    $self->_define_header_data( $company );
    
    return;
}

sub show_proc {
    my $self = shift;
    
    my $header = [ 'Methods' ];
    my $data = [ map { [ $_ ] } sort $self->{client}->_methods ];
    
    $self->header( $header );
    $self->data( $data );
    
    return;
}

1;
