use Test::More tests => 14;
use lib qw(lib);
use strict;

my $SIG = $^O eq 'MSWin32' ? 'INT' : 'TERM';

{
    package Manager;
    use MooseX::Workers::Job;
    use Moose;
    with qw(MooseX::Workers);

    sub worker_manager_start {
        ::pass('started worker manager');
    }

    sub worker_manager_stop {
        ::pass('stopped worker manager');
    }

    sub worker_stdout {
        my ( $self, $output, $wheel ) = @_;
        ::is( $output, "HELLO", "STDOUT" );
    }

    sub worker_stderr {
        my ( $self, $output, $wheel ) = @_;
        ::is( $output, "WORLD", "STDERR" );
    }

    sub worker_error { ::fail('Got error?'.@_) }

    sub worker_started { 
        my ( $self, $job ) = @_;
        ::pass("worker started");
        kill $SIG, $$;    # Send the worker manager (myself) the $SIG signal
    }
    
    sub worker_finished  { 
        my ( $self, $job ) = @_;
        ::pass("worker_finished");
    }

    sub run { 
        my $job = MooseX::Workers::Job->new(
            command => sub { print "HELLO\n"; print STDERR "WORLD\n"; },
        );
        $_[0]->run_command( $job );
        POE::Kernel->run();
    }
    no Moose;
}


# --------------------------------
# When we have no sig_$SIG(), so we should fall back to our vanilla non-POE $SIG trap.
# --------------------------------
$SIG{$SIG} = sub { ::pass("non-POE $SIG trapped") };
Manager->new()->run();

# --------------------------------
# But as soon as we define sig_$SIG(), we should hit that one and not the Perl one.
# --------------------------------
$SIG{$SIG} = sub { ::fail("non-POE $SIG trapped") };
Manager->meta->add_method( "sig_$SIG" => sub { 
   my ( $self, $job ) = @_;
   ::pass("worker manager trapped the $SIG signal");
});
Manager->new()->run();


