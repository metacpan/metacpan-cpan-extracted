use strict;
use warnings;

use Test2::V0;

use Parallel::Subs;
use Scalar::Util qw(weaken);

# Detection method: create a weak reference to the object.
# If the object leaks (circular reference), the weak ref stays defined
# after the strong ref goes out of scope.

subtest 'object freed after run()' => sub {
    my $ref;
    {
        my $p = Parallel::Subs->new( max_process => 2 );
        $p->add( sub { 42 } );
        $p->add( sub { 84 } );
        $p->run();
        $ref = $p;
        weaken($ref);
    }
    ok !defined $ref,
        "no circular reference leak after run()";
};

subtest 'object freed after wait_for_all' => sub {
    my $ref;
    {
        my $p = Parallel::Subs->new( max_process => 2 );
        $p->add( sub { 1 }, sub { } );
        $p->add( sub { 2 } );
        $p->wait_for_all();
        $ref = $p;
        weaken($ref);
    }
    ok !defined $ref,
        "no circular reference leak after wait_for_all with callbacks";
};

subtest 'object freed after wait_for_all_optimized' => sub {
    my $ref;
    {
        my $p = Parallel::Subs->new( max_process => 2 );
        $p->add( sub { 1 } );
        $p->add( sub { 2 } );

        # Suppress the "Callback not supported" warning
        local $SIG{__WARN__} = sub { };
        $p->wait_for_all_optimized();

        $ref = $p;
        weaken($ref);
    }
    ok !defined $ref,
        "no circular reference leak after wait_for_all_optimized";
};

subtest 'unused object freed' => sub {
    my $ref;
    {
        my $p = Parallel::Subs->new( max_process => 2 );
        $p->add( sub { 1 } );
        $ref = $p;
        weaken($ref);
    }
    ok !defined $ref,
        "no leak even when jobs are added but never run";
};

done_testing;
