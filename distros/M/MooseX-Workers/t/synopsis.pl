package Manager;
use Moose;
with qw(MooseX::Workers);

sub run {
    $_[0]->spawn( sub { sleep 3; print "Hello World\n" } );
    warn "Running now ... ";
    POE::Kernel->run();
}

# Implement our Interface
sub worker_manager_start { warn 'started worker manager' }
sub worker_manager_stop  { warn 'stopped worker manager' }
sub max_workers_reached  { warn 'maximum worker count reached' }

sub worker_stdout  { shift; warn join ' ', @_; }
sub worker_stderr  { shift; warn join ' ', @_; }
sub worker_error   { shift; warn join ' ', @_; }
sub worker_finished { warn 'worker finished' }
sub worker_started { shift; warn join ' ', @_; }
sub sig_child      { shift; warn join ' ', @_; }
no Moose;

Manager->new->run();
