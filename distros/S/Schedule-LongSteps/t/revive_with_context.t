#! perl -wt

use Test::More;
use Schedule::LongSteps;

my $do_break_stuff_fails = 1;
{

    package MyProcess;
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    use DateTime;
    has 'required_att' => ( is => 'ro', isa => 'Str', required => 1 );

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

# this process requires some context
my $required_context = { required_att => 'saussage' };

ok( my $long_steps = Schedule::LongSteps->new() );

ok(
    my $process = $long_steps->instantiate_process(
        'MyProcess', $required_context, { beef => 'saussage' }
    )
);
ok( $process->id() );

is( $process->what(), 'do_break_stuff' );
is_deeply( $process->state(), { beef => 'saussage' } );

# Time to run!
ok( $long_steps->run_due_processes($required_context) );

# do_break_stuff fails
like( $process->error(), qr(something went wrong), 'something did go wrong' );

$do_break_stuff_fails = 0;
eval { $long_steps->revive( $process->id() ) };
like(
    $@,
    qr|Attribute \(required_att\) is required at|,
    'failed as the context was not provived'
);

# the process was not revived, so the error and state are stil the same
like( $process->error(), qr(something went wrong), 'something is still wrong' );
is( $process->status(), 'terminated', 'process status is terminated' );

# now revive with a context
ok( $long_steps->revive( $process->id(), $required_context ) );

# the process was fullyrevived, so the error and state have been reset
is( $process->error(),  undef,    'error has been reset' );
is( $process->status(), 'paused', 'process status is paused' );

ok( $long_steps->run_due_processes($required_context), 'run the revived step' );

# And check the step properties have been
ok( $long_steps->run_due_processes($required_context), 'run the final step' );
is_deeply( $process->state(), { the => 'final', state => 1 } );
is( $process->status(), 'terminated' );
is( $process->run_at(), undef );

# # # Check no due step have run again
ok( !$long_steps->run_due_processes($required_context) );

done_testing();
