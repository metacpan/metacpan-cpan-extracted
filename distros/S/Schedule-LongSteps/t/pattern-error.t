#! perl -wt

use strict;
use warnings;

use Log::Any::Test;
use Log::Any qw/$log/;

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
        die "SOMETHING HORRIBLE HAPPENED" x 100;
    }
}

{
    my $captured_error;
    ok( my $long_steps = Schedule::LongSteps->new(
        {
            error_limit => 123,
            on_error => sub{
              my ( $process ) = @_;
              is( $process->status() , 'terminated' );
              like( $process->error()  , qr/SOMETHING HORRIBLE/ );
              is( length( $process->error() ) , 123 );
              $captured_error = $process->error();
          } }) );
    {
        ok( my $process = $long_steps->instantiate_process('MyProcess') );
        # Time to run!
        ok( $long_steps->run_due_processes() );
        like( $process->error() , qr/SOMETHING HORRIBLE/ );
        is( $process->status() , 'terminated' );
    }
    like( $captured_error , qr/SOMETHING HORRIBLE/ );
}

{
    my $never_reached = 1;
    my $reached = 0;

    my $long_steps = Schedule::LongSteps->new({ on_error => sub{
                                                    $reached = 1;
                                                    die "ERROR HANDLER FAILURE\n";
                                                    $never_reached = 0;
                                                } });
    ok( my $process = $long_steps->instantiate_process('MyProcess') );
    # Time to run!
    ok( $long_steps->run_due_processes() );
    ok( $reached );
    ok( $never_reached );
    is_deeply( $log->msgs()->[-1],{
        level => 'critical',
        message => "Error handler triggered an error: ERROR HANDLER FAILURE\n",
        category => 'Schedule::LongSteps'
    });
}



done_testing();
