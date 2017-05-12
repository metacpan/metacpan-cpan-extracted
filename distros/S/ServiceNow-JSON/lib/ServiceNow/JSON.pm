package ServiceNow::JSON;
use Moose;
use REST::Client;
use MIME::Base64;
use JSON;

our $VERSION = 0.01;

has 'instance' => (
    is => 'rw',
    isa => 'Str',
);

has 'user' => (
    is => 'rw',
    isa => 'Str',
);

has 'password' => (
    is => 'rw',
    isa => 'Str',
);

has 'client' => (
    is => 'rw',
    isa => 'REST::Client',
);

has 'legacy' => (
    is => 'rw',
    isa => 'Any',
    default => '0',
);

sub BUILD {
    my ( $self ) = @_;
    my $client = REST::Client->new();
    $client->setHost( "https://" . $self->instance . ".service-now.com" );
    $client->addHeader( 'Accept', '*/*' );
    $client->addHeader( 'Authorization', 'Basic ' . encode_base64( $self->user . ":" . $self->password ) );
    $self->client( $client );
}

sub _do_request {
    my ( $self, $table, $action, $json ) = @_;

    my $api_version = "JSONv2";

    $api_version = "JSON" if $self->legacy;
    
    my $url = $table . ".do?$api_version&$action";

    if( $json ) {
        $self->client->POST( $url, to_json( $json ), { "Content-type" => 'application/json' } );
        if( $self->client->responseCode != 200 ) {
            print STDERR "ERROR!\n";
            print STDERR $self->client->responseContent();
        } else {
            my $data = from_json( $self->client->responseContent() );
            if( exists( $data->{records} ) ) {
                return $data->{records};
            } else {
                return $data;
            
            }
        }
    } else {
        $self->client->GET( $url );
        if( $self->client->responseCode != 200 ) {
            print STDERR "ERROR!\n";
            print STDERR $self->client->responseContent();
        } else {
            if( $self->client->responseContent() ) {
                my $data = from_json( $self->client->responseContent() );
                if( exists( $data->{records} ) ) {
                    return $data->{records};
                } else {
                    return $data;
                }
            } else {
                return [];
            }
        }
    }
}

sub getRecords {
    my ( $self, $table, $search ) = @_;
    my $search_str = $self->_build_search_string( $search );
    return $self->_do_request( $table, "sysparm_action=getRecords$search_str" );
}

sub getKeys {
    my ( $self, $table, $search ) = @_;
    my $search_str = $self->_build_search_string( $search );
    return $self->_do_request( $table, "sysparm_action=getKeys$search_str" );
}

sub get {
    my ( $self, $table, $sysparm_id ) = @_;
    return $self->_do_request( $table, "sysparm_action=get&sysparm_sys_id=$sysparm_id" );
}

sub _build_search_string {
    my ( $self, $search ) = @_;

    my $search_str = "";

    if( scalar( keys( %{ $search } ) ) > 0 ) {
        $search_str = "&sysparm_query=";

        my @terms;
        foreach my $key ( keys %{ $search } ) {
            push( @terms, "$key=" . $search->{$key} );
        }

        $search_str .= join( '^', @terms );
    }
    
    return $search_str;
}

sub update {
    my ( $self, $table, $search, $changes ) = @_;
    my $search_str = $self->_build_search_string( $search );
    return $self->_do_request( $table, "sysparm_action=update$search_str", $changes );
}

sub insert {
    my ( $self, $table, $data ) = @_;

    if( ref( $data ) eq "ARRAY" ) {
        return $self->insertMultiple( $table, $data );
    }

    return $self->_do_request( $table, "sysparm_action=insert", $data );
}

sub insertMultiple {
    my ( $self, $table, $data ) = @_;

    if( ref( $data ) eq "ARRAY" ) {
        $data = { records => $data };
    }

    return $self->_do_request( $table, "sysparm_action=insertMultiple", $data );
}

sub delete {
    my ( $self, $table, $sysparm_id ) = @_;
    return $self->_do_request( $table, "sysparm_action=deleteRecord&sysparm_sys_id=$sysparm_id" );
}

sub deleteMultiple {
    my ( $self, $table, $search ) = @_;
    my $search_str = $self->_build_search_string( $search );
    return $self->_do_request( $table, "sysparm_action=deleteMultiple$search_str" );
}

=head1 NAME

ServiceNow::JSON - Absraction Library for ServiceNow JSON WebServices

=head1 DESCRIPTION

Allows for easy use of the ServiceNow JSON REST api from perl.  Supports
both ServiceNow JSON and ServiceNow JSONv2 implementations.  

=head1 SYNOPSIS

use ServiceNow::JSON;

my $sn = new ServiceNow::JSON( instance => "my_sn_instance", 
    user => "foo", password => "bar" );

my $record = $sn->get( "cmdb_ci_computer", 
    "72542ce36f015500e5f95afc5d3ee423" );

my $records = $sn->getRecords( "cmdb_ci_computer", 
    { serial_number => '1234567' } );

my $keys = $sn->getKeys( "cmdb_ci_computer", 
    { active => "true" } );

my $update = $sn->update( "cmdb_ci_computer", 
    { sys_id => '0014eca36f015500e5f95afc5d3ee4af' }, 
    { cpu_name => "kevin_test_another" } );

my $insert = $sn->insert( "cmdb_ci_computer", 
    { serial_number => "1234567" } );

my $multi_insert = $sn->insert( "cmdb_ci_computer", 
    [ { serial_number => "222222" },
      { serial_number => "111111" } ] );

my $delete = $sn->delete( "cmdb_ci_computer", 
    '0014eca36f015500e5f95afc5d3ee4af' );

my $delete_multi = $sn->deleteMultiple( "cmdb_ci_computer", 
    { serial_number => "111111" } );

=head1 DESCRIPTION

If you need to use version 1 of the ServiceNow JSON API, pass legacy => 1 
to the contructor. "Instance" in the contructor represents the part of the 
service now url that is before service-now.com.  So instance.service-now.com.

=head1 METHODS

=head2 get

Accepts a table/record name and a sys_id for that record, returns an arrayref with either
0 or 1 elements.  The elements will be a hashref of the ServiceNow object.

=head2 getRecords

Accepts a table/record name and a hashref of query terms, multiple terms are ANDed together,
API does not support OR type clauses. Returns all objects in an arrayref that match that
query.

=head2 getKeys

Accepts a table/record name and a hashref of query terms.  Returns an arrayref of sys_ids
for all objects that match the query criteria.

=head2 update

Accepts a table/record name, a hashref of query parameters and a hashref of the changes
 you wish to make.  Multiple query parameters are ANDed together, works the same as getRecords
 and getKeys.  Returns an arrayref of the objects that were updated.

=head2 insert

Accepts a table/record name and either an array or hashref of the data you wish to enter.  
If you pass an arrayref it will detect this and pass the call onto insertMultiple. 
Returns an arrayref of the records that were just created.

=head2 insertMultiple

Accepts a table/record name and an arrayref of the records you want to insert.  Returns an
arrayref of the records that were just created.

=head2 delete

Accepts a table/record name and a sys_id of the record you wish to delete.  Will only ever 
delete a single record.  Returns the record that you just deleted in an arrayref.

=head2 deleteMultiple

Accepts a table/record name and a hashref of query terms.  Will delete ALL records that match 
those query terms.  Returns arrayref of the objects that were deleted.

=head1 SEE ALSO  

L<Moose|Moose>

L<REST::Client|REST::Client>

L<MIME::Base64|MIME::Base64>

L<JSON|JSON>

L<https://wiki.servicenow.com/index.php?title=JSON_Web_Service|ServiceNow JSON Web Service Documentation>

L<https://github.com/klkane/servicenow-json|ServiceNow::JSON Github Repository>

=head1 AUTHOR

Kevin L. Kane, E<lt>kkane@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kevin L. Kane

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
