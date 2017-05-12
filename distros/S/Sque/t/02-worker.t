use Test::More;
use lib 't/lib';
use Test::SpawnMq qw( mq );
use Sque;

my ( $s, $server ) = mq();

sub END { $s->() if $s }

my $sque = new_ok( "Sque" => [( stomp => $server )],
                    "Build Sque object $server" );

isa_ok( my $worker = $sque->worker, 'Sque::Worker' );

ok( $worker->add_queues( 'Test' ), 'Add Single Queue' );
is( keys %{ $worker->queues } => 1, 'Found 1 Queue' );
ok( $worker->queues->{Test}, 'Found Test Queue' );

ok( $worker->add_queues( 'Test2', 'Test3' ), 'Add Two More Queues' );
is( keys %{ $worker->queues } => 3, 'Found 1 Queue' );
is(
    ( grep{ /^(Test|Test2|Test3)$/ } keys %{ $worker->queues } ) => 3,
    'Found All Queues'
);

# Push non-object worker
push_job( $sque, args => [ 'default' ] );
ok( my $job = $worker->reserve, 'reserve() a job' );
is( $job->args->[0] => 'default', 'Got Job Arg 0' );
ok( my $reval = $worker->perform( $job ), 'Performed Job' );
is( $reval->[0] => 'default', 'Got Job Reval' );

# Push Moose Worker
push_job( $sque,
    class => 'Test::WorkerMoose',
    args => [ 'MOOSE', 'test' ]
);
ok( my $obj_job = $worker->reserve, 'reserve() an object job' );
is( $obj_job->args->[0] => 'MOOSE', 'Got Job Arg 0' );
is( $obj_job->args->[1] => 'test', 'Got Job Arg 1' );
ok( my $obj_re = $worker->perform( $obj_job), 'Performed obj Job' );
is( $obj_re->[0] => 'MOOSE', 'Got Obj Job Reval 1' );
is( $obj_re->[1] => 'test', 'Got Obj Job Reval 2' );

sub push_job {
    my ( $sque, %args ) = @_;
    $args{class} //= 'Test::Worker';
    $args{queue} //= 'Test';
    $args{args} //= [ 'DEFAULT', 'ARGS' ];

    ok( $sque->push( $args{queue} => {
            class => $args{class},
            args =>  $args{args}
        }), "Push new job to $args{queue} queue" );
}


done_testing;
