#! perl -wt

use Test::More;
use Schedule::LongSteps;

my $do_break_stuff_fails = 1;
{

    package MyProcess;
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    use DateTime;

    sub build_first_step {
        my ($self) = @_;
        return $self->new_step(
            { what => 'do_break_stuff', run_at => DateTime->now() } );
    }

    sub do_break_stuff {
        my ($self) = @_;
        die 'something went wrong' if $do_break_stuff_fails;
        return $self->new_step(
            { what => 'do_final_step', run_at => DateTime->now() } );
    }

    sub do_final_step {
        my ($self) = @_;
        return $self->final_step( { state => { the => 'final', state => 1 } } );
    }
}

ok( my $long_steps = Schedule::LongSteps->new() );

ok(
    my $process = $long_steps->instantiate_process(
        'MyProcess', undef, { beef => 'saussage' }
    )
);
ok( $process->id() );

is( $process->what(), 'do_break_stuff' );
is_deeply( $process->state(), { beef => 'saussage' } );

# Time to run!
ok( $long_steps->run_due_processes() );
like( $process->error(), qr(something went wrong), 'something did go wrong' );

# this should die, as there is no do_the_hoff
eval{ $long_steps->revive( $process->id(), {}, 'do_the_hoff' ) };
like( $@, qr(Unable revive \d+ to do_the_hoff), 'revive to an incorrect function' );

$do_break_stuff_fails = 0;
is( $long_steps->revive( $process->id() ), 1, 'Process was revived' );
is( $process->error(),  undef,    'revived process error was undef' );
is( $process->status(), "paused", 'revived process status is paused' );

ok( $long_steps->run_due_processes(), 'run the revived step' );

# And check the step properties have been
ok( $long_steps->run_due_processes(), 'run the final step' );
is_deeply( $process->state(), { the => 'final', state => 1 } );
is( $process->status(), 'terminated' );
is( $process->run_at(), undef );

# Check no due step have run again
ok( !$long_steps->run_due_processes() );

done_testing();
