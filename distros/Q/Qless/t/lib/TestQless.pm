package TestQless;
use base qw(Test::Class);
use Redis;
use Qless::Client;
use Time::HiRes;

sub setup : Test(setup) {
	my $self = shift;

	$self->{'redis'}  = eval { Redis->new(debug=>0) };
	if ($@) {
		$self->SKIP_ALL('No Redis server at localhost');
		return;
	}
	$self->{'redis'}->script('flush');

	$self->{'client'} = Qless::Client->new($self->{'redis'});
	$self->{'q'}      = $self->{'client'}->queues('testing');

	# worker a
	{
		my $tmp = Qless::Client->new($self->{'redis'});
		$tmp->worker_name('worker-a');
		$self->{'a'} = $tmp->queues('testing');
	}

	# worker b
	{
		my $tmp = Qless::Client->new($self->{'redis'});
		$tmp->worker_name('worker-b');
		$self->{'b'} = $tmp->queues('testing');
	}

	$self->{'other'} = $self->{'client'}->queues('other');
}

sub teardown : Test(teardown) {
	my $self = shift;

	$self->{'redis'}->flushdb();
}

sub time_freeze {
	my $self = shift;
	$self->{'_original_sub'} = \&Time::HiRes::time;
	$self->{'_time'} = Time::HiRes::time;
	no warnings qw(redefine);
	*Time::HiRes::time = sub() {
		return $self->{'_time'};
	};
	use warnings;
}

sub time_unfreeze {
	my $self = shift;
	no warnings qw(redefine);
	*Time::HiRes::time = $self->{'_original_sub'};
	use warnings;
}

sub time_advance {
	my ($self, $value) = @_;
	$self->{'_time'} += $value;
}

1;
