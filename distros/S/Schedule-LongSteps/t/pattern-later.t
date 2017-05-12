#! perl -wt

use Test::More;
use Test::MockDateTime;
use DateTime;

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
        return $self->new_step({ what => 'do_end', run_at => DateTime->now()->add( days => 2 ) });
    }

    sub do_end{
        my ($self) = @_;
        return $self->final_step({ state => { final => 'state' }});
    }
}


ok( my $long_steps = Schedule::LongSteps->new() );

ok( my $process = $long_steps->instantiate_process('MyProcess', undef, { beef => 'saussage' }) );

# Time to run!
ok( $long_steps->run_due_processes() );

is( $process->what() , 'do_end' );

# Nothing to run right now
ok( ! $long_steps->run_due_processes() );

# Simulate 3 days after now.
my $three_days = DateTime->now()->add( days => 3 );

on $three_days.'' => sub{
    ok( $long_steps->run_due_processes() , "Ok one step was run");
};

is_deeply( $process->state() , { final => 'state' });

done_testing();
