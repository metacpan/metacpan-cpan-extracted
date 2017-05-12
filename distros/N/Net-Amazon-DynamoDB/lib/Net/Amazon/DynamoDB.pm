package Net::Amazon::DynamoDB;

=head1 NAME

Net::Amazon::DynamoDB - Simple interface for Amazon DynamoDB

=head1 DESCRIPTION

Simple to use interface for Amazon DynamoDB

If you want an ORM-like interface with real objects to work with, this is implementation is not for you. If you just want to access DynamoDB in a simple/quick manner - you are welcome.

See L<https://github.com/ukautz/Net-Amazon-DynamoDB> for latest release.

=head1 SYNOPSIS

    my $ddb = Net::Amazon::DynamoDB->new(
        access_key => $my_access_key,
        secret_key => $my_secret_key,
        tables     => {

            # table with only hash key
            sometable => {
                hash_key   => 'id',
                attributes => {
                    id   => 'N',
                    name => 'S'
                }
            },

            # table with hash and reange key key
            othertable => {
                hash_key   => 'id',
                range_key  => 'range_id',
                attributes => {
                    id       => 'N',
                    range_id => 'N',
                    attrib1  => 'S',
                    attrib2  => 'S'
                }
            }
        }
    );

    # create both tables with 10 read and 5 write unites
    $ddb->exists_table( $_ ) || $ddb->create_table( $_, 10, 5 )
        for qw/ sometable othertable /;

    # insert something into tables
    $ddb->put_item( sometable => {
        id   => 5,
        name => 'bla'
    } ) or die $ddb->error;
    $ddb->put_item( sometable => {
        id        => 5,
        range_id  => 7,
        attrib1   => 'It is now '. localtime(),
        attrib2   => 'Or in unix timstamp '. time(),
    } ) or die $ddb->error;

=cut

use Moose;

use v5.10;
use version 0.74; our $VERSION = qv( "v0.1.16" );

use Carp qw/ croak /;
use Data::Dumper;
use DateTime::Format::HTTP;
use DateTime::Format::Strptime;
use DateTime;
use Digest::SHA qw/ sha1_hex sha256_hex sha384_hex sha256 hmac_sha256_base64 /;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use LWP::ConnCache;
use Net::Amazon::AWSSign;
use Time::HiRes qw/ usleep /;
use XML::Simple qw/ XMLin /;
use Encode;

=head1 CLASS ATTRIBUTES

=head2 tables

The table definitions

=cut

has tables => ( isa => 'HashRef[HashRef]', is => 'rw', required => 1, trigger => sub {
    my ( $self ) = @_;

    # check table
    while( my ( $table, $table_ref ) = each %{ $self->{ tables } } ) {

        # determine primary keys
        my @check_pk = ( 'hash' );
        push @check_pk, 'range'
            if defined $table_ref->{ range_key };

        # check primary keys
        foreach my $check_pk( @check_pk ) {
            my $key_pk = "${check_pk}_key";
            my $name_pk = $table_ref->{ $key_pk };
            croak "Missing '$key_pk' attribute in '$table' table definition\n"
                unless defined $table_ref->{ $key_pk };
            croak "Missing $check_pk key attribute in '$table' table attribute declaration: "
                . "{ $table => { attributes => { '$name_pk' => 'S|N' } }\n"
                unless defined $table_ref->{ attributes }->{ $name_pk };
            croak "Wrong data type for $check_pk key attribute. Got '$table_ref->{ attributes }->{ $name_pk }',"
                . " expect 'S' or 'N'"
                unless $table_ref->{ attributes }->{ $name_pk } =~ /^(S|N)$/;
        }

        # check attributes
        while( my( $attr_name, $attr_type ) = each %{ $table_ref->{ attributes } } ) {
            croak "Wrong data type for attribute '$attr_name' in table '$table': Got '$attr_type' was"
                . " expecting 'S' or 'N' or 'SS' or 'NS'"
                unless $attr_type =~ /^[NS]S?$/;
        }
    }

    # no need to go further, if no namespace given
    return unless $self->namespace;

    # update table definitions with namespace
    my %new_table = ();
    my $updated = 0;
    foreach my $table( keys %{ $self->{ tables } } ) {
        my $table_updated = index( $table, $self->namespace ) == 0 ? $table : $self->_table_name( $table );
        $new_table{ $table_updated } = $self->{ tables }->{ $table };
        $updated ++ unless $table_updated eq $table;
    }
    if ( $updated ) {
        $self->{ tables } = \%new_table;
    }
} );

=head2 use_keep_alive

Use keep_alive connections to AWS (Uses C<LWP::ConnCache> experimental mechanism). 0 to disable, positive number sets value for C<LWP::UserAgent> attribute 'keep_alive'
Default: 0

=cut

has use_keep_alive => ( isa => 'Int', is => 'rw', default => 0 );

=head2 lwp

Contains C<LWP::UserAgent> instance.

=cut

has lwp => ( isa => 'LWP::UserAgent', is => 'rw', lazy => 1, default => sub { my ($self) = @_; LWP::UserAgent->new( timeout => 5, keep_alive => $self->use_keep_alive ) } );
has _lwpcache => ( isa => 'LWP::ConnCache', is => 'ro', lazy => 1, default => sub { my ($self) = @_; $self->lwp->conn_cache(); } );

=head2 json

Contains C<JSON> instance for decoding/encoding json.

JSON object needs to support: canonical, allow_nonref and utf8

=cut

has json => ( isa => 'JSON', is => 'rw', default => sub { JSON->new()->canonical( 1 )->allow_nonref( 1 )->utf8( 1 ) }, trigger => sub {
    shift->json->canonical( 1 )->allow_nonref( 1 )->utf8( 1 );
} );

=head2 host

DynamoDB API Hostname

Default: dynamodb.us-east-1.amazonaws.com

=cut

has host => ( isa => 'Str', is => 'rw', default => 'dynamodb.us-east-1.amazonaws.com' );

=head2 access_key

AWS API access key

Required!

=cut

has access_key => ( isa => 'Str', is => 'rw', required => 1 );

=head2 secret_key

AWS API secret key

Required!

=cut

has secret_key => ( isa => 'Str', is => 'rw', required => 1 );

=head2 api_version

AWS API Version. Use format "YYYYMMDD"

Default: 20111205

=cut

has api_version => ( isa => 'Str', is => 'rw', default => '20111205' );

=head2 read_consistent

Whether reads (get_item, batch_get_item) consistent per default or not. This does not affect scan_items or query_items, which are always eventually consistent.

Default: 0 (eventually consistent)

=cut

has read_consistent => ( isa => 'Bool', is => 'rw', default => 0 );

=head2 namespace

Table prefix, prepended before table name on usage

Default: ''

=cut

has namespace => ( isa => 'Str', is => 'ro', default => '' );

=head2 raise_error

Whether database errors (eg 4xx Response from DynamoDB) raise errors or not.

Default: 0

=cut

has raise_error => ( isa => 'Bool', is => 'rw', default => 0 );

=head2 max_retries

Amount of retries a query will be tries if ProvisionedThroughputExceededException is raised until final error.

Default: 0 (do only once, no retries)

=cut

has max_retries => ( isa => 'Int', is => 'rw', default => 1 );

=head2 derive_table

Whether we parse results using table definition (faster) or without a known definition (still requires table definition for indexes)

Default: 0

=cut

has derive_table => ( isa => 'Bool', is => 'rw', default => 0 );

=head2 retry_timeout

Wait period in seconds between tries. Float allowed.

Default: 0.1 (100ms)

=cut

has retry_timeout => ( isa => 'Num', is => 'rw', default => 0.1 );

=head2 cache

Cache object using L<Cache> interface, eg L<Cache::File> or L<Cache::Memcached>

If set, caching is used for get_item, put_item, update_item and batch_get_item.

Default: -

=cut

has cache => ( isa => 'Cache', is => 'rw', predicate => 'has_cache' );

=head2 cache_disabled

If cache is set, you still can disable it per default and enable it per operation with "use_cache" option (see method documentation)
This way you have a default no-cache policy, but still can use cache in choosen operations.

Default: 0

=cut

has cache_disabled => ( isa => 'Bool', is => 'rw', default => 0 );

=head2 cache_key_method

Which one to use. Either sha1_hex, sha256_hex, sha384_hex or coderef

Default: sha1_hex

=cut

has cache_key_method => ( is => 'rw', default => sub { \&Digest::SHA::sha1_hex }, trigger => sub {
    my ( $self, $method ) = @_;
    if ( ( ref( $method ) ) ne 'CODE' ) {
        if ( $method eq 'sha1_hex' ) {
            $self->{ cache_key_method } = \&Digest::SHA::sha1_hex();
        }
        elsif ( $method eq 'sha256_hex' ) {
            $self->{ cache_key_method } = \&Digest::SHA::sha256_hex();
        }
        elsif ( $method eq 'sha384_hex' ) {
            $self->{ cache_key_method } = \&Digest::SHA::sha384_hex();
        }
    }
} );

#
# _aws_signer
#   Contains C<Net::Amazon::AWSSign> instance.
#

has _aws_signer => ( isa => 'Net::Amazon::AWSSign', is => 'rw', predicate => '_has_aws_signer' );

#
# _security_token_url
#   URL for receiving security token
#

has _security_token_url => ( isa => 'Str', is => 'rw', default => 'https://sts.amazonaws.com/?Action=GetSessionToken&Version=2011-06-15' );

#
# _credentials
#   Contains credentials received by GetSession
#

has _credentials => ( isa => 'HashRef[Str]', is => 'rw', predicate => '_has_credentials' );

#
# _credentials_expire
#   Time of credentials exiration
#

has _credentials_expire => ( isa => 'DateTime', is => 'rw' );

#
# _error
#   Contains credentials received by GetSession
#

has _error => ( isa => 'Str', is => 'rw', predicate => '_has_error' );

=head1 METHODS


=head2 create_table $table_name, $read_amount, $write_amount

Create a new Table. Returns description of the table

    my $desc_ref = $ddb->create_table( 'table_name', 10, 5 )
    $desc_ref = {
        count           => 123,         # amount of "rows"
        status          => 'CREATING',  # or 'ACTIVE' or 'UPDATING' or some error state?
        created         => 1328893776,  # timestamp
        read_amount     => 10,          # amount of read units
        write_amount    => 5,           # amount of write units
        hash_key        => 'id',        # name of the hash key attribute
        hash_key_type   => 'S',         # or 'N',
        #range_key      => 'id',        # name of the hash key attribute (optional)
        #range_key_type => 'S',         # or 'N' (optional)
    }

=cut

sub create_table {
    my ( $self, $table, $read_amount, $write_amount ) = @_;
    $table = $self->_table_name( $table );
    $read_amount ||= 10;
    $write_amount ||= 5;

    # check & get table definition
    my $table_ref = $self->_check_table( "create_table", $table );

    # init create definition
    my %create = (
        TableName => $table,
        ProvisionedThroughput => {
            ReadCapacityUnits  => $read_amount + 0,
            WriteCapacityUnits => $write_amount + 0,
        }
    );

    # build keys
    $create{ KeySchema } = {
        HashKeyElement => {
            AttributeName => $table_ref->{ hash_key },
            AttributeType => $table_ref->{ attributes }->{ $table_ref->{ hash_key } }
        }
    };
    if ( defined $table_ref->{ range_key } ) {
        $create{ KeySchema }->{ RangeKeyElement } = {
            AttributeName => $table_ref->{ range_key },
            AttributeType => $table_ref->{ attributes }->{ $table_ref->{ range_key } }
        };
    }

    # perform create
    my ( $res, $res_ok, $json_ref ) = $self->request( CreateTable => \%create );

    # got res
    if ( $res_ok && defined $json_ref->{ TableDescription } ) {
        return {
            status        => $json_ref->{ TableDescription }->{ TableStatus },
            created       => int( $json_ref->{ TableDescription }->{ CreationDateTime } ),
            read_amount   => $json_ref->{ TableDescription }->{ ProvisionedThroughput }->{ ReadCapacityUnits },
            write_amount  => $json_ref->{ TableDescription }->{ ProvisionedThroughput }->{ WriteCapacityUnits },
            hash_key      => $json_ref->{ Table }->{ KeySchema }->{ HashKeyElement }->{ AttributeName },
            hash_key_type => $json_ref->{ Table }->{ KeySchema }->{ HashKeyElement }->{ AttributeType },
            ( defined $json_ref->{ Table }->{ KeySchema }->{ RangeKeyElement }
                ? (
                    range_key      => $json_ref->{ Table }->{ KeySchema }->{ RangeKeyElement }->{ AttributeName },
                    range_key_type => $json_ref->{ Table }->{ KeySchema }->{ RangeKeyElement }->{ AttributeType },
                )
                : ()
            ),
        }
    }

    # set error
    $self->error( 'create_table failed: '. $self->_extract_error_message( $res ) );
    return ;
}



=head2 delete_table $table

Delete an existing (and defined) table.

Returns bool whether table is now in deleting state (succesfully performed)

=cut

sub delete_table {
    my ( $self, $table ) = @_;
    $table = $self->_table_name( $table );

    # check & get table definition
    my $table_ref = $self->_check_table( delete_table => $table );

    # perform create
    my ( $res, $res_ok, $json_ref ) = $self->request( DeleteTable => { TableName => $table } );

    # got result
    if ( $res_ok && defined $json_ref->{ TableDescription } ) {
        return $json_ref->{ TableDescription }->{ TableStatus } eq 'DELETING';
    }

    # set error
    $self->error( 'delete_table failed: '. $self->_extract_error_message( $res ) );
    return ;
}



=head2 describe_table $table

Returns table information

    my $desc_ref = $ddb->describe_table( 'my_table' );
    $desc_ref = {
        existing        => 1,
        size            => 123213,      # data size in bytes
        count           => 123,         # amount of "rows"
        status          => 'ACTIVE',    # or 'DELETING' or 'CREATING' or 'UPDATING' or some error state
        created         => 1328893776,  # timestamp
        read_amount     => 10,          # amount of read units
        write_amount    => 5,           # amount of write units
        hash_key        => 'id',        # name of the hash key attribute
        hash_key_type   => 'S',         # or 'N',
        #range_key      => 'id',        # name of the hash key attribute (optional)
        #range_key_type => 'S',         # or 'N' (optional)
    }

If no such table exists, return is

    {
        existing => 0
    }

=cut

sub describe_table {
    my ( $self, $table ) = @_;
    $table = $self->_table_name( $table );

    # check table definition
    $self->_check_table( "describe_table", $table );

    my ( $res, $res_ok, $json_ref ) = $self->request( DescribeTable => { TableName => $table } );
    # got result
    if ( $res_ok ) {
        if ( defined $json_ref->{ Table } ) {
            no warnings 'uninitialized';
            return {
                existing      => 1,
                size          => $json_ref->{ Table }->{ TableSizeBytes },
                count         => $json_ref->{ Table }->{ ItemCount },
                status        => $json_ref->{ Table }->{ TableStatus },
                created       => int( $json_ref->{ Table }->{ CreationDateTime } ),
                read_amount   => $json_ref->{ Table }->{ ProvisionedThroughput }->{ ReadCapacityUnits },
                write_amount  => $json_ref->{ Table }->{ ProvisionedThroughput }->{ WriteCapacityUnits },
                hash_key      => $json_ref->{ Table }->{ KeySchema }->{ HashKeyElement }->{ AttributeName },
                hash_key_type => $json_ref->{ Table }->{ KeySchema }->{ HashKeyElement }->{ AttributeType },
                ( defined $json_ref->{ Table }->{ KeySchema }->{ RangeKeyElement }
                    ? (
                        range_key      => $json_ref->{ Table }->{ KeySchema }->{ RangeKeyElement }->{ AttributeName },
                        range_key_type => $json_ref->{ Table }->{ KeySchema }->{ RangeKeyElement }->{ AttributeType },
                    )
                    : ()
                ),
            };
        }
        else {
            return {
                existing => 0
            }
        }
    }

    # set error
    $self->error( 'describe_table failed: '. $self->_extract_error_message( $res ) );
    return ;
}


=head2 update_table $table, $read_amount, $write_amount

Update read and write amount for a table

=cut

sub update_table {
    my ( $self, $table, $read_amount, $write_amount ) = @_;
    $table = $self->_table_name( $table );

    my ( $res, $res_ok, $json_ref ) = $self->request( UpdateTable => {
        TableName             => $table,
        ProvisionedThroughput => {
            ReadCapacityUnits  => $read_amount + 0,
            WriteCapacityUnits => $write_amount + 0,
        }
    } );

    if ( $res_ok ) {
        return 1;
    }

    # set error
    $self->error( 'update_table failed: '. $self->_extract_error_message( $res ) );
    return ;
}



=head2 exists_table $table

Returns bool whether table exists or not

=cut

sub exists_table {
    my ( $self, $table ) = @_;
    $table = $self->_table_name( $table );

    # check table definition
    $self->_check_table( "exists_table", $table );

    my ( $res, $res_ok, $json_ref );
    eval {
        ( $res, $res_ok, $json_ref ) = $self->request( DescribeTable => { TableName => $table } );
    };

    return defined $json_ref->{ Table } && defined $json_ref->{ Table }->{ ItemCount } ? 1 : 0
        if $res_ok;

    # set error
    return 0;
}



=head2 list_tables

Returns tables names as arrayref (or array in array context)

=cut

sub list_tables {
    my ( $self ) = @_;

    my ( $res, $res_ok, $json_ref ) = $self->request( ListTables => {} );
    if ( $res_ok ) {
        my $ns_length = length( $self->namespace );
        my @table_names = map {
            substr( $_, $ns_length );
        } grep {
            ! $self->namespace || index( $_, $self->namespace ) == 0
        } @{ $json_ref->{ TableNames } };
        return wantarray ? @table_names : \@table_names;
    }

    # set error
    $self->error( 'list_tables failed: '. $self->_extract_error_message( $res ) );
    return ;
}



=head2 put_item $table, $item_ref, [$where_ref], [$args_ref]

Write a single item to table. All primary keys are required in new item.

    # just write
    $ddb->put_item( my_table => {
        id => 123,
        some_attrib => 'bla',
        other_attrib => 'dunno'
    } );

    # write conditionally
    $ddb->put_item( my_table => {
        id => 123,
        some_attrib => 'bla',
        other_attrib => 'dunno'
    }, {
        some_attrib => { # only update, if some_attrib has the value 'blub'
            value => 'blub'
        },
        other_attrib => { # only update, if a value for other_attrib exists
            exists => 1
        }
    } );

=over

=item * $table

Name of the table

=item * $item_ref

Hashref containing the values to be inserted

=item * $where_ref [optional]

Filter containing expected values of the (existing) item to be updated

=item * $args_ref [optional]

HashRef with options

=over

=item * return_old

If true, returns old value

=item * no_cache

Force not using cache, if enabled per default

=item * use_cache

Force using cache, if disabled per default but setupped

=back

=back

=cut

sub put_item {
    my ( $self, $table, $item_ref, $where_ref, $args_ref ) = @_;
    $args_ref ||= {
        return_old  => 0,
        no_cache    => 0,
        use_cache   => 0,
        max_retries => undef
    };
    $table = $self->_table_name( $table );

    # check definition
    my $table_ref = $self->_check_table( "put_item", $table );

    # check primary keys
    croak "put_item: Missing value for hash key '$table_ref->{ hash_key }'"
        unless defined $item_ref->{ $table_ref->{ hash_key } }
        && length( $item_ref->{ $table_ref->{ hash_key } } );

    # check other attributes
    $self->_check_keys( "put_item: item values", $table, $item_ref );

    # having where -> check now
    $self->_check_keys( "put_item: where clause", $table, $where_ref ) if $where_ref;

    # build put
    my %put = (
        TableName => $table,
        Item      => {}
    );

    # build the item
    foreach my $key( keys %$item_ref ){
        my $type = $self->_attrib_type( $table, $key );
        my $value;
        if ( $type eq 'SS' || $type eq 'NS' ) {
            my @values = map { $_. '' } ( ref( $item_ref->{ $key } ) ? @{ $item_ref->{ $key } } : () );
            $value = \@values;
        }
        else {
            $value = $item_ref->{ $key } .'';
        }
        $put{ Item }->{ $key } = { $type => $value };
    }

    # build possible where clause
    if ( $where_ref ) {
        $self->_build_attrib_filter( $table, $where_ref, $put{ Expected } = {} );
    }

    # add return value, if set
    $put{ ReturnValues } = 'ALL_OLD' if $args_ref->{ return_old };

    # perform create
    my ( $res, $res_ok, $json_ref ) = $self->request( PutItem => \%put, {
        max_retries => $args_ref->{ max_retries },
    } );

    # get result
    if ( $res_ok ) {

        # clear cache
        if ( $self->_cache_enabled( $args_ref ) ) {
            my $cache_key = $self->_cache_key_single( $table, $item_ref );
            $self->cache->remove( $cache_key );
        }

        if ( $args_ref->{ return_old } ) {
            return defined $json_ref->{ Attributes }
                ? $self->_format_item( $table, $json_ref->{ Attributes } )
                : undef;
        }
        else {
            return $json_ref->{ ConsumedCapacityUnits } > 0;
        }
    }

    # set error
    $self->error( 'put_item failed: '. $self->_extract_error_message( $res ) );
    return ;
}


=head2 batch_write_item $tables_ref, [$args_ref]

Batch put / delete items into one ore more tables.

Caution: Each batch put / delete cannot process more operations than you have write capacity for the table.

Example:

    my ( $ok, $unprocessed_count, $next_query_ref ) = $ddb->batch_write_item( {
        table_name => {
            put => [
                {
                    attrib1 => "Value 1",
                    attrib2 => "Value 2",
                },
                # { .. } ..
            ],
            delete => [
                {
                    hash_key => "Hash Key Value",
                    range_key => "Range Key Value",
                },
                # { .. } ..
            ]
        },
        # table2_name => ..
    } );

    if ( $ok ) {
        if ( $unprocessed_count ) {
            print "Ok, but $unprocessed_count still not processed\n";
            $ddb->batch_write_item( $next_query_ref );
        }
        else {
            print "All processed\n";
        }
    }

=over

=item $tables_ref

HashRef in the form

    { table_name => { put => [ { attribs }, .. ], delete => [ { primary keys } ] } }

=item $args_ref

HashRef

=over

=item * process_all

Keep processing everything which is returned as unprocessed (if you send more operations than your
table has write capability or you surpass the max amount of operations OR max size of request (see AWS API docu)).

Caution: Error handling

Default: 0

=back

=back

=cut

sub batch_write_item {
    my ( $self, $tables_ref, $args_ref ) = @_;
    $args_ref ||= {
        process_all => 0,
        max_retries => undef
    };

    # check definition
    my %table_map;
    foreach my $table( keys %$tables_ref ) {
        $table = $self->_table_name( $table );
        my $table_ref = $self->_check_table( "batch_write_item", $table );
        $table_map{ $table } = $table_ref;
    }

    my %write = ( RequestItems => {} );
    foreach my $table( keys %table_map ) {
        my $table_out = $self->_table_name( $table, 1 );
        my $t_ref = $tables_ref->{ $table_out };
        my $table_requests_ref = $write{ RequestItems }->{ $table } = [];

        foreach my $operation( qw/ put delete / ) {
            next unless defined $t_ref->{ $operation };
            my @operations = ref( $t_ref->{ $operation } ) eq 'ARRAY'
                ? @{ $t_ref->{ $operation } }
                : ( $t_ref->{ $operation } );

            # put ..
            if ( $operation eq 'put' ) {
                foreach my $put_ref( @operations ) {
                    push @$table_requests_ref, { 'PutRequest' => { Item => my $request_ref = {} } };

                    # build the item
                    foreach my $key( keys %$put_ref ){
                        my $type = $self->_attrib_type( $table, $key );
                        my $value;
                        if ( $type eq 'SS' || $type eq 'NS' ) {
                            my @values = map { $_. '' } ( ref( $put_ref->{ $key } ) ? @{ $put_ref->{ $key } } : () );
                            $value = \@values;
                        }
                        else {
                            $value = $put_ref->{ $key } .'';
                        }
                        $request_ref->{ $key } = { $type => $value };
                    }
                }
            }

            # delete ..
            else {
                foreach my $delete_ref( @operations ) {
                    push @$table_requests_ref, { 'DeleteRequest' => { Key => my $request_ref = {} } };
                    $self->_build_pk_filter( $table, $delete_ref, $request_ref );
                }
            }
        }
    }

    # perform create
    my ( $res, $res_ok, $json_ref ) = $self->request( BatchWriteItem => \%write, {
        max_retries => $args_ref->{ max_retries },
    } );

    # having more to process
    while ( $args_ref->{ process_all }
        && $res_ok
        && defined $json_ref->{ UnprocessedItems }
        && scalar( keys %{ $json_ref->{ UnprocessedItems } } )
    ) {
        ( $res, $res_ok, $json_ref ) = $self->request( BatchWriteItem => {
            RequestItems => $json_ref->{ UnprocessedItems }
        }, {
            max_retries => $args_ref->{ max_retries },
        } );
    }

    # count unprocessed
    my $unprocessed_count = 0;
    my %next_query;
    if ( $res_ok && defined $json_ref->{ UnprocessedItems } ) {
        foreach my $table( keys %{ $json_ref->{ UnprocessedItems } } ) {
            my @operations = @{ $json_ref->{ UnprocessedItems }->{ $table } };
            next unless @operations;
            $unprocessed_count += scalar( @operations );
            $next_query{ $table } = {};
            foreach my $operation_ref( @operations ) {
                my ( $item_ref, $operation_name ) = defined $operation_ref->{ PutRequest }
                    ? ( $operation_ref->{ PutRequest }->{ Item }, 'put' )
                    : ( $operation_ref->{ DeleteRequest }->{ Key }, 'delete' );
                #print Dumper( [ $operation_ref, $operation_name, $item_ref ] );
                push @{ $next_query{ $table }->{ $operation_name } ||= [] },
                    $self->_format_item( $table, $item_ref )
            }
        }
    }

    return wantarray ? ( $res_ok, $unprocessed_count, \%next_query ) : $res_ok;
}



=head2 update_item $table, $update_ref, $where_ref, [$args_ref]

Update existing item in database. All primary keys are required in where clause

    # update existing
    $ddb->update_item( my_table => {
        some_attrib => 'bla',
        other_attrib => 'dunno'
    }, {
        id => 123,
    } );

    # write conditionally
    $ddb->update_item( my_table => {
        some_attrib => 'bla',
        other_attrib => 'dunno'
    }, {
        id => 123,
        some_attrib => { # only update, if some_attrib has the value 'blub'
            value => 'blub'
        },
        other_attrib => { # only update, if a value for other_attrib exists
            exists => 1
        }
    } );

=over

=item * $table

Name of the table

=item * $update_ref

Hashref containing the updates.

=over

=item * delete a single values

    { attribname => undef }

=item * replace a values

    {
        attribname1 => 'somevalue',
        attribname2 => [ 1, 2, 3 ]
    }

=item * add values (arrays only)

    { attribname => \[ 4, 5, 6 ] }

=back

=item * $where_ref [optional]

Filter HashRef

=item * $args_ref [optional]

HashRef of options

=over

=item * return_mode

Can be set to on of "ALL_OLD", "UPDATED_OLD", "ALL_NEW", "UPDATED_NEW"

=item * no_cache

Force not using cache, if enabled per default

=item * use_cache

Force using cache, if disabled per default but setupped

=back

=back

=cut

sub update_item {
    my ( $self, $table, $update_ref, $where_ref, $args_ref ) = @_;
    $args_ref ||= {
        return_mode => '',
        no_cache    => 0,
        use_cache   => 0,
        max_retries => undef
    };
    $table = $self->_table_name( $table );

    # check definition
    my $table_ref = $self->_check_table( "update_item", $table );

    croak "update_item: Cannot update hash key value, do not set it in update-clause"
        if defined $update_ref->{ $table_ref->{ hash_key } };

    croak "update_item: Cannot update range key value, do not set it in update-clause"
        if defined $table_ref->{ range_key }
        && defined $update_ref->{ $table_ref->{ range_key } };

    # check primary keys
    croak "update_item: Missing value for hash key '$table_ref->{ hash_key }' in where-clause"
        unless defined $where_ref->{ $table_ref->{ hash_key } }
        && length( $where_ref->{ $table_ref->{ hash_key } } );
    croak "update_item: Missing value for range key '$table_ref->{ hash_key }' in where-clause"
        if defined $table_ref->{ range_key } && !(
            defined $where_ref->{ $table_ref->{ range_key } }
            && length( $where_ref->{ $table_ref->{ range_key } } )
        );

    # check other attributes
    $self->_check_keys( "update_item: item values", $table, $update_ref );
    croak "update_item: Cannot update hash key '$table_ref->{ hash_key }'. You have to delete and put the item!"
        if defined $update_ref->{ $table_ref->{ hash_key } };
    croak "update_item: Cannot update range key '$table_ref->{ hash_key }'. You have to delete and put the item!"
        if defined $table_ref->{ range_key } && defined $update_ref->{ $table_ref->{ range_key } };

    # having where -> check now
    $self->_check_keys( "update_item: where clause", $table, $where_ref );

    # build put
    my %update = (
        TableName        => $table,
        AttributeUpdates => {},
        Key              => {}
    );

    # build the item
    foreach my $key( keys %$update_ref ) {
        my $type = $self->_attrib_type( $table, $key );
        my $value = $update_ref->{ $key };

        # delete
        if ( ! defined $value ) {
            $update{ AttributeUpdates }->{ $key } = {
                Action => 'DELETE'
            };
        }

        # if ++N or --N on numeric type, ADD to get inc/dec behavior
        elsif ( $type eq 'N' && $value =~ /^(--|\+\+)(\d+)$/ ) {
            $update{ AttributeUpdates }->{ $key } = {
                Value  => { $type => ($1 eq '--') ? "-$2" : "$2" },
                Action => 'ADD'
            };
        }

        # replace for scalar
        elsif ( $type eq 'N' || $type eq 'S' ) {
            $update{ AttributeUpdates }->{ $key } = {
                Value  => { $type => $value. '' },
                Action => 'PUT'
            };
        }

        # replace or add for array types
        elsif ( $type =~ /^[NS]S$/ ) {

            # add \[ qw/ value1 value2 / ]
            if ( ref( $value ) eq 'REF' ) {
                $update{ AttributeUpdates }->{ $key } = {
                    Value  => { $type => [ map { "$_" } @$$value ] },
                    Action => 'ADD'
                };
            }

            # replace [ qw/ value1 value2 / ]
            else {
                $update{ AttributeUpdates }->{ $key } = {
                    Value  => { $type => [ map { "$_" } @$value ] },
                    Action => 'PUT'
                };
            }
        }
    }

    # build possible where clause
    my %where = %$where_ref;

    # primary key
    $self->_build_pk_filter( $table, \%where, $update{ Key } );

    # additional filters
    if ( keys %where ) {
        $self->_build_attrib_filter( $table, \%where, $update{ Expected } = {} );
    }

    # add return value, if set
    if ( $args_ref->{ return_mode } ) {
        $update{ ReturnValues } = "$args_ref->{ return_mode }" =~ /^(?:ALL_OLD|UPDATED_OLD|ALL_NEW|UPDATED_NEW)$/i
            ? uc( $args_ref->{ return_mode } )
            : "ALL_OLD";
    }

    # perform create
    my ( $res, $res_ok, $json_ref ) = $self->request( UpdateItem => \%update, {
        max_retries => $args_ref->{ max_retries },
    } );

    # get result
    if ( $res_ok ) {

        # clear cache
        if ( $self->_cache_enabled( $args_ref ) ) {
            my $cache_key = $self->_cache_key_single( $table, $where_ref );
            $self->cache->remove( $cache_key );
        }

        if ( $args_ref->{ return_mode } ) {
            return defined $json_ref->{ Attributes }
                ? $self->_format_item( $table, $json_ref->{ Attributes } )
                : undef;
        }
        else {
            return $json_ref->{ ConsumedCapacityUnits } > 0;
        }
    }

    # set error
    $self->error( 'put_item failed: '. $self->_extract_error_message( $res ) );
    return ;
}



=head2 get_item $table, $pk_ref, [$args_ref]

Read a single item by hash (and range) key.

    # only with hash key
    my $item1 = $ddb->get_item( my_table => { id => 123 } );
    print "Got $item1->{ some_key }\n";

    # with hash and range key, also consistent read and only certain attributes in return
    my $item2 = $ddb->get_item( my_other_table =>, {
        id    => $hash_value, # the hash value
        title => $range_value # the range value
    }, {
        consistent => 1,
        attributes => [ qw/ attrib1 attrib2 ]
    } );
    print "Got $item2->{ attrib1 }\n";

=over

=item * $table

Name of the table

=item * $pk_ref

HashRef containing all primary keys

    # only hash key
    {
        $hash_key => $hash_value
    }

    # hash and range key
    {
        $hash_key => $hash_value,
        $range_key => $range_value
    }


=item * $args_ref [optional]

HashRef of options

=over

=item * consistent

Whether read shall be consistent. If set to 0 and read_consistent is globally enabled, this read will not be consistent

=item * attributes

ArrayRef of attributes to read. If not set, all attributes are returned.

=item * no_cache

Force not using cache, if enabled per default

=item * use_cache

Force using cache, if disabled per default but setupped

=back

=back

=cut

sub get_item {
    my ( $self, $table, $pk_ref, $args_ref ) = @_;
    $table = $self->_table_name( $table );
    $args_ref ||= {
        consistent  => undef,
        attributes  => undef,
        no_cache    => 0,
        use_cache   => 0,
        max_retries => undef
    };
    $args_ref->{ consistent } //= $self->read_consistent;

    # check definition
    my $table_ref = $self->_check_table( "get_item", $table );

    # check primary keys
    croak "get_item: Missing value for hash key '$table_ref->{ hash_key }'"
        unless defined $pk_ref->{ $table_ref->{ hash_key } }
        && length( $pk_ref->{ $table_ref->{ hash_key } } );
    croak "get_item: Missing value for Range Key '$table_ref->{ range_key }'"
        if defined $table_ref->{ range_key } && !(
            defined $pk_ref->{ $table_ref->{ range_key } }
            && length( $pk_ref->{ $table_ref->{ hash_key } } )
        );

    # use cache
    my $use_cache = $self->_cache_enabled( $args_ref );
    my $cache_key;
    if ( $use_cache ) {
        $cache_key = $self->_cache_key_single( $table, $pk_ref );
        my $cached = $self->cache->thaw( $cache_key );
        return $cached if defined $cached;
    }


    # build get
    my %get = (
        TableName => $table,
        ( defined $args_ref->{ attributes } ? ( AttributesToGet => $args_ref->{ attributes } ) : () ),
        ConsistentRead => $args_ref->{ consistent } ? \1 : \0,
        Key => {
            HashKeyElement => {
                $self->_attrib_type( $table, $table_ref->{ hash_key } ) =>
                    $pk_ref->{ $table_ref->{ hash_key } }
            }
        }
    );

    # add range key ?
    if ( defined $table_ref->{ range_key } ) {
        $get{ Key }->{ RangeKeyElement } = {
            $self->_attrib_type( $table, $table_ref->{ range_key } ) =>
                    $pk_ref->{ $table_ref->{ range_key } }
        };
    }

    # perform create
    my ( $res, $res_ok, $json_ref ) = $self->request( GetItem => \%get, {
        max_retries => $args_ref->{ max_retries },
    } );

    # return on success
    my $item_ref = $self->_format_item( $table, $json_ref->{ Item } ) if $res_ok && defined $json_ref->{ Item };
    if ( $use_cache ) {
        $self->cache->freeze( $cache_key, $item_ref ) if $item_ref;
    }
    return $item_ref;

    # return on success, but nothing received
    return undef if $res_ok;

    # set error
    $self->error( 'get_item failed: '. $self->_extract_error_message( $res ) );
    return ;
}



=head2 batch_get_item $tables_ref, [$args_ref]

Read multiple items (possible accross multiple tables) identified by their hash and range key (if required).

    my $res = $ddb->batch_get_item( {
        table_name => [
            { $hash_key => $value1 },
            { $hash_key => $value2 },
            { $hash_key => $value3 },
        ],
        other_table_name => {
            keys => [
                { $hash_key => $value1, $range_key => $rvalue1 },
                { $hash_key => $value2, $range_key => $rvalue2 },
                { $hash_key => $value3, $range_key => $rvalue3 },
            ],
            attributes => [ qw/ attrib1 attrib2 / ]
        ]
    } );

    foreach my $table( keys %$res ) {
        foreach my $item( @{ $res->{ $table } } ) {
            print "$item->{ some_attrib }\n";
        }
    }

=over

=item $tables_ref

HashRef of tablename => primary key ArrayRef

=item $args_ref

HashRef

=over

=item * process_all

Batch request might not fetch all requested items at once. This switch enforces
to batch get the unprocessed items.

Default: 0

=back

=back



=cut

sub batch_get_item {
    my ( $self, $tables_ref, $args_ref ) = @_;
    $args_ref ||= {
        max_retries => undef,
        process_all => undef,
        consistent  => undef
    };
    $args_ref->{ consistent } //= $self->read_consistent();

    # check definition
    my %table_map;
    foreach my $table( keys %$tables_ref ) {
        $table = $self->_table_name( $table );
        my $table_ref = $self->_check_table( "batch_get_item", $table );
        $table_map{ $table } = $table_ref;
    }

    my %get = ( RequestItems => {} );
    foreach my $table( keys %table_map ) {
        my $table_out = $self->_table_name( $table, 1 );
        my $t_ref = $tables_ref->{ $table_out };

        # init items for table
        $get{ RequestItems }->{ $table } = {};

        # init / get keys
        my $k_ref = $get{ RequestItems }->{ $table }->{ Keys } = [];
        my @keys = ref( $t_ref ) eq 'ARRAY'
            ? @$t_ref
            : @{ $t_ref->{ keys } };

        # get mapping for table
        my $m_ref = $table_map{ $table };

        # get hash key
        my $hash_key = $m_ref->{ hash_key };
        my $hash_key_type = $self->_attrib_type( $table, $hash_key );

        # get range key?
        my ( $range_key, $range_key_type );
        if ( defined $m_ref->{ range_key } ) {
            $range_key = $m_ref->{ range_key };
            $range_key_type = $self->_attrib_type( $table, $range_key );
        }

        # build request items
        foreach my $key_ref( @keys ) {
            push @$k_ref, {
                HashKeyElement => { $hash_key_type => $key_ref->{ $hash_key }. '' },
                ( defined $range_key ? ( RangeKeyElement => { $range_key_type => $key_ref->{ $range_key }. '' } ) : () )
            };
        }

        # having attributes limitation?
        if ( ref( $t_ref ) eq 'HASH' && defined $t_ref->{ attributes } ) {
            $get{ RequestItems }->{ $table }->{ AttributesToGet } = $t_ref->{ attributes };
        }

        # using consistent read?
        if ( $args_ref->{ consistent } ) {
            $get{ RequestItems }->{ $table }->{ ConsistentRead } = \1;
        }
    }

    # perform create
    my ( $res, $res_ok, $json_ref ) = $self->request( BatchGetItem => \%get, {
        max_retries => $args_ref->{ max_retries },
    } );

    # return on success
    if ( $res_ok && defined $json_ref->{ Responses } ) {

        if ( $args_ref->{ process_all } && defined( my $ukeys_ref = $json_ref->{ UnprocessedKeys } ) ) {
            while ( $ukeys_ref ) {
                ( $res, $res_ok, my $ujson_ref ) = $self->request( BatchGetItem =>
                    {
                        RequestItems => $ukeys_ref
                    }, {
                        max_retries => $args_ref->{ max_retries },
                    } );
                if ( $res_ok && defined $ujson_ref->{ Responses } ) {
                    foreach my $table_out( keys %$tables_ref ) {
                        my $table = $self->_table_name( $table_out );
                        if ( defined $ujson_ref->{ Responses }->{ $table } && defined $ujson_ref->{ Responses }->{ $table }->{ Items } ) {
                            $json_ref->{ Responses }->{ $table } ||= {};
                            push @{ $json_ref->{ Responses }->{ $table }->{ Items } ||= [] },
                                @{ $ujson_ref->{ Responses }->{ $table }->{ Items } };
                        }
                    }
                }
                $ukeys_ref = $res_ok && defined $ujson_ref->{ UnprocessedKeys }
                    ? $ujson_ref->{ UnprocessedKeys }
                    : undef;
            }
        }

        my %res;
        foreach my $table_out( keys %$tables_ref ) {
            my $table = $self->_table_name( $table_out );
            next unless defined $json_ref->{ Responses }->{ $table } && defined $json_ref->{ Responses }->{ $table }->{ Items };
            my $items_ref = $json_ref->{ Responses }->{ $table };
            $res{ $table_out } = [];
            foreach my $item_ref( @{ $items_ref->{ Items } } ) {
                my %res_item;
                foreach my $attrib( keys %$item_ref ) {
                    my $type = $self->_attrib_type( $table, $attrib );
                    $res_item{ $attrib } = $item_ref->{ $attrib }->{ $type };
                }
                push @{ $res{ $table_out } }, \%res_item;
            }
        }
        return \%res;
    }

    # set error
    $self->error( 'batch_get_item failed: '. $self->_extract_error_message( $res ) );
    return ;
}



=head2 delete_item $table, $where_ref, [$args_ref]

Deletes a single item by primary key (hash or hash+range key).

    # only with hash key

=over

=item * $table

Name of the table

=item * $where_ref

HashRef containing at least primary key. Can also contain additional attribute filters

=item * $args_ref [optional]

HashRef containing options

=over

=item * return_old

Bool whether return old, just deleted item or not

Default: 0

=item * no_cache

Force not using cache, if enabled per default

=item * use_cache

Force using cache, if disabled per default but setupped

=back

=back

=cut

sub delete_item {
    my ( $self, $table, $where_ref, $args_ref ) = @_;
    $args_ref ||= {
        return_old  => 0,
        no_cache    => 0,
        use_cache   => 0,
        max_retries => undef
    };
    $table = $self->_table_name( $table );

    # check definition
    my $table_ref = $self->_check_table( "delete_item", $table );

    # check primary keys
    croak "delete_item: Missing value for hash key '$table_ref->{ hash_key }'"
        unless defined $where_ref->{ $table_ref->{ hash_key } }
        && length( $where_ref->{ $table_ref->{ hash_key } } );
    croak "delete_item: Missing value for Range Key '$table_ref->{ range_key }'"
        if defined $table_ref->{ range_key } && ! (
            defined $where_ref->{ $table_ref->{ range_key } }
            && length( $where_ref->{ $table_ref->{ range_key } } )
        );

    # check other attributes
    $self->_check_keys( "delete_item: where-clause", $table, $where_ref );

    # build delete
    my %delete = (
        TableName    => $table,
        Key          => {},
        ( $args_ref->{ return_old } ? ( ReturnValues => 'ALL_OLD' ) : () )
    );

    # setup pk
    my %where = %$where_ref;

    # for hash key
    my $hash_value = delete $where{ $table_ref->{ hash_key } };
    $delete{ Key }->{ HashKeyElement } = {
        $self->_attrib_type( $table, $table_ref->{ hash_key } ) => $hash_value
    };

    # for range key
    if ( defined $table_ref->{ range_key } ) {
        my $range_value = delete $where{ $table_ref->{ range_key } };
        $delete{ Key }->{ RangeKeyElement } = {
            $self->_attrib_type( $table, $table_ref->{ range_key } ) => $range_value
        };
    }

    # build filter for other attribs
    if ( keys %where ) {
        $self->_build_attrib_filter( $table, \%where, $delete{ Expected } = {} );
    }

    # perform create
    my ( $res, $res_ok, $json_ref ) = $self->request( DeleteItem => \%delete, {
        max_retries => $args_ref->{ max_retries },
    } );

    if ( $res_ok ) {

        # use cache
        if ( $self->_cache_enabled( $args_ref ) ) {
            my $cache_key = $self->_cache_key_single( $table, $where_ref );
            $self->cache->remove( $cache_key );
        }

        if ( defined $json_ref->{ Attributes } ) {
            my %res;
            foreach my $attrib( $self->_attribs( $table ) ) {
                next unless defined $json_ref->{ Attributes }->{ $attrib };
                $res{ $attrib } = $json_ref->{ Attributes }->{ $attrib }->{ $self->_attrib_type( $table, $attrib ) };
            }
            return \%res;
        }
        return {};
    }

    $self->error( 'delete_item failed: '. $self->_extract_error_message( $res ) );
    return;
}



=head2 query_items $table, $where, $args

Search in a table with hash AND range key.

    my ( $count, $items_ref, $next_start_keys_ref )
        = $ddb->qyery_items( some_table => { id => 123, my_range_id => { GT => 5 } } );
    print "Found $count items, where last id is ". $items_ref->[-1]->{ id }. "\n";

    # iterate through al all "pages"
    my $next_start_keys_ref;
    do {
        ( my $count, my $items_ref, $next_start_keys_ref )
            = $ddb->qyery_items( some_table => { id => 123, my_range_id => { GT => 5 } }, {
                start_key => $next_start_keys_ref
            } );
    } while( $next_start_keys_ref );

=over

=item * $table

Name of the table

=item * $where

Search condition. Has to contain a value of the primary key and a search-value for the range key.

Search-value for range key can be formated in two ways

=over

=item * Scalar

Eg

    { $range_key_name => 123 }

Performs and EQ (equal) search

=item * HASHREF

Eg

    { $range_key_name => { GT => 1 } }
    { $range_key_name => { CONTAINS => "Bla" } }
    { $range_key_name => { IN => [ 1, 2, 5, 7 ] } }

See L<http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_Query.html>

=back

=item * $args

    {
        limit => 5,
        consistent => 0,
        backward => 0,
        #start_key =>  { .. }
        attributes => [ qw/ attrib1 attrib2 / ],
        #count => 1
    }

HASHREF containing:

=over

=item * limit

Amount of items to return

Default: unlimited

=item * consistent

If set to 1, consistent read is performed

Default: 0

=item * backward

Whether traverse index backward or forward.

Default: 0 (=forward)

=item * start_key

Contains start key, as return in C<LastEvaluatedKey> from previous query. Allows to iterate above a table in pages.

    { $hash_key => 5, $range_key => "something" }

=item * attributes

Return only those attributes

    [ qw/ attrib attrib2 / ]

=item * count

Instead of returning the actual result, return the count.

Default: 0 (=return result)

=item * all

Iterate through all pages (see link to API above) and return them all.

Can take some time. Also: max_retries might be needed to set, as a scan/query create lot's of read-units, and an immediate reading of the next "pages" lead to an Exception due to too many reads.

Default: 0 (=first "page" of items)

=back

=back


=cut

sub query_items {
    my ( $self, $table, $filter_ref, $args_ref ) = @_;
    my $table_orig = $table;
    $table = $self->_table_name( $table );
    $args_ref ||= {
        limit       => undef,   # amount of items
        consistent  => 0,       # default: eventually, not hard, conistent
        backward    => 0,       # default: forward
        start_key   => undef,   # eg { pk_name => 123, pk_other => 234 }
        attributes  => undef,   # eq [ qw/ attrib1 attrib2 / ]
        count       => 0,       # returns amount instead of the actual result
        all         => 0,       # read all entries (runs possibly multiple queries)
        max_retries => undef,   # overwrite default max rewrites
    };

    # check definition
    croak "query_items: Table '$table' does not exist in table definition"
        unless defined $self->tables->{ $table };
    my $table_ref = $self->tables->{ $table };

    # die "query_items: Can run query_items only on tables with range key! '$table' does not have a range key.."
    #     unless defined $table_ref->{ range_key };

    # build put
    my %query = (
        TableName        => $table,
        ConsistentRead   => $args_ref->{ consistent } ? \1 : \0,
        ScanIndexForward => $args_ref->{ backward } ? \0 : \1,
        ( defined $args_ref->{ limit } ? ( Limit => $args_ref->{ limit } ) : () ),
    );

    # using filter
    my %filter = %$filter_ref;

    if ( defined $filter{ $table_ref->{ hash_key } } ) {
        croak "query_items: Missing hash key value in filter-clause"
            unless defined $filter{ $table_ref->{ hash_key } };
        $query{ HashKeyValue } = {
            $self->_attrib_type( $table, $table_ref->{ hash_key } ) =>
                ( delete $filter{ $table_ref->{ hash_key } } ) . ''
        };
    }

    # adding range to filter
    if ( defined $table_ref->{ range_key }) {
        croak "query_items: Missing range key value in filter-clause"
            unless defined $filter{ $table_ref->{ range_key } };
        # r_ref = { GT => 1 } OR { BETWEEN => [ 1, 5 ] } OR { EQ => [ 1 ] } OR 5 FOR { EQ => 5 }
        my $r_ref = delete $filter{ $table_ref->{ range_key } };
        $r_ref = { EQ => $r_ref } unless ref( $r_ref );
        my ( $op, $vals_ref ) = %$r_ref;
        $vals_ref = [ $vals_ref ] unless ref( $vals_ref );
        my $type = $self->_attrib_type( $table, $table_ref->{ range_key } );
        $query{ RangeKeyCondition } = {
            AttributeValueList => [ map {
                { $type => $_. '' }
            } @$vals_ref ],
            ComparisonOperator => uc( $op )
        };
    }

    # too much keys
    croak "query_items: Cannot use keys ". join( ', ', sort keys %filter ). " in in filter - only hash and range key allowed."
        if keys %filter;


    # with start key?
    if( defined( my $start_key_ref = $args_ref->{ start_key } ) ) {
        $self->_check_keys( "query_items: start_key", $table, $start_key_ref );
        my $e_ref = $query{ ExclusiveStartKey } = {};

        # add hash key
        if ( defined $start_key_ref->{ $table_ref->{ hash_key } } ) {
            my $type = $self->_attrib_type( $table, $table_ref->{ hash_key } );
            $e_ref->{ HashKeyElement } = { $type => $start_key_ref->{ $table_ref->{ hash_key } } };
        }

        # add range key?
        if ( defined $table_ref->{ range_key } && defined $start_key_ref->{ $table_ref->{ range_key } } ) {
            my $type = $self->_attrib_type( $table, $table_ref->{ range_key } );
            $e_ref->{ RangeKeyElement } = { $type => $start_key_ref->{ $table_ref->{ range_key } } };
        }
    }

    # only certain attributes
    if ( defined( my $attribs_ref = $args_ref->{ attributes } ) ) {
        my @keys = $self->_check_keys( "query_items: attributes", $table, $attribs_ref );
        $query{ AttributesToGet } = \@keys;
    }

    # or count?
    elsif ( $args_ref->{ count } ) {
        $query{ Count } = \1;
    }

    # perform query
    #print Dumper( { QUERY => \%query } );
    my ( $res, $res_ok, $json_ref ) = $self->request( Query => \%query, {
        max_retries => $args_ref->{ max_retries },
    } );

    # format & return result
    if ( $res_ok && defined $json_ref->{ Items } ) {
        my @res;
        foreach my $from_ref( @{ $json_ref->{ Items } } ) {
            push @res, $self->_format_item( $table, $from_ref );
        }
        my $count = $json_ref->{ Count };

        # build start key for return or use
        my $next_start_key_ref;
        if ( defined $json_ref->{ LastEvaluatedKey } ) {
            $next_start_key_ref = {};

            # add hash key to start key
            my $hash_type = $self->_attrib_type( $table, $table_ref->{ hash_key } );
            $next_start_key_ref->{ $table_ref->{ hash_key } } = $json_ref->{ LastEvaluatedKey }->{ HashKeyElement }->{ $hash_type };

            # add range key to start key
            if ( defined $table_ref->{ range_key } && defined $json_ref->{ LastEvaluatedKey }->{ RangeKeyElement } ) {
                my $range_type = $self->_attrib_type( $table, $table_ref->{ range_key } );
                $next_start_key_ref->{ $table_ref->{ range_key } } = $json_ref->{ LastEvaluatedKey }->{ RangeKeyElement }->{ $range_type };
            }
        }

        # cycle through all?
        if ( $args_ref->{ all } && $next_start_key_ref ) {

            # make sure we do not run into a loop by comparing last and current start key
            my $new_start_key = join( ';', map { sprintf( '%s=%s', $_, $next_start_key_ref->{ $_ } ) } sort keys %$next_start_key_ref );
            my %key_cache     = defined $args_ref->{ _start_key_cache } ? %{ $args_ref->{ _start_key_cache } } : ();
            #print Dumper( { STARTKEY => $next_start_key_ref, LASTEVAL => $json_ref->{ LastEvaluatedKey }, KEYS => [ \%key_cache, $new_start_key ] } );

            if ( ! defined $key_cache{ $new_start_key } ) {
                $key_cache{ $new_start_key } = 1;

                # perform sub-query
                my ( $sub_count, $sub_res_ref ) = $self->query_items( $table_orig, $filter_ref, {
                    %$args_ref,
                    _start_key_cache => \%key_cache,
                    start_key        => $next_start_key_ref
                } );
                #print Dumper( { SUB_COUNT => $sub_count } );

                # add result
                if ( $sub_count ) {
                    $count += $sub_count;
                    push @res, @$sub_res_ref;
                }
            }
        }

        return wantarray ? ( $count, \@res, $next_start_key_ref ) : \@res;
    }

    # error
    $self->error( 'query_items failed: '. $self->_extract_error_message( $res ) );
    return;
}



=head2 scan_items $table, $filter, $args

Performs scan on table. The result is B<eventually consistent>. Non hash or range keys are allowed in the filter.

See query_items for argument description.

Main difference to query_items: A whole table scan is performed, which is much slower. Also the amount of data scanned is limited in size; see L<http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_Scan.html>

=cut

sub scan_items {
    my ( $self, $table, $filter_ref, $args_ref ) = @_;
    my $table_orig = $table;
    $table = $self->_table_name( $table );
    $args_ref ||= {
        limit       => undef,   # amount of items
        start_key   => undef,   # eg { hash_key => 1, range_key => "bla" }
        attributes  => undef,   # eq [ qw/ attrib1 attrib2 / ]
        count       => 0,       # returns amount instead of the actual result
        all         => 0,       # read all entries (runs possibly multiple queries)
        max_retries => undef,   # overwrite default max retries
    };

    # check definition
    croak "scan_items: Table '$table' does not exist in table definition"
        unless defined $self->tables->{ $table };
    my $table_ref = $self->tables->{ $table };

    # build put
    my %query = (
        TableName => $table,
        ScanFilter => {},
        ( defined $args_ref->{ limit } ? ( Limit => $args_ref->{ limit } ) : () ),
    );

    # using filter
    if ( $filter_ref && keys %$filter_ref ) {
        my @filter_keys = $self->_check_keys( "scan_items: filter keys", $table, $filter_ref );
        my $s_ref = $query{ ScanFilter };
        foreach my $key( @filter_keys ) {
            my $type = $self->_attrib_type( $table, $key );
            my $val_ref = $filter_ref->{ $key };
            my $rvalue = ref( $val_ref ) || '';
            if ( $rvalue eq 'HASH' ) {
                my ( $op, $value ) = %$val_ref;
                $s_ref->{ $key } = {
                    AttributeValueList => [ { $type => $value. '' } ],
                    ComparisonOperator => uc( $op )
                };
            }
            elsif( $rvalue eq 'ARRAY' ) {
                $s_ref->{ $key } = {
                    AttributeValueList => [ { $type => $val_ref } ],
                    ComparisonOperator => 'IN'
                };
            }
            else {
                $s_ref->{ $key } = {
                    AttributeValueList => [ { $type => $val_ref. '' } ],
                    ComparisonOperator => 'EQ'
                };
            }
        }
    }

    # with start key?
    if( defined( my $start_key_ref = $args_ref->{ start_key } ) ) {
        $self->_check_keys( "scan_items: start_key", $table, $start_key_ref );
        my $e_ref = $query{ ExclusiveStartKey } = {};

        # add hash key
        if ( defined $start_key_ref->{ $table_ref->{ hash_key } } ) {
            my $type = $self->_attrib_type( $table, $table_ref->{ hash_key } );
            $e_ref->{ HashKeyElement } = { $type => $start_key_ref->{ $table_ref->{ hash_key } } };
        }

        # add range key?
        if ( defined $table_ref->{ range_key } && defined $start_key_ref->{ $table_ref->{ range_key } } ) {
            my $type = $self->_attrib_type( $table, $table_ref->{ range_key } );
            $e_ref->{ RangeKeyElement } = { $type => $start_key_ref->{ $table_ref->{ range_key } } };
        }
    }

    # only certain attributes
    if ( defined( my $attribs_ref = $args_ref->{ attributes } ) ) {
        my @keys = $self->_check_keys( "scan_items: attributes", $table, $attribs_ref );
        $query{ AttributesToGet } = \@keys;
    }

    # or count?
    elsif ( $args_ref->{ count } ) {
        $query{ Count } = \1;
    }

    # perform query
    my ( $res, $res_ok, $json_ref ) = $self->request( Scan => \%query, {
        max_retries => $args_ref->{ max_retries },
    } );

    # format & return result
    if ( $res_ok && defined $json_ref->{ Items } ) {
        my @res;
        foreach my $from_ref( @{ $json_ref->{ Items } } ) {
            push @res, $self->_format_item( $table, $from_ref );
        }

        my $count = $json_ref->{ Count };

        # build start key for return or use
        my $next_start_key_ref;
        if ( defined $json_ref->{ LastEvaluatedKey } ) {
            $next_start_key_ref = {};

            # add hash key to start key
            my $hash_type = $self->_attrib_type( $table, $table_ref->{ hash_key } );
            $next_start_key_ref->{ $table_ref->{ hash_key } } = $json_ref->{ LastEvaluatedKey }->{ HashKeyElement }->{ $hash_type };

            # add range key to start key
            if ( defined $table_ref->{ range_key } && defined $json_ref->{ LastEvaluatedKey }->{ RangeKeyElement } ) {
                my $range_type = $self->_attrib_type( $table, $table_ref->{ range_key } );
                $next_start_key_ref->{ $table_ref->{ range_key } } = $json_ref->{ LastEvaluatedKey }->{ RangeKeyElement }->{ $range_type };
            }
        }

        # cycle through all?
        if ( $args_ref->{ all } && $next_start_key_ref ) {

            # make sure we do not run into a loop by comparing last and current start key
            my $new_start_key = join( ';', map { sprintf( '%s=%s', $_, $next_start_key_ref->{ $_ } ) } sort keys %$next_start_key_ref );
            my %key_cache     = defined $args_ref->{ _start_key_cache } ? %{ $args_ref->{ _start_key_cache } } : ();
            #print Dumper( { STARTKEY => $next_start_key_ref, LASTEVAL => $json_ref->{ LastEvaluatedKey }, KEYS => [ \%key_cache, $new_start_key ] } );

            if ( ! defined $key_cache{ $new_start_key } ) {
                $key_cache{ $new_start_key } = 1;

                # perform sub-query
                my ( $sub_count, $sub_res_ref ) = $self->scan_items( $table_orig, $filter_ref, {
                    %$args_ref,
                    _start_key_cache => \%key_cache,
                    start_key        => $next_start_key_ref
                } );
                #print Dumper( { SUB_COUNT => $sub_count } );

                # add result
                if ( $sub_count ) {
                    $count += $sub_count;
                    push @res, @$sub_res_ref;
                }
            }
        }

        return wantarray ? ( $count, \@res, $next_start_key_ref ) : \@res;
    }

    # error
    $self->error( 'scan_items failed: '. $self->_extract_error_message( $res ) );
    return;
}



=head2 request

Arbitrary request to DynamoDB API

=cut

sub request {
    my ( $self, $target, $json, $args_ref ) = @_;
    $args_ref ||= {
        max_retries => undef
    };

    # assure security token existing
    unless( $self->_init_security_token() ) {
        my %error = ( error => $self->error() );
        return wantarray ? ( undef, 0, \%error ) : \%error;
    }

    # convert to string, if required
    $json = $self->json->encode( $json ) if ref $json;

    # get date
    my $http_date = DateTime::Format::HTTP->format_datetime( DateTime->now );

    # build signable content
    #$json is already utf8 encoded via json encode
    my $sign_content = encode_utf8(join( "\n",
        'POST', '/', '',
        'host:'. $self->host,
        'x-amz-date:'. $http_date,
        'x-amz-security-token:'. $self->_credentials->{ SessionToken },
        'x-amz-target:DynamoDB_20111205.'. $target,
        ''
    )) . "\n" . $json ;
    my $signature = hmac_sha256_base64( sha256( $sign_content ), $self->_credentials->{ SecretAccessKey } );
    $signature .= '=' while( length( $signature ) % 4 != 0 );

    # build request
    my $request = HTTP::Request->new( POST => 'http://'. $self->host. '/' );

    # .. setup headers
    $request->header( host => $self->host );
    $request->header( 'x-amz-date' => $http_date );
    $request->header( 'x-amz-target', 'DynamoDB_'. $self->api_version. '.'. $target );
    $request->header( 'x-amzn-authorization' => join( ',',
        'AWS3 AWSAccessKeyId='. $self->_credentials->{ AccessKeyId },
        'Algorithm=HmacSHA256',
        'SignedHeaders=host;x-amz-date;x-amz-security-token;x-amz-target',
        'Signature='. $signature
    ) );
    $request->header( 'x-amz-security-token' => $self->_credentials->{ SessionToken } );
    $request->header( 'content-type' => 'application/x-amz-json-1.0' );

    # .. add content
    $request->content( $json );

    my ( $json_ref, $response );
    my $tries = defined $args_ref->{ max_retries }
        ? $args_ref->{ max_retries }
        : $self->max_retries + 1;
    while( 1 ) {

        # run request
        $response = $self->lwp->request( $request );
        $ENV{ DYNAMO_DB_DEBUG } && warn Dumper( $response );
        $ENV{ DYNAMO_DB_DEBUG_KEEPALIVE } && warn "  LWP keepalives in use: ", scalar($self->_lwpcache()->get_connections()), "/", $self->_lwpcache()->total_capacity(), "\n";

        # get json
        $json_ref = $response
            ? eval { $self->json->decode( $response->decoded_content ) } || { error => "Failed to parse JSON result" }
            : { error => "Failed to get result" };
        if ( defined $json_ref->{ __type } && $json_ref->{ __type } =~ /ProvisionedThroughputExceededException/ && $tries-- > 0 ) {
            $ENV{ DYNAMO_DB_DEBUG_RETRY } && warn "Retry $target: $json\n";
            usleep( $self->retry_timeout * 1_000_000 );
            next;
        }
        last;
    }


    # handle error
    if ( defined $json_ref->{ error } && $json_ref->{ error } ) {
        $self->error( $json_ref->{ error } );
    }

    # handle exception
    elsif ( defined $json_ref->{ __type } && $json_ref->{ __type } =~ /Exception/ && $json_ref->{ Message } ) {
        $self->error( $json_ref->{ Message } );
    }

    return wantarray ? ( $response, $response ? $response->is_success : 0, $json_ref ) : $json_ref;
}



=head2 error [$str]

Get/set last error

=cut

sub error {
    my ( $self, $str ) = @_;
    if ( $str ) {
        croak $str if $self->raise_error();
        $self->_error( $str );
    }
    return $self->_error if $self->_has_error;
    return ;
}



#
# _init_security_token
#   Creates new temporary security token (, access and secret key), if not exist
#

sub _init_security_token {
    my ( $self ) = @_;

    # wheter has valid credentials
    if ( $self->_has_credentials() ) {
        my $dt = DateTime->now( time_zone => 'local' )->add( seconds => 5 );
        return 1 if $dt < $self->_credentials_expire;
    }

    # build aws signed request
    $self->_aws_signer( Net::Amazon::AWSSign->new(
        $self->access_key, $self->secret_key ) )
        unless $self->_has_aws_signer;
    my $url = $self->_aws_signer->addRESTSecret( $self->_security_token_url );

    # get token
    my $res = $self->lwp->get( $url );

    # got response
    if ( $res->is_success) {
        my $content = $res->decoded_content;
        my $result_ref = XMLin( $content );

        # got valid result
        if( ref $result_ref && defined $result_ref->{ GetSessionTokenResult }
            && defined $result_ref->{ GetSessionTokenResult }
            && defined $result_ref->{ GetSessionTokenResult }->{ Credentials }
        ) {
            # SessionToken, AccessKeyId, Expiration, SecretAccessKey
            my $cred_ref = $result_ref->{ GetSessionTokenResult }->{ Credentials };
            if ( ref( $cred_ref )
                && defined $cred_ref->{ SessionToken }
                && defined $cred_ref->{ AccessKeyId }
                && defined $cred_ref->{ SecretAccessKey }
                && defined $cred_ref->{ Expiration }
            ) {
                # parse expiration date
                my $pattern = DateTime::Format::Strptime->new(
                    pattern   => '%FT%T',
                    time_zone => 'UTC'
                );
                my $expire = $pattern->parse_datetime( $cred_ref->{ Expiration } );
                $expire->set_time_zone( 'local' );
                $self->_credentials_expire( $expire );

                # set credentials
                $self->_credentials( $cred_ref );
                return 1;
            }
        }
        else {
            $self->error( "Failed to fetch credentials: ". $res->status_line. " ($content)" );
        }
    }
    else {
        my $content = eval { $res->decoded_content } || "No Content";
        $self->error( "Failed to fetch credentials: ". $res->status_line. " ($content)" );
    }

    return 0;
}


#
# _check_table $table
#   Check whether table exists and returns definition
#

sub _check_table {
    my ( $self, $meth, $table ) = @_;
    unless( $table ) {
        $table = $meth;
        $meth = "check_table";
    }
    croak "$meth: Table '$table' not defined"
        unless defined $self->tables->{ $table };

    return $self->tables->{ $table };
}


#
# _check_keys $meth, $table, $key_ref
#   Check attributes. Dies on invalid (not registererd) attributes.
#

sub _check_keys {
    my ( $self, $meth, $table, $key_ref ) = @_;
    my $table_ref = $self->_check_table( $meth, $table );

    my @keys = ref( $key_ref )
        ? ( ref( $key_ref ) eq 'ARRAY'
            ? @$key_ref
            : keys %$key_ref
        )
        : ( $key_ref )
    ;

    my @invalid_keys = grep { ! defined $table_ref->{ attributes }->{ $_ } } @keys;
    croak "$meth: Invalid keys: ". join( ', ', @invalid_keys )
        if @invalid_keys;

    return wantarray ? @keys : \@keys;
}


#
# _build_pk_filter $table, $where_ref, $node_ref
#   Build attribute filter "HashKeyElement" and "RangeKeyElement".
#   Hash key and range key will be deleted from where clause
#

sub _build_pk_filter {
    my ( $self, $table, $where_ref, $node_ref ) = @_;
    # primary key
    my $table_ref = $self->_check_table( $table );
    my $hash_value = delete $where_ref->{ $table_ref->{ hash_key } };
    my $hash_type  = $self->_attrib_type( $table, $table_ref->{ hash_key } );
    $node_ref->{ HashKeyElement } = { $hash_type => $hash_value . '' };
    if ( defined $table_ref->{ range_key } ) {
        my $range_value = delete $where_ref->{ $table_ref->{ range_key } };
        my $range_type  = $self->_attrib_type( $table, $table_ref->{ range_key } );
        $node_ref->{ RangeKeyElement } = { $range_type => $range_value . '' };
    }
}


#
# _build_attrib_filter $table, $where_ref, $node_ref
#   Build attribute filter "Expected" from given where-clause-ref
# {
#     attrib1 => 'somevalue', # -> { attrib1 => { Value => { S => 'somevalue' } } }
#     attrib2 => \1,          # -> { attrib2 => { Exists => true } }
#     attrib3 => {            # -> { attrib3 => { Value => { S => 'bla' } } }
#         value => 'bla'
#     }
# }
#

sub _build_attrib_filter {
    my ( $self, $table, $where_ref, $node_ref ) = @_;
    my $table_ref = $self->_check_table( $table );
    foreach my $key( keys %$where_ref ){
        my $type = $table_ref->{ attributes }->{ $key };
        my %cur;
        unless( ref( $where_ref->{ $key } ) ) {
            $where_ref->{ $key } = { value => $where_ref->{ $key } };
        }
        if ( ref( $where_ref->{ $key } ) eq 'SCALAR' ) {
            $cur{ Exists } = $where_ref->{ $key };
        }
        else {
            if ( defined( my $value = $where_ref->{ $key }->{ value } ) ) {
                $cur{ Value } = { $type => $value. '' };
            }
            if ( defined $where_ref->{ $key }->{ exists } ) {
                $cur{ Exists } = $where_ref->{ $key }->{ exists } ? \1 : \0;
            }
        }
        $node_ref->{ $key } = \%cur if keys %cur;
    }
}


#
# _attrib_type $table, $key
#   Returns type ("S", "N", "NS", "SS") of existing attribute in table
#

sub _attrib_type {
    my ( $self, $table, $key ) = @_;
    my $table_ref = $self->_check_table( $table );
    return defined $table_ref->{ attributes }->{ $key } ? $table_ref->{ attributes }->{ $key } : "S";
}


#
# _attribs $table
#   Returns list of attributes in table
#

sub _attribs {
    my ( $self, $table ) = @_;
    my $table_ref = $self->_check_table( $table );
    return sort keys %{ $table_ref->{ attributes } };
}


#
# _format_item $table, $from_ref
#
#   Formats result item into simpler format
# {
#     attrib => { S => "bla" }
# }
#
#   to
# {
#     attrib => 'bla'
# }
#

sub _format_item {
    my ( $self, $table, $from_ref ) = @_;
    my $table_ref = $self->_check_table( format_item => $table );
    my %formatted;
    if ( defined $from_ref->{ HashKeyElement } ) {
        my @keys = ( 'hash' );
        push @keys, 'range' if defined $table_ref->{ range_key };
        foreach my $key( @keys ) {
            my $key_name = $table_ref->{ "${key}_key" };
            my $key_type = $table_ref->{ attributes }->{ $key_name };
            $formatted{ $key_name } = $from_ref->{ ucfirst( $key ). 'KeyElement' }->{ $key_type };
        }
    }
    else {
        if ( $self->derive_table() ) {
            while ( my ( $key, $value ) = each %$from_ref ) {
	            $formatted{$key} = ( $value->{'S'} || $value->{'N'} || $value->{'NS'} || $value->{'SS'} );
	        }
        }
        else {
            while( my( $attrib, $type ) = each %{ $table_ref->{ attributes } } ) {
                next unless defined $from_ref->{ $attrib };
                $formatted{ $attrib } = $from_ref->{ $attrib }->{ $type };
            }
        }
    }
    return \%formatted;
}


#
# _table_name
#   Returns prefixed table name
#

sub _table_name {
    my ( $self, $table, $remove ) = @_;
    return $remove ? substr( $table, length( $self->namespace ) ) : $self->namespace. $table;
}


#
# _extract_error_message
#

sub _extract_error_message {
    my ( $self, $response ) = @_;
    my $msg = '';
    if ( $response ) {
        my $json = eval { $self->json->decode( $response->decoded_content ) } || { error => "Failed to parse JSON result" };
        if ( defined $json->{ __type } ) {
            $msg = join( ' ** ',
                "ErrorType: $json->{ __type }",
                "ErrorMessage: $json->{ message }",
            );
        }
        else {
            $msg = $json->{ error };
        }
    }
    else {
        $msg = 'No response received. DynamoDB down?'
    }
}

#
# _cache_enabled
#

sub _cache_enabled {
    my ( $self, $args_ref ) = @_;
    return $self->has_cache && ! $args_ref->{ no_cache }
        && ( $args_ref->{ use_cache } || ! $self->cache_disabled );
}

#
# _cache_key_single
#

sub _cache_key_single {
    my ( $self, $table, $hash_ref ) = @_;
    my $table_ref = $self->_check_table( $table );
    my @keys = ( $table_ref->{ hash_key } );
    push @keys, $table_ref->{ range_key } if defined $table_ref->{ range_key };
    my %pk = map { ( $_ => $hash_ref->{ $_ } || '' ) } @keys;
    return $self->_cache_key( $table, 'single', \%pk );
}

#
# _cache_key
#

sub _cache_key {
    my ( $self, $table, $name, $id_ref ) = @_;
    my $method = $self->cache_key_method();
    return sprintf( '%s-%s-%s', $table, $name, $method->( $self->json->encode( $id_ref ) ) );
}

__PACKAGE__->meta->make_immutable;


=head1 AUTHOR

=over

=item * Ulrich Kautz <uk@fortrabbit.de>

=item * Thanks to MadHacker L<http://stackoverflow.com/users/1139526/madhacker> (the signing code in request method)

=item * Benjamin Abbott-Scoot <benjamin@abbott-scott.net> (Keep Alive patch)

=back

=head1 COPYRIGHT

Copyright (c) 2012 the L</AUTHOR> as listed above

=head1 LICENCSE

Same license as Perl itself.

=cut

1;
