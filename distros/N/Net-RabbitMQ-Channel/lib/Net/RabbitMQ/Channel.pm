package Net::RabbitMQ::Channel;

use Class::Easy;

use Net::RabbitMQ;

unless ($^O eq 'MSWin32') {
	use Sys::SigAction;
}

use Net::RabbitMQ::Exchange;
use Net::RabbitMQ::Queue;

our $VERSION = '0.05';

# has 'mq';

has exchange_pack => 'Net::RabbitMQ::Exchange';
has queue_pack    => 'Net::RabbitMQ::Queue';

has 'number';

our @NO_CHANNEL_CALLS = ('recv');

sub new {
	my $class  = shift;
	my $number = shift;
	my $config = {@_};
	
	$config->{mq}     = Net::RabbitMQ->new;
	$config->{number} = $number;
	
	$config->{reconnect_timeout} ||= 10;
	
	my $self = bless $config, $class;

	if ($self->_confirmed_connect) {
		return $self;
	}
	
	die "can't open connection";
	# if channel didn't open, then we died before this string
}

sub exchange_declare {
	my $self = shift;
	my $name = shift;
	my $args = {@_};
	
	$args->{package} = $self->exchange_pack
		unless exists $args->{package};
	
	$args->{package}->new ($self, $name, %$args);
}

sub queue_declare {
	my $self = shift;
	my $name = shift;
	my $args = {@_};
	
	$args->{package} = $self->queue_pack
		unless exists $args->{package};
	
	return $args->{package}->new ($self, $name, %$args);
}

sub _failed_host_sort_sub {
	my ($hosts, $sort_a, $sort_b) = @_;
	return !exists $hosts->{$sort_a}->{failed}
		? -1
		: !exists $hosts->{$sort_b}->{failed}
			? 1
			: $hosts->{$sort_b}->{failed} <=> $hosts->{$sort_a}->{failed}
}


# here we try to connect, if all servers fails, then die
sub _confirmed_connect {
	my $self = shift;
	my $is_reconnect = shift;
	
	my $mq = $self->{mq};
	
	local $@;
	
	my $success = 0;
	
	my $hosts = $self->{hosts};
	
	foreach my $host (sort {_failed_host_sort_sub ($hosts, $a, $b)} keys %$hosts
	) {
		my $last_failed = $hosts->{$host}->{failed};
		if (defined $last_failed and (time - $last_failed < $self->{reconnect_timeout})) {
			die "no hosts can be reached within $self->{reconnect_timeout} sec. you must check hosts availability or enlarge your interval";
		}
		
		eval {
			if ($^O ne 'MSWin32') {
				# warn "setting alarm";
				my $sig_handler = sub {
					# failed disconnect is safe solution
					# warn "alarm called";
					$self->{hosts}->{$host}->{failed} = time;
					$success = 0;
					die "timeout";
				};
				my $h = Sys::SigAction::set_sig_handler ('ALRM', $sig_handler);
				$h->{ACT}->{HANDLER} = $sig_handler;
				#use Data::Dumper;
				#warn Dumper $h;
				#$SIG{'ALRM'} = sub {die;};
				alarm ($self->{timeout} || 10);
			}

			#warn "before connect";

			$mq->connect ($host, $self->{hosts}->{$host});
			$self->_do ('channel_open')
				unless $is_reconnect;
			$success = 1;
			
			#warn "after connect";

			alarm 0;
		};
		
		#warn "after eval, before alarm";

		alarm 0;
		#warn "after eval";

		if ($success) {
			delete $hosts->{$host}->{failed};
			return 1
		} else {
			$self->{hosts}->{$host}->{failed} = time;
		}
	}
	
	die "we can't connect to any provided server: $@";
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
	
	# warn "cmd: $cmd, num: ", $self->number, ", array: @_";
	
	# use warnings FATAL => qw(uninitialized);

	my @params = @_;
	
	unshift @params, $self->number
		unless scalar grep {$_ eq $cmd} @NO_CHANNEL_CALLS;
	
	# real server work -> we must restart connection after failure
	eval {
		# warn "$cmd ", $self->number;
		$result  = $self->{mq}->$cmd (@params);
		$success = 1;
	};
	
	#no warnings qw(uninitialized);
	#debug "command: $cmd, result: $result, success: $success";
	#use warnings qw(uninitialized);
	
	# TODO: check for real connection error, we don't want to run erratical command another time
	unless ($success) {
		
		# warn $@;
		
		$self->_confirmed_connect (1); # send flag for reconnect
		$self->{mq}->channel_open ($self->number);
		
		# if we have more than one failure after successful
		# reconnect, then we must die
		$result  = $self->{mq}->$cmd (@params);
		$success = 1;
	}
	
	return wantarray ? ($success, $result) : $success;
}

sub publish {
	my $self = shift;
	my $routing_key = shift;
	my $body = shift;
	my $props = {@_};
	
	my $opts = {};
	
	foreach my $k (keys %$props) {
		if ($k eq 'exchange' or $k eq 'mandatory' or $k eq 'immediate') {
			$opts->{$k} = delete $props->{$k};
		}
	}
	
	my ($success, $result) = $self->_do ('publish', $routing_key, $body, $opts, $props);
}

sub close {
	my $self = shift;
	
	
}

1;

=head1 NAME

Net::RabbitMQ::Channel - use rabbitmq, OOP style

=head1 SYNOPSIS

	use Net::RabbitMQ::Channel;

	my $channel = Net::RabbitMQ::Channel->new (1, {
		hosts => {
			rabbit1 => {user => 'guest', pass => 'guest'},
			rabbit2 => {user => 'guest', pass => 'guest'}
		}
	});

	my $exchange = $channel->exchange_declare (
		'test.x', 
		exchange_type => "topic",
	);

	my $publisher_key = 'test.*';

	# consumer part
	my $queue = $channel->queue_declare (
		'test.q',
		exclusive => 0,
	);

	$queue->bind ($exchange, $publisher_key);

	# publisher part
	$exchange->publish ($publisher_key, $message,
		app_id => 'test',
		timestamp => time
	);
	
	# consumer part
	my $message = $queue->get;

=head1 METHODS

=head2 init

=over 4

=item new

	my $channel = Net::RabbitMQ::Channel->new (1, {
		# mandatory
		hosts => {host_name => {user => 'user_name', pass => 'password'}},
		# optional
	});


when creating Net::RabbitMQ::Channel you must provide
channel number and configuration options.

in the current version only 'hosts' key is supported. each key for 'hosts' specifies
one rabbitmq broker configuration. if current broker connection fails, module tries
to reconnect to another one.


=cut

=back

=head2 working with channel

=over 4

=item exchange_declare

declares exchange

	my $exchange = $self->exchange_declare (
		'test.exchange',
		package => 'My::Exchange', # Net::RabbitMQ::Exchange if omitted
		passive => 0,              # 0
		durable => 1,              # 1
		auto_delete => 0,          # 0
		exchange_type => "topic"
	);


=item queue_declare

declares queue


	my $queue = $self->queue_declare (
		'test.queue',
		package => 'My::Queue', # Net::RabbitMQ::Queue if omitted
		passive => 0,           # 0
		durable => 1,           # 1
		auto_delete => 0,       # 0
		exclusive => 0
	);


=item publish

publish message to routing key

a typical workflow for a producer role is: open channel, declare exchange,
and publish message via routing key

please, note: queue for recieving that message must be declared
and binded to exchange using routing key prior to message publishing.

	$channel->publish ($publisher_key, $message, {exchange => $exchange->name}, {
		# content_type => $string,
		# content_encoding => $string,
		# correlation_id => $string,
		# reply_to => $string,
		# expiration => $string,
		# message_id => $string,
		# type => $string,
		# user_id => $string,
		app_id => 'test',
		# delivery_mode => $integer,
		# priority => $integer,
		timestamp => time

	});
	

=item close

stub

=cut

=back

=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net::RabbitMQ::Channel>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
