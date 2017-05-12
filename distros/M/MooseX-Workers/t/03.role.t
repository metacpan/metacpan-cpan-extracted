use Test::More tests => 6;
use lib qw(lib);

{

    package ManagerRole;
    use Moose::Role;
    with qw(MooseX::Workers);

    sub worker_manager_start {
        ::pass('started worker manager');
    }

    sub worker_manager_stop {
        ::pass('stopped worker manager');
    }

    sub worker_stdout {
        my ( $self, $output ) = @_;
        ::is( $output, 'HELLO' );
    }

    sub worker_stderr {
        my ( $self, $output ) = @_;
        ::is( $output, 'WORLD' );
    }
    sub worker_error { }
    sub worker_finished  { ::pass('worker finished') }

    sub worker_started { ::pass('worker started') }
    no Moose::Role;
}

{

    package Manager;
    use Moose;
    with qw(ManagerRole);

    no Moose;
}

my $m = Manager->new();
$m->run_command( sub { print "HELLO\n"; print STDERR "WORLD\n" } );
POE::Kernel->run();
