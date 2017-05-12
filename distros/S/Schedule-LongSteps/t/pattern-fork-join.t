#! perl -wt

use Test::More;
use Test::MockDateTime;
use DateTime;

# use Log::Any::Adapter qw/Stderr/;

use Schedule::LongSteps;

{
    package AnotherProcessClass;
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    sub build_first_step{
        my ($self) = @_;
        return $self->new_step({ what => 'do_one_thing' , run_at => DateTime->now() });
    }
    sub do_one_thing{
        my ($self) = @_;
        return $self->final_step({ state => { from => 'another'  }  }) ;
    }
}

{
    package YetAnotherProcessClass;
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    sub build_first_step{
        my ($self) = @_;
        return $self->new_step({ what => 'do_one_thing' , run_at => DateTime->now() });
    }
    sub do_one_thing{
        my ($self) = @_;
        return $self->final_step({ state => { from => 'yetanother'  }  }) ;
    }
}


{
    package MyProcess;
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    use DateTime;
    sub build_first_step{
        my ($self) = @_;
        return $self->new_step({ what => 'do_fork', run_at => DateTime->now() });
    }

    sub do_fork{
        my ($self) = @_;

        my $state = $self->state();

        my $p1 = $self->longsteps->instantiate_process('AnotherProcessClass');
        my $p2 = $self->longsteps->instantiate_process('YetAnotherProcessClass');

        return $self->new_step({ what => 'do_join', run_at => DateTime->now() , state => { processes => [ $p1->id(), $p2->id() ], %$state } });
    }

    sub do_join{
        my ($self) = @_;
        return $self->wait_processes(
            $self->state()->{processes},
            sub{
                my ( @processes ) = @_;
                return $self->final_step({
                    state => {
                        done => 'joined',
                        pstates => [ map{ $_->state() } @processes ]
                    }});
            });
    }
}


my $long_steps = Schedule::LongSteps->new();
ok( my $process = $long_steps->instantiate_process('MyProcess', undef, {}) );

{
    # Time to run!
    ok( $long_steps->run_due_processes() );

    is( $process->what() , 'do_join' );
    is_deeply( $process->state() , { processes => [ 2 , 3 ] });
}



{
    # Time to run again
    # This will run (in order):
    #  - The 'do_join' step of the main process (which will fail).
    #  - The 'Another' sub process finishing action
    #  - The 'YetAnother' sub process finishing action
    is( $long_steps->run_due_processes(), 3 );

    # This will run:
    # - The do_join step of the main process (which will terminate).
    ok( $long_steps->run_due_processes() );

    is( $process->what() , 'do_join' );
    is( $process->status() , 'terminated' );
    is( $process->error() , undef );
    is_deeply($process->state() , { done => 'joined' , pstates => [ { from => 'another' } , { from => 'yetanother' }] });
}

done_testing();
