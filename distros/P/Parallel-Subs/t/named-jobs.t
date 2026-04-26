use strict;
use warnings;

use Test2::V0;

use Parallel::Subs;

subtest 'named job stores and retrieves result' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( 'greet', sub { 'hello' } );
    $p->wait_for_all();

    is $p->result('greet'), 'hello', "result('greet') returns job result";
};

subtest 'multiple named jobs' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( 'alpha', sub { 1 } );
    $p->add( 'beta',  sub { 2 } );
    $p->add( 'gamma', sub { 3 } );
    $p->wait_for_all();

    is $p->result('alpha'), 1, "alpha = 1";
    is $p->result('beta'),  2, "beta = 2";
    is $p->result('gamma'), 3, "gamma = 3";
};

subtest 'named jobs with complex return values' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( 'hash_job',  sub { { key => 'value' } } );
    $p->add( 'array_job', sub { [ 1, 2, 3 ] } );
    $p->wait_for_all();

    is $p->result('hash_job'),  { key => 'value' }, "hash result";
    is $p->result('array_job'), [ 1, 2, 3 ],        "array result";
};

subtest 'mixed named and unnamed jobs' => sub {
    my $p = Parallel::Subs->new( max_process => 1 );
    $p->add( sub { 'anon1' } );
    $p->add( 'named_one', sub { 'named' } );
    $p->add( sub { 'anon2' } );
    $p->wait_for_all();

    is $p->result('named_one'), 'named', "named job accessible by name";
    is $p->results(), [ 'anon1', 'named', 'anon2' ],
        "results() returns all in insertion order";
};

subtest 'named jobs with callbacks' => sub {
    my $captured;
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( 'worker', sub { 42 }, sub { $captured = shift } );
    $p->wait_for_all();

    is $p->result('worker'), 42,  "named result correct";
    is $captured,            42,  "callback received result";
};

subtest 'chaining with named jobs' => sub {
    my $p = Parallel::Subs->new( max_process => 2 )
        ->add( 'a', sub { 10 } )
        ->add( 'b', sub { 20 } )
        ->add( 'c', sub { 30 } )
        ->wait_for_all();

    is $p->result('a'), 10, "chained named a";
    is $p->result('b'), 20, "chained named b";
    is $p->result('c'), 30, "chained named c";
};

subtest 'duplicate name croaks' => sub {
    my $p = Parallel::Subs->new();
    $p->add( 'dup', sub { 1 } );

    like dies { $p->add( 'dup', sub { 2 } ) },
        qr/duplicate job name 'dup'/,
        "duplicate name is rejected";
};

subtest 'result with unknown name croaks' => sub {
    my $p = Parallel::Subs->new();
    $p->add( 'known', sub { 1 } );
    $p->wait_for_all();

    like dies { $p->result('unknown') },
        qr/unknown job name 'unknown'/,
        "unknown name croaks";
};

subtest 'result without name croaks' => sub {
    my $p = Parallel::Subs->new();

    like dies { $p->result() },
        qr/result\(\) requires a job name/,
        "result() without argument croaks";
};

subtest 'named jobs do not break results() ordering' => sub {
    my $p = Parallel::Subs->new( max_process => 1 );
    for my $i ( 1 .. 5 ) {
        $p->add( "job_$i", sub { $i * 100 } );
    }
    $p->wait_for_all();

    is $p->results(), [ 100, 200, 300, 400, 500 ],
        "results() preserves insertion order";

    for my $i ( 1 .. 5 ) {
        is $p->result("job_$i"), $i * 100, "result('job_$i') correct";
    }
};

done_testing;
