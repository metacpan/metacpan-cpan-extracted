#! perl -wt

use Test::More;
use Schedule::LongSteps;

{
    package MyProcess;
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    use DateTime;

    sub build_first_step {
        my ($self) = @_;
        return $self->new_step(
            {
                what   => 'do_stuff1',
                run_at => DateTime->now(),
            }
        );
    }

    sub do_stuff1 {
        my ($self) = @_;
        return $self->new_step(
            {
                what   => 'do_final_step',
                run_at => DateTime->now(),
                state  => { %{ $self->state() }, first_step => 'done' }
            }
        );
    }

    sub do_death {
        die 'I died'
    }

    sub do_final_step {
        my ($self) = @_;
        return $self->final_step( { state => { the => 'final', state => 1 } } );
    }
}

ok( my $long_steps = Schedule::LongSteps->new() );

# create a MyProcess process
ok(
    my $process = $long_steps->instantiate_process(
        'MyProcess', undef, { beef => 'saussage' }
    )
);

# the process looks normal
ok( $process->id() );
is( $process->what(), 'do_stuff1' );
is_deeply( $process->state(), { beef => 'saussage' } );


# load the process by using its id.
ok( my $loaded_process = $long_steps->load_process( $process->id() ),
    'can load a process' );

# is the loaded process the same as the crated process
my $stored_process = $loaded_process->stored_process;
is( $process->id(),   $stored_process->id(),   'same process: id' );
is( $process->what(), $stored_process->what(), 'same process: what' );
is_deeply(
    $process->state(),
    $stored_process->state(),
    'same process: state'
);

# is there a first_step in the stat?
is($process->state()->{first_step}, undef, 'there is no first_step in the state');

# lets run some of the functions on the process
# something that returns something
my $did_do_stuff = $loaded_process->do_stuff1();

#something that goes bang
eval {$loaded_process->do_death()};
like($@, qr(I died), 'do_death dies');

# Time to run!
ok( $long_steps->run_due_processes() );

# running do_stuff manually and as part of a process return the same state.
is_deeply($process->state, $did_do_stuff->{state});

# now run to complete
ok( $long_steps->run_due_processes() );

# And check the step properties have been
is_deeply( $process->state(), { the => 'final', state => 1 } );
is( $process->status(), 'terminated' );
is( $process->run_at(), undef );

# Check no due step have run again
ok( !$long_steps->run_due_processes() );

done_testing();
