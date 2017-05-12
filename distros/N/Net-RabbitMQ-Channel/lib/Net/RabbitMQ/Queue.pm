package Net::RabbitMQ::Queue;

use Class::Easy;

has 'connection';
has 'channel';
has 'exchange';
has 'name';

sub new {
	my $class   = shift;
	my $channel = shift;
	my $name    = shift;
	my $options = {@_};
	
	if ($channel->_do (
		'queue_declare', $name, {
			exchange_type => "topic",
			passive => 0, # the exchange will not get declared but an error will be thrown if it does not exist.
			durable => 1, # the exchange will survive a broker restart.
			auto_delete => 0, # the exchange will get deleted as soon as there are no more queues bound to it. Exchanges to which queues have never been bound will never get auto deleted.
			%$options
		}
	)) {
		return bless {
			name    => $name,
			channel => $channel
		}, $class;
	}
	
	# if channel didn't open, then we died before this string
}

sub bind {
	my $self = shift;
	my $xchange = shift;
	my $routing_key = shift;

	my $xchange_name = (ref ($xchange) and $xchange->can ('name')) ? $xchange->name : $xchange;

	$self->channel->_do ('queue_bind', $self->name, $xchange_name, $routing_key);
}

sub unbind {
	my $self = shift;
	my $xchange = shift;
	my $routing_key = shift;
	
	my $xchange_name = (ref ($xchange) and $xchange->can ('name')) ? $xchange->name : $xchange;
	
	$self->channel->_do ('queue_unbind', $self->name, $xchange_name, $routing_key);
}


sub get {
	my $self = shift;
	my $opts = {@_};
	
	my ($success, $result) = $self->channel->_do ('get', $self->name, $opts);
	
	return $result;
}

sub consume {
	my $self = shift;
	my $opts = {@_};
	
	my ($success, $result) = $self->channel->_do ('consume', $self->name, $opts);
}

sub recv {
	my $self = shift;
	#my $opts = {@_};
	
	my ($success, $result) = $self->channel->_do ('recv');
	
	return $result;
}

sub purge {
	my $self    = shift;
	my $no_wait = $_[0];
	
	my ($success, $result) = $self->channel->_do ('purge', $self->name, @_);
}

1;
