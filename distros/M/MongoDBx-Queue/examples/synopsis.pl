use v5.10;
use MongoDB;
use MongoDBx::Queue;

my $connection = MongoDB::Connection->new(@parameters);
my $database   = $connection->get_database("queue_db");

my $queue = MongoDBx::Queue->new( db => $database );

$queue->add_task( { msg => "Hello World" } );
$queue->add_task( { msg => "Goodbye World" } );

while ( my $task = $queue->reserve_task ) {
  say $task->{msg};
  $queue->remove_task($task);
}
