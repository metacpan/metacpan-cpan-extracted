package Net::RabbitMQ::Connection;

use Class::Easy;

use Net::RabbitMQ;

use Net::RabbitMQ::Channel;
use Net::RabbitMQ::Exchange;
use Net::RabbitMQ::Queue;

# has 'mq';

has exchange_pack => 'Net::RabbitMQ::Exchange';
has queue_pack    => 'Net::RabbitMQ::Queue';

&init;

sub init {
	my $class = caller;
	
	# singleton
	# has instance => $class->new;
}

sub new {
	my $class  = shift;
	my $config = {@_};
	
	$config->{mq} = Net::RabbitMQ->new;
	
	my $self = bless $config, $class;

	$self->confirmed_connect;
	
	return $self;
}

sub channel {
	my $self = shift;
	my $num  = shift;
	
	$self->{_channels}->{$num} = Net::RabbitMQ::Channel->new ($num, $self)
		unless $self->{_channels}->{$num};
	
	return $self->{_channels}->{$num};
}

# here we try to connect, if all servers fails, then die
sub confirmed_connect {
	my $self = shift;
	
	my $mq = $self->{mq};
	
	local $@;
	
	foreach my $host (keys %{$self->{hosts}}) {
		eval {
			$mq->connect ($host, $self->{hosts}->{$host});
		};
		
		return unless $@;
	}
	
	die "we can't connect to any server";
}

sub _do {
	my $self = shift;
	my $cmd  = shift;
	
	my $verify = "_verify_$cmd";
	
	# parameter verification
	if ($self->can ($verify)) {
		return unless $self->$verify (@_);
	}
	
	local $@;
	
	my $result;
	my $success = 0;
	
	# real server work -> we must restart connection after failure
	eval {
		$result  = $self->{mq}->$cmd (@_);
		$success = 1;
	};
	
	# warn "command: $cmd, result: $result, success: $success, errors: $@";
	
	# TODO: check for real connection error, we don't want to run erratical command another time
	if ($@) {
		$self->confirmed_connect ($_[0]); # send channel for reconnect
		
		# if we have more than one failure after successful
		# reconnect, then we must die
		$result  = $self->{mq}->$cmd (@_);
		$success = 1;
	}
	
	return wantarray ? ($success, $result) : $success;
}

1;