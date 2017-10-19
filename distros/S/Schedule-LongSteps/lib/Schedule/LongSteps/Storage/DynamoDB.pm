package Schedule::LongSteps::Storage::DynamoDB;
$Schedule::LongSteps::Storage::DynamoDB::VERSION = '0.020';
use Moose;
extends qw/Schedule::LongSteps::Storage/;

use Compress::Zlib;
use DateTime::Format::ISO8601;
use DateTime;
use JSON qw//;
use Log::Any qw/$log/;
use MIME::Base64;
use Scalar::Util;

my $TIME_MAX = '9999-12-31T23:59:59.999Z';

=head1 NAME

Schedule::LongSteps::Storage::DynamoDB - A DynamoDB backed longstep storage.

=cut

=head1 SYNOPSIS


  my $dynamo_db = Paws->service('DynamoDB', ...); # see Paws
  # You can also look in t/storage-dynamodb.t for a working example.

  my $storage = Schedule::LongSteps::Storage::DynamoDB->new({ dynamo_db => $dynamo_db, table_prefix => 'my_app_longsteps' });

  # Call that only once as part of your persistent data management:
  $storage->vivify_table();

  my $sl = Schedule::LongSteps->new({ storage => $storage, ... }, ... );

=cut

has 'dynamo_db' => (is => 'ro', isa => 'Paws::DynamoDB' , required => 1 );
has 'table_prefix' => ( is => 'ro', isa => 'Str', required => 1);

has 'table_name' => ( is => 'ro', isa => 'Str', lazy_build => 1);

has 'creation_wait_time' => ( is => 'ro', isa => 'Int', default => 2 );

sub _build_table_name{
    my ($self) = @_;
    my $package = __PACKAGE__;
    $package =~ s/::/_/g;
    return $self->table_prefix().'_'.$package;
}

=head2 table_active

The remote DynamoDB table exists and is active.

=cut

sub table_active{
    my ($self) = @_;
    my $status = $self->table_status();
    unless( defined( $status ) ){ $status = 'NOMATCH'; }
    return $status eq 'ACTIVE';
}

=head2 table_exists

The remote DynamoDB table exists.

=cut

sub table_exists{
    return defined( shift->table_status() );
}

=head2 table_status

Returns the table status (or undef if the table doens't exists at all)

Usage:

  if( my $status = $self->table_status() ){ .. }

Returned status can be one of those described here: L<https://metacpan.org/pod/Paws::DynamoDB::TableDescription>

=cut

sub table_status{
    my ($self) = @_;
    my $desc_table = eval{ $self->dynamo_db()->DescribeTable( TableName => $self->table_name() ) };
    if( my $err = $@ ){
        if( Scalar::Util::blessed($err) &&
            $err->isa('Paws::Exception') &&
            $err->code() eq 'ResourceNotFoundException'
        ){
            $log->debug("No table ".$self->table_name());
            return undef;
        }
        # Rethrow any other error.
        confess( $err );
    }
    return $desc_table->Table()->TableStatus();
}

=head2 vivify_table

Vivifies the remote DynamoDB table to support this storage.

You need to call that at least once as part of your persistent data
management process, or at the beginning of your application.

=cut

sub vivify_table{
    my ($self) = @_;

    my $table_name = $self->table_name();
    if( $self->table_exists() ){
        $log->warn("Table $table_name already exists in remote DynamoDB. Not creating it");
        return;
    }
    # Get all tables and check this one is not there already.
    $log->info("Creating Table ".$table_name." in dynamoDB");

    my $creation = $self->dynamo_db()->CreateTable(
        TableName => $table_name,
        AttributeDefinitions => [
            { AttributeName => 'id', AttributeType => 'S' },
            ## Note those are only there for reference.
            ## as AttributeDefinition must only defined attributes
            ## used in the KeySchema
            # { AttributeName => 'process_class', AttributeType => 'S' },
            # { AttributeName => 'mstatus', AttributeType => 'S' },
            # { AttributeName => 'what', AttributeType => 'S' },
            { AttributeName => 'run_at_day' , AttributeType => 'S' }, # ISO8601 YYYY-MM-DD
            { AttributeName => 'run_at', AttributeType => 'S' }, # ISO8601 YYYY-MM-DDTHH:MM:SS.000
            # { AttributeName => 'run_id', AttributeType => 'S' }, # The current run_id
            # { AttributeName => 'mstate', AttributeType => 'S' },
            # { AttributeName => 'merror', AttributeType => 'S' },
        ],
        KeySchema => [
            { AttributeName => 'id', KeyType => 'HASH' },
        ],
        GlobalSecondaryIndexes => [
            {
                IndexName => 'by_run_at_day',
                KeySchema => [
                    { AttributeName => 'run_at_day', KeyType => 'HASH' },
                    { AttributeName => 'run_at', KeyType => 'RANGE' },
                ],
                Projection => {
                    NonKeyAttributes => [ 'run_id' ],
                    ProjectionType => 'INCLUDE'
                },
                ProvisionedThroughput => {
                    ReadCapacityUnits => 2,
                    WriteCapacityUnits => 2,
                }
            }
        ],
        ProvisionedThroughput => {
            ReadCapacityUnits => 2,
            WriteCapacityUnits => 2,
            # This is low to avoid having a large bill in case
            # of tests failure.
            # Note that we can change that AFTER the fact
        },
    );

    while(! $self->table_active() ){
        $log->info("Table $table_name not active yet. Waiting ".$self->creation_wait_time()." second");
        if( $self->creation_wait_time() ){
            sleep($self->creation_wait_time());
        }
    }
    $log->info("Table $table_name ACTIVE. All is fine");
    return $creation;
}

=head2 prepare_due_processes

See L<Schedule::LongSteps::Storage>

=cut

sub prepare_due_processes{
    my ($self, $options ) = @_;

    $options ||= {};

    my $now = DateTime->now();
    my $run_at_day = $now->clone()->truncate( to => 'day' );

    my @found_items = ();
    my $query_output;
    do{
        # Query the by_run_at_day index
        $query_output = $self->dynamo_db()->Query(
            TableName => $self->table_name(),
            IndexName => 'by_run_at_day',
            ConsistentRead => 0, # Consistent read are not supported on secondary indices.
            ExpressionAttributeValues => {
                ":run_at_day" => { "S" => substr( $run_at_day->iso8601() , 0 , 10 ) },
                ":now" => { "S" => $now->iso8601().'Z' },
                ":null" => { "S" => 'NULL' },
            },
            Limit => 20,
            KeyConditionExpression => 'run_at_day = :run_at_day AND run_at <= :now',
            FilterExpression => 'run_id = :null',
            ProjectionExpression => 'id',
        );

        # Next we are going to look at the day before
        $run_at_day->subtract( days => 1 )->truncate( to => 'day' );

        $log->info("Got ".$query_output->Count()." results back for run_at_day = $run_at_day");
        push @found_items , @{ $query_output->Items() };

    } while( $query_output->Count() );

    # Of all the items found, we need to inject a run_id in those who dont have any yet
    # and return only those ones.
    my $run_id = $self->uuid()->create_str();
    $log->info("Will set run_id=$run_id on due items");
    my @locked_processes;

    ( $options->{concurrent_fiddle} || sub{} )->();

    foreach my $item ( @found_items ){
        my $id = $item->Map()->{id}->S();
        my $update_output = eval{
            $self->dynamo_db()->UpdateItem(
                TableName => $self->table_name(),
                ExpressionAttributeValues => {
                    ":run_id" => { S => $run_id },
                    ":null" => { "S" => 'NULL' },
                },
                Key => { id => { S => $id } },
                UpdateExpression => 'SET run_id = :run_id',
                ConditionExpression => 'run_id = :null',
                ReturnValues => 'ALL_NEW',
            );
        };
        if( my $err = $@ ){
            # This error is expected in case of race condition.
            if( $err =~ m/^The conditional request failed/ ){
                $log->info("INVALID ITEM Item ".$id." has not been updated with our run_id. It was taken by another run id");
                next;
            }
            # This is a non-expected error.
            confess( $err );
        }

        my $attributes = $update_output->Attributes()->Map();
        my $new_run_id = $attributes->{run_id}->S();
        $log->info("VALID ITEM Updated item ".$id." with our run_id=".$run_id);
        push @locked_processes, $self->_process_from_attrmap( $update_output->Attributes() );
    }

    return @locked_processes;
}

=head2 create_process

See L<Schedule::LongSteps::Storage>

=cut

sub create_process{
    my ($self, $properties) = @_;
    my $o = Schedule::LongSteps::Storage::DynamoDB::Process->new({
        storage => $self,
        id => $self->uuid()->create_str(),
        %{$properties}
    });
    $o->_insert();
    return $o;
}

=head2 find_process

See L<Schedule::LongSteps::Storage>

=cut

sub find_process{
    my ($self, $pid) = @_;
    my $dynamo_item = $self->dynamo_db()->GetItem(
        TableName => $self->table_name(),
        ConsistentRead => 1,
        Key => {
            id => { S => $pid }
        }
    )->Item();
    unless( $dynamo_item ){
        return undef;
    }
    return $self->_process_from_attrmap( $dynamo_item );
}

sub _state_decode{
    my ($self, $dynamo_state) = @_;
    if( $dynamo_state =~ /^{/ ){
        # Assume JSON
        return JSON::from_json( $dynamo_state );
    }

    # Assume base64 encoded memGunzip
    return JSON::from_json( Compress::Zlib::memGunzip( MIME::Base64::decode_base64( $dynamo_state ) ) );
}

sub _process_from_attrmap{
    my ($self, $dynamoItem) = @_;
    my $map = $dynamoItem->Map();

    my $run_at = $map->{run_at}->S();
    if( $run_at eq $TIME_MAX ){
        $run_at = undef;
    }else{
        $run_at = DateTime::Format::ISO8601->parse_datetime( $run_at );
    }
    my $run_id = $map->{run_id}->S();
    if( $run_id eq 'NULL' ){
        $run_id = undef;
    }
    my $state = $self->_state_decode( $map->{mstate}->S() );
    my $error = $map->{merror}->S();
    if( $error eq 'NULL' ){
        $error = undef;
    }

    return Schedule::LongSteps::Storage::DynamoDB::Process->new({
        storage => $self,
        id => $map->{id}->S(),
        process_class => $map->{process_class}->S(),
        status => $map->{mstatus}->S(),
        what => $map->{what}->S(),
        run_at => $run_at,
        run_id => $run_id,
        state => $state,
        error => $error,
    });
}


=head2 destroy_table

Destroys this table. Mainly so tests don't leave some crap behind.

Use that responsibly. Which is never except in tests.

Note that this blocks until the table has effectively been deleted remotely.

=cut

sub destroy_table{
    my ($self, $am_i_sure) = @_;
    unless( $am_i_sure eq 'I am very sure and I am not insane' ){
        confess("Sorry we cannot let you do that");
    }
    unless( $self->table_active() ){
        confess("Sorry this table is not ACTIVE. Too early to destroy");
    }
    my $table_name = $self->table_name();
    unless( $table_name =~ /^testdelete/ ){
        confess("Sorry this is not a test table (from the test suite. Destroy manually if you are sure");
    }
    $log->warn("Will destroy $table_name from dynamoDB");
    my $deletion = $self->dynamo_db()->DeleteTable(TableName => $table_name);
    # Wait until the table is effectively destroyed.
    while( $self->table_exists() ){
        $log->warn("Table $table_name not destroyed yet. Waiting ".$self->creation_wait_time()." second");
        if( $self->creation_wait_time() ){
            sleep( $self->creation_wait_time() );
        }
    }
    $log->warn("Table $table_name DESTROYED");
    return $deletion;
}

__PACKAGE__->meta()->make_immutable();

package Schedule::LongSteps::Storage::DynamoDB::Process;
$Schedule::LongSteps::Storage::DynamoDB::Process::VERSION = '0.020';
use Moose;

use Compress::Zlib;
use Data::Dumper;
use DateTime::Format::ISO8601;
use DateTime;
use JSON qw//;
use Log::Any qw/$log/;
use MIME::Base64;

has 'storage' => ( is => 'ro', isa => 'Schedule::LongSteps::Storage::DynamoDB', required => 1 );
has 'id' =>      ( is => 'ro', isa => 'Str', required => 1 );

has 'process_class' => ( is => 'rw', isa => 'Str', required => 1); # rw only for test. Should not changed ever.
has 'status' =>        ( is => 'rw', isa => 'Str', default => 'pending' );
has 'what' =>          ( is => 'rw' ,  isa => 'Str', required => 1);
has 'run_at' =>        ( is => 'rw', isa => 'Maybe[DateTime]', default => sub{ undef; } );
has 'run_id' =>        ( is => 'rw', isa => 'Maybe[Str]', default => sub{ undef; } );
has 'state' =>         ( is => 'rw', default => sub{ {}; });
has 'error' =>         ( is => 'rw', isa => 'Maybe[Str]', default => sub{ undef; } );

my $MAX_DYNAMO_ITEM_SIZE = 350_000;

# Local to Dynamo Items.
my $MEMORY_TO_DYNAMO = {
    id => [ 'id' ],
    process_class => [ 'process_class' ],
    status => [ 'mstatus' ], # My status
    what => [ 'what' ],
    run_at => [ 'run_at', 'run_at_day' ],
    run_id => [ 'run_id' ],
    state => [ 'mstate' ],  # My state
    error => [ 'merror' ],  # My error
};


=head2 update

Updates via upsert.

=cut

sub update{
    my ($self, $attributes) = @_;

    foreach my $key ( keys %$attributes ){
        $self->$key( $attributes->{$key} );
    }
    my $dynamo_item = $self->_to_dynamo_item();
    my $to_update = {};
    # Only keep attributes that were updated.
    foreach my $attr ( keys %$attributes ){
        foreach my $dynamo_attr ( @{ $MEMORY_TO_DYNAMO->{$attr} } ){
            $to_update->{$dynamo_attr} = $dynamo_item->{$dynamo_attr};
        }
    }

    $log->info("Updating Item ID = ".$self->id()." with ".Dumper( $to_update ) );

    my @update_keys = keys %$to_update;
    my $expression_attributes = {
        map { ':'.$_ => $to_update->{$_} } @update_keys
    };
    # $log->debug("ExpressionAttributes = ".Dumper( $expression_attributes ) );
    my $update_expression = 'SET '.join(', ', map { $_.' = :'.$_  } @update_keys );
    # $log->debug("UpdateExpression = ".$update_expression);

    $self->storage()->dynamo_db()->UpdateItem(
        TableName => $self->storage()->table_name(),
        Key => { id => { S => $self->id() } },
        ExpressionAttributeValues => $expression_attributes,
        UpdateExpression => $update_expression
    );

    return $self;
}

=head2 discard_changes

Updates what is updatable.

=cut

sub discard_changes{
    my ($self) = @_;
    my $fresh_one = $self->storage()->find_process( $self->id() );
    foreach my $rw_attr ( qw/process_class status what run_at run_id state error/ ){
        $self->$rw_attr( $fresh_one->$rw_attr() );
    }
    return $self;
}

sub _insert{
    my ($self) = @_;
    my $table_name = $self->storage()->table_name();

    $log->info("Inserting ".ref($self)." , id = ".$self->id()." in Dynamo table ".$table_name);
    $self->storage()->dynamo_db->PutItem(
        TableName => $table_name,
        Item => $self->_to_dynamo_item(),
    );
    return $self;
}

sub _state_encode{
    my ($self) = @_;
    my $state_json = JSON::to_json(
        $self->state(),
        { ascii => 1 }
    );
    unless( length( $state_json ) > $MAX_DYNAMO_ITEM_SIZE ){
        $log->debug("Encoded state is ".substr( $state_json, 0 , 2000 ));
        return $state_json;
    }

    $log->debug("State JSON is over 350KB, compressing");
    my $state_b64zjs = MIME::Base64::encode_base64(
        Compress::Zlib::memGzip( $state_json ) );
    if( length( $state_b64zjs ) > $MAX_DYNAMO_ITEM_SIZE ){
        confess("Compressed state is too large (over 350000 bytes)");
    }
    $log->debug("Encoded state is ".substr( $state_b64zjs , 0, 1000 ) .'...' );
    return $state_b64zjs;
}

sub _error_trim{
    my ($self) = @_;
    unless( $self->error() ){
        return undef;
    }
    return substr( $self->error() , 0 , 2000 );
}

sub _to_dynamo_item{
    my ($self) = @_;
    my $run_at_str = $TIME_MAX;
    if( my $run_at = $self->run_at() ){
        $run_at_str = $run_at->iso8601().'Z';
    }
    my $run_at_str_day = substr( $run_at_str, 0, 10 );


    return {
        id => { S => $self->id() },
        process_class => { S => $self->process_class() },
        mstatus => { S => $self->status() },
        what => { S => $self->what() },
        run_at_day => { S => $run_at_str_day },
        run_at => { S => $run_at_str },
        run_id => { S => $self->run_id() || 'NULL' },
        mstate => { S => $self->_state_encode() },
        merror => { S => $self->_error_trim() || 'NULL' },
    }
}

__PACKAGE__->meta()->make_immutable();
