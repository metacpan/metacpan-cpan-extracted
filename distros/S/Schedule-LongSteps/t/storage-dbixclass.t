#! perl -wt

use Test::More;
use Test::Exception;
use Test::MockModule;

use Schedule::LongSteps::Storage::DBIxClass;
use DateTime;

use Log::Any::Adapter;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for this test."
    if $@;

eval "use DBIx::Class::Schema::Loader";
plan skip_all => "DBIx::Class::Schema::Loader is required for this test."
    if $@;

eval "use DateTime::Format::SQLite";
plan skip_all => "DateTime::Format::SQLite is required for this test."
    if $@;

my $create_table = q|
CREATE TABLE longsteps_process( id INTEGER PRIMARY KEY AUTOINCREMENT,
                             process_class TEXT NOT NULL,
                             status TEXT NOT NULL DEFAULT 'pending',
                             what TEXT NOT NULL,
                             run_at TEXT DEFAULT NULL,
                             run_id TEXT DEFAULT NULL,
                             state TEXT NOT NULL DEFAULT '{}',
                             error TEXT DEFAULT NULL
)
|;

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, {
    AutoCommit => 1,
    RaiseError => 1
});

$dbh->do( $create_table );

DBIx::Class::Schema::Loader::make_schema_at(
    'My::Schema',
    {
        # debug => 1,
        naming => 'v5',
        components => ["InflateColumn::DateTime"],
    },
    [ sub{ return $dbh; } ]
);

my $schema = My::Schema->connect(sub{ $dbh; });

ok( my $storage = Schedule::LongSteps::Storage::DBIxClass->new({ schema => $schema, resultset_name => 'LongstepsProcess' }) );
is( scalar( $storage->prepare_due_processes() ) , 0 , "Ok zero due steps");

# Note that we need that for SQLite, cause it hasnt got
# a datetime type. Therefore, we need to make sure the format is consistent with what is done
# inside the LongSteps::Storage::DBIxClass code.
my $dtf = $schema->storage()->datetime_parser();

ok( my $process_id = $storage->create_process({ process_class => 'Blabla', what => 'whatever', run_at => $dtf->format_datetime( DateTime->now() ) })->id(), "Ok got ID");
ok( $storage->find_process($process_id) );

is( scalar( $storage->prepare_due_processes() ) , 1 , "Ok one due step");
is( scalar( $storage->prepare_due_processes() ) , 0 , "Doing it again gives zero steps");

my $process = $storage->create_process({ process_class => 'Blabla', what => 'whatever', run_at => $dtf->format_datetime( DateTime->now() ) });
ok( $storage->find_process($process->id()));
$storage->create_process({ process_class => 'Blabla', what => 'whatever', run_at => $dtf->format_datetime( DateTime->now() ) });

{
    $dbh->begin_work();
    my @steps = $storage->prepare_due_processes();
    is( scalar( @steps ), 2 , "Ok two steps to do");
    foreach my $step ( @steps ){
        # While we are doing things, any other process would see zero things to do
        is( scalar( $storage->prepare_due_processes() ) , 0 , "Preparing steps again whilst they are running give zero steps");
    }
    $dbh->commit();
}

{
    ok( $storage->find_process($process->id()));
    ok( $storage->update_process( $process , { run_at => DateTime->now() }) );
}

{
    # Log::Any::Adapter->set({ lexically => \my $lex }, 'Stderr' );
    my $times_called = 0;
    my $mock_process = Test::MockModule->new( ref( $process ) );
    $mock_process->mock( update => sub{
                             my @args = @_;
                             # Simulate a deadlock for the first two times.
                             ( $times_called++ < 2 ) && die ( "Deadlock found when trying to get lock; try restarting transaction" );
                             # Works after a while
                             return $mock_process->original( 'update' )->( @args ) ;
                         });
    ok( $storage->find_process($process->id()));
    ok( $storage->update_process( $process , { run_at => DateTime->now() }) );
    is( $times_called , 3 , "Ok called 3 times. The third time worked");
}

{
    # Log::Any::Adapter->set({ lexically => \my $lex }, 'Stderr' );
    my $times_called = 0;
    my $mock_process = Test::MockModule->new( ref( $process ) );
    $mock_process->mock( update => sub{
                             my @args = @_;
                             # This dies straight away with some unmanaged exception
                             ( $times_called++ < 2 ) && die ( "Some unmanaged exception" );
                             die "NEVER REACHED";
                         });
    ok( $storage->find_process($process->id()));
    throws_ok { $storage->update_process( $process , { run_at => DateTime->now() } ) } qr/unmanaged exception/;
    is( $times_called , 1 , "Ok called only one time, because it died with something unmanaged");
}


done_testing();
