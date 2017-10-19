#! perl -wt

use Test::More;

use Schedule::LongSteps::Storage::DynamoDB;
use DateTime;
use Class::Load;

# use Log::Any::Adapter qw/Stderr/;


$ENV{DYNAMODB_LOCAL} or plan skip_all => "ENV DYNAMODB_LOCAL URL is required";

my @paws_class = ( 'Paws',
                   'Paws::Credential::Explicit',
                   'Paws::Net::LWPCaller',
                   'JSON',
                   'MIME::Base64',
                   'Compress::Zlib',
               );

join( '', map{ Class::Load::try_load_class( $_ ) ? 'yes' : '' } @paws_class ) eq join('', map{ 'yes' } @paws_class )
    or plan skip_all => "Paws required to run these tests";

my $dynamo_config = {
    region => 'eu-west-1',
    endpoint => $ENV{DYNAMODB_LOCAL},
};


my $caller = Paws::Net::LWPCaller->new();
my $credentials = Paws::Credential::Explicit->new({ access_key => 'foo', secret_key => 'bar' });

my $dynamo_db = Paws->service(
    'DynamoDB',
    caller => $caller,
    credentials => $credentials,
    max_attempts => 10,
    %{$dynamo_config}
);

ok( my $storage = Schedule::LongSteps::Storage::DynamoDB->new({ dynamo_db => $dynamo_db, table_prefix => 'testdeletethis' }) );
like( $storage->table_name() , qr/^testdeletethis_Schedule_LongSteps_Storage_DynamoDB/ );
is( $storage->table_status() , undef ,"Ok no table exists remotely");
ok( $storage->vivify_table() , "Ok can vivify table");

ok( ! scalar( $storage->prepare_due_processes() ), "Ok zero due steps");

my $now = DateTime->now();

{
    ok( my $process_id =  $storage->create_process({ process_class => 'Blabla', what => 'whatever', run_at => $now })->id(), "Ok got ID");
    ok( my $process = $storage->find_process($process_id) );
    is_deeply( $process->state() , {} );
    ok( $process = $process->update({ state => { 'foo' => 'updated' } } ) );
    $process = $storage->find_process($process_id);
    is( $process->run_at().'' , $now.'' );
    is_deeply( $process->state() , { 'foo' => 'updated' });
}

{
    ok( my $process_id =  $storage->create_process({ process_class => 'Blabla', what => 'whatever', run_at => undef, state => { foo => 'bar' } })->id(), "Ok got ID");
    ok( my $process = $storage->find_process($process_id) );
    $process->update({ error => 'blabla' });
    $process = $storage->find_process( $process_id );
    is( $process->error() , 'blabla' );
    is_deeply( $process->state() , { foo => 'bar' } );
    is( $process->run_at() , undef );
}

{
    ok( my $process_id =  $storage->create_process({ process_class => 'Blabla', what => 'whatever', run_at => $now, state => { foo => 'bar' x 300_000 } })->id(), "Ok got ID");
    ok( my $process = $storage->find_process($process_id) );
    is_deeply( $process->state() , { foo => 'bar' x 300_000 } );
}

is( scalar( $storage->prepare_due_processes() ) , 2 );

$storage->create_process({ process_class => 'Blabla', what => 'whatever', run_at =>  DateTime->now() });
$storage->create_process({ process_class => 'Blabla', what => 'whatever', run_at =>  DateTime->now() });
$storage->create_process({ process_class => 'Blabla', what => 'some_other_thing', run_at => DateTime->now() , id => 'PLEASE_FIDDLE_WITH_ME' });

my @steps = $storage->prepare_due_processes({ concurrent_fiddle => sub{
                                                  $storage->dynamo_db()->UpdateItem(
                                                      TableName => $storage->table_name(),
                                                      Key => { id => { S => 'PLEASE_FIDDLE_WITH_ME' } },
                                                      ExpressionAttributeValues => {
                                                          ':run_id' => { S => 'FIDDLE_RUN_ID' },
                                                      },
                                                      UpdateExpression => 'SET run_id = :run_id'
                                                  );
                                              }
                                          });

is( scalar( @steps ) , 2, "Ok found 2 more to run");

foreach my $step ( @steps ){
    # While we are doing things, any other process would see zero things to do
    ok(! scalar( $storage->prepare_due_processes()) , "Preparing steps again whilst they are running give zero steps");
}


END{
    if( $storage ){
        if( $storage->table_exists() ){
            $storage->destroy_table('I am very sure and I am not insane');
        }
    }
    done_testing();
}
