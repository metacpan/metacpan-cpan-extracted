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
        return $self->new_step({ what => 'do_choose', run_at => DateTime->now() });
    }

    sub do_choose{
        my ($self) = @_;

        if( $self->state()->{choice} == 1 ){
            return $self->new_step({ what => 'do_choice1', run_at => DateTime->now() });
        }
        return $self->new_step({ what => 'do_choice2', run_at => DateTime->now() });
    }

    sub do_choice1{
        my ($self) = @_;
        return $self->final_step({ state => { done => 'choice1' }});
    }

    sub do_choice2{
        my ($self) = @_;
        return $self->final_step({ state => { done => 'choice2' }});
    }
}


ok( my $long_steps = Schedule::LongSteps->new() );
{
    ok( my $process = $long_steps->instantiate_process('MyProcess', undef, { choice => 1 }) );
    # Time to run!
    ok( $long_steps->run_due_processes() );

    is( $process->what() , 'do_choice1' );

    ok( $long_steps->run_due_processes() );

    is_deeply( $process->state() , { done => 'choice1' });
}

{
    ok( my $process = $long_steps->instantiate_process('MyProcess', undef, { choice => 2 }) );
    # Time to run!
    ok( $long_steps->run_due_processes() );

    is( $process->what() , 'do_choice2' );

    ok( $long_steps->run_due_processes() );

    is_deeply( $process->state() , { done => 'choice2' });
}

done_testing();
