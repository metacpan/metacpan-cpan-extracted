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
        return $self->new_step({ what => 'do_end', run_at => DateTime->now() });
    }

    sub do_end{
        my ($self) = @_;
        return $self->final_step({ state => { the => 'final', state => 1 }  }) ;
    }
}


ok( my $long_steps = Schedule::LongSteps->new() );

ok( my $process = $long_steps->instantiate_process('MyProcess', undef, { beef => 'saussage' }) );

# Time to run!
ok( $long_steps->run_due_processes() );

# And check the step properties have been
is_deeply( $process->state(), { the => 'final', state => 1 });
is( $process->status() , 'terminated' );
is( $process->run_at() , undef );

# Check no due step have run again
ok( ! $long_steps->run_due_processes() );

done_testing();
