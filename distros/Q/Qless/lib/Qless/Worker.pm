package Qless::Worker;
=head1 NAME

Qless::Worker

=cut

use strict; use warnings;
use Redis;
use Qless::Client;
use POSIX qw(setsid :sys_wait_h);

sub new {
	my $class = shift;

	my %opt = @_;

	$class = ref $class if ref $class;
	my $self = bless {}, $class;

	$self->{'debug'} = $opt{'debug'} || 0;


	#Redis server
	$opt{'host'} ||= '127.0.0.1:6379' if !$opt{'socket'};
	$self->debug('Connecting to Redis server at '.($opt{'socket'} || $opt{'host'}));
	my %redis_params        = (encoding => undef);
	$redis_params{'server'} = $opt{'host'} if $opt{'host'};
	$redis_params{'sock'}   = $opt{'socket'} if $opt{'socket'};
	$self->{'redis'}  = Redis->new(%redis_params);


	# Qless client and queues
	$self->{'client'} = Qless::Client->new($self->{'redis'});
	$self->{'client'}->worker_name($opt{'name'}) if $opt{'name'};
	my @queues = map { $self->{'client'}->queues($_) } @{ $opt{'queue'} };
	$self->debug('Listening for jobs in queues: '.join(', ', map { $_->name } @queues));
	$self->{'queues'} = \@queues;

	$self->{'interval'} = $opt{'interval'};
	$self->{'workers_max'} = $opt{'workers'} || 5;
	$self->{'workers'} = {};

	$self;
}

sub redis       { $_[0]->{'redis'} }
sub client      { $_[0]->{'client'} }

#TBD
sub resume {
	my $self = shift;
	my $jids = $self->client->workers( $self->client->worker_name )->{'jobs'};
}

sub _reaper {
	my $self = shift;
	while (( my $pid = waitpid(-1, WNOHANG)) > 0) {
		$self->debug("reaping worker PID $pid\n");
		delete $self->{'workers'}->{ $pid };
	}
	$SIG{'CHLD'} = sub { $self->_reaper };
}

sub run {
	my $self = shift;

    $SIG{'CHLD'} = sub { $self->_reaper };

	my $working = 1;
	my $queue_index = 0;
	my $queue_count = scalar @{ $self->{'queues'} };
	$self->debug('Starting loop');
	while ($working) {

		if (scalar keys %{ $self->{'workers'} } >= $self->{'workers_max'}) {
			sleep(1);
			next;
		}

		my $queue = $self->{'queues'}->[$queue_index];
		$self->debug('Queuing '.$queue->name);
		if (my $job = $queue->pop) {

			$self->debug('Got job class '.$job->klass);
			my $pid = fork();
			if (!defined $pid) {
				die "Could not fork: $!";
			}

			if (!$pid) {
				$job->process;
				exit;
			}

			$self->debug('Starting worker, PID: '.$pid);
			$self->{'workers'}->{ $pid } = 1;
		}
		else {
			$self->debug('Sleeping');
			sleep($self->{'interval'} || 1+int(rand(10)));
		}

		$queue_index++;
		if ($queue_index >= $queue_count) {
			$queue_index = 0;
		}
	}

	while(scalar keys %{ $self->{'workers'} }) {
		$self->debug('waiting for worker PIDS: '.join(', ', keys %{ $self->{'workers'} }));
		sleep(1);
	}

	$self->debug('done');
}


sub debug {
	return if !$_[0]->{'debug'};
	print $_[1],"\n";
}

1;
