package Manager;

=pod

This is an extended example of how to reap child workers if this
parent manager process receives a TERM signal.

=cut

use Moose;
with qw(MooseX::Workers);

use lib ".";

#sub POE::Kernel::ASSERT_DEFAULT () { 1 }
#sub POE::Kernel::TRACE_SIGNALS ()  { 1 }
use POE::Session; # Get export constants like KERNEL, HEAP, STATE etc

use Getopt::Long;
use Pod::Usage;

use Data::Dumper;

my $debug       = 0;
my $help        = 0;
my $num_workers = 4;

my @argv = @ARGV;

GetOptions(
    'debug|d'       => \$debug,
    'help|?'        => \$help,
    'num_workers=i' => \$num_workers,
);

pod2usage(1) if $help;
$ENV{CATALYST_DEBUG} = 1 if $debug;

sub run {
	my $self  = shift;

	for my $i (1..$num_workers) {
		$self->spawn( sub {
		    require App;
		    App->run();
		} );
	}

        POE::Kernel->run();
}

sub process_output {
	my ($debug, $worker_id) = @_;
	printf "[%02d] %s\n", $worker_id, $debug;
}

# Implement our Interface
sub worker_manager_start { warn "started worker manager: \n" }
sub worker_manager_stop  {
    my ($self) = shift;

    $self->_kill_workers();

    warn 'stopped worker manager'
}

sub _kill_workers {
    my ($self, @args) = shift;

    my @keys = $self->get_worker_ids;

    foreach my $wheel_id ( @keys ) {
	warn "going to kill_worker($wheel_id)\n";
	$self->kill_worker($wheel_id);
    }
 
}

sub max_workers_reached  { warn 'maximum worker count reached' }

sub worker_stdout  { shift; process_output(@_) }
sub worker_stderr  { shift; process_output(@_) }
sub worker_error   { shift; warn join ' ', @_; }
sub worker_finished    {
	my $self = shift;
	process_output('restarting...', 0);
	$self->spawn( sub { 
			      require App;
			      App->run();
		      } );
}
sub worker_started { shift; process_output("Worker $_[0] started", 0) }
sub sig_child      { shift; process_output("Worker $_[0] exited with signal $_[1]", 0) }

sub sig_TERM {
    my ($self) = @_;
    $self->_kill_workers();
    $self->num_workers = 0; # worker_finished() would restart them otherwise
}

no Moose;

my $manager = Manager->new();
$manager->run();

print "Done\n";
