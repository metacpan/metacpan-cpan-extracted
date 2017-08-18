#! perl -wt

use Test::More;
use Schedule::LongSteps;

{
    package MyProcess;
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    use DateTime;
    sub build_first_step{
        my ($self) = @_;
        return $self->new_step({ what => 'do_stuff1', run_at => DateTime->now() });
    }

    sub do_stuff1{
        my ($self) = @_;
        return $self->new_step({ what => 'do_last_stuff', run_at => DateTime->now(),  state => { some => 'new one' }});
    }

    sub do_last_stuff{
        my ($self) = @_;
        return $self->final_step({ state => { the => 'final one' }});
    }
}


ok( my $long_steps = Schedule::LongSteps->new() );

ok( my $step = $long_steps->instantiate_process('MyProcess', undef, { beef => 'saussage' }) );

ok( my $fakestep = $long_steps->instantiate_process('MyProcess', undef, { beef => 'kdowkdowk' }) );
# This simulates the fact that this process class could now be impossible to load.
# The subsequent run_due_process should not break and just
# report the error in $fakestep
$fakestep->update({ process_class => 'BladiBlabla' });

is( $step->what() , 'do_stuff1' );
is_deeply( $step->state() , { beef => 'saussage' });

# Time to run!
ok( $long_steps->run_due_processes() );
like( $fakestep->error() , qr/locate BladiBlabla\.pm/ );

{
    eval {
        $long_steps->load_process( $fakestep->id() );
    };
    like($@, qr(Can\'t locate BladiBlabla.pm), 'load procress throws an error');
    ok( my $loaded_process = $long_steps->load_process( $step->id() ),
        'can load a process' );
    my $stored_process = $loaded_process->stored_process;
    is( $step->id(),   $stored_process->id(),   'same process: id' );
    is( $step->what(), $stored_process->what(), 'same process: what' );
    is_deeply( $step->state(), $stored_process->state(), 'same process: state' );
}


# And check the step properties have been
is_deeply( $step->state(), { some => 'new one' });
is( $step->what(), 'do_last_stuff' );
is( $step->status() , 'paused' );
ok( $step->run_at() );

ok( $long_steps->run_due_processes() , "Will run one step");

is_deeply( $step->state(), { the => 'final one' });
is( $step->status() , 'terminated' );
ok( ! $step->run_at() );

ok( ! $long_steps->run_due_processes() );

is($long_steps->load_process( 1234567890 ), undef, 'load_process returns undef if not found');

done_testing();
