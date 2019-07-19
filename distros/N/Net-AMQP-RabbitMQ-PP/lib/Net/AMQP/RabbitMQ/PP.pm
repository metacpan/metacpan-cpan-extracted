package Net::AMQP::RabbitMQ::PP;

use strict;
use warnings;

our $VERSION = '0.09';

use Carp;
use Cwd;
use English qw(-no_match_vars);
use File::ShareDir;
use IO::Select;
use IO::Socket::INET;
use Socket qw( IPPROTO_TCP );
use List::MoreUtils;
use Net::AMQP;
use Sys::Hostname;
use Try::Tiny;
use Time::HiRes;

use constant HAS_TLS => eval { require IO::Socket::SSL; 1 };

sub new {
	my ( $class, %parameters ) = @_;

	if( ! %Net::AMQP::Protocol::spec ) {
		Net::AMQP::Protocol->load_xml_spec(
			File::ShareDir::dist_file(
				'Net-AMQP-RabbitMQ-PP',
				'amqp0-9-1.extended.xml'
			)
		);
	}

	my $self = bless {}, ref $class || $class;

	return $self;
}

sub connect {
	my ( $self, %args ) = @_;

	try {
		local $SIG{ALRM} = sub {
			Carp::croak 'Timed out';
		};

		if( $args{timeout} ) {
			Time::HiRes::alarm( $args{timeout} );
		}

		my $connection_class = "IO::Socket::INET";
		my %connection_args;

		if ( $args{secure} ) {
			die "IO::Socket::SSL is required for secure connections"
				if ! HAS_TLS;
			$connection_class = "IO::Socket::SSL";
			my @ssl_args = grep { /^SSL_/ } sort keys %args;
			@connection_args{ @ssl_args } = @args{ @ssl_args };
		}

		$self->_set_handle(
			$connection_class->new(
				PeerAddr => $args{host} || 'localhost',
				PeerPort => $args{port} || ( $args{secure} ? 5671 : 5672 ),
				( ! $args{secure} ? ( Proto => 'tcp' ) : () ),
				( $args{socket_timeout} ? ( Timeout => $args{socket_timeout} ) : () ),
				%connection_args,
			) or Carp::croak "Could not connect: $EVAL_ERROR"
		);

		$self->_select( IO::Select->new( $self->_get_handle ) );

		if( $args{timeout} ) {
			Time::HiRes::alarm( 0 );
		}
	}
	catch {
		Carp::croak $_;
	};

	$self->_get_handle->autoflush( 1 );

	my $password = $args{password} || 'guest';
	my $username = $args{username} || 'guest';
	my $virtualhost = $args{virtual_host} || '/';
	my $heartbeat = $args{heartbeat} || 0;


	# Backlog of messages.
	$self->_backlog( [] );

	$self->_startup(
		username => $username,
		password => $password,
		virtual_host => $virtualhost,
		heartbeat => $heartbeat,
	);

	return $self;
}

sub set_keepalive {
	my ( $self, %args ) = @_;
	my $handle = $self->_get_handle;
	my $idle = $args{idle};
	my $count = $args{count};
	my $interval = $args{interval};

	if( eval { require Socket::Linux } ) {
		# Turn on keep alive probes.
		defined $handle->sockopt( SO_KEEPALIVE, 1 )
			or Carp::croak "Could not turn on tcp keep alive: $OS_ERROR";

		# Time between last meaningful packet and first keep alive
		if( defined $idle ) {
			defined $handle->setsockopt( Socket::IPPROTO_TCP, Socket::Linux::TCP_KEEPIDLE(), $idle )
				or Carp::croak "Could not set keep alive idle time: $OS_ERROR";
		}

		# Time between keep alives
		if( defined $interval ) {
			defined $handle->setsockopt( Socket::IPPROTO_TCP, Socket::Linux::TCP_KEEPINTVL(), $interval )
				or Carp::croak "Could not set keep alive interval time: $OS_ERROR";
		}

		# Number of failures to allow
		if( defined $count ) {
			defined $handle->setsockopt( Socket::IPPROTO_TCP, Socket::Linux::TCP_KEEPCNT(), $count )
				or Carp::croak "Could not set keep alive count: $OS_ERROR";
		}
	}
	else {
		Carp::croak "Unable to find constants for keepalive settings";
	}

	return;
}

sub _default {
	my ( $self, $key, $value, $default ) = @_;
	if( defined $value ) {
		return ( $key => $value );
	}
	elsif( defined $default ) {
		return $key => $default;
	}
	return;
}

sub _startup {
	my ( $self, %args ) = @_;

	my $password = $args{password};
	my $username = $args{username};
	my $virtualhost = $args{virtual_host};

	# Startup is two-way rpc. The server starts by asking us some questions, we
	# respond then tell it we're ready to consume everything.
	#
	# The initial hand shake is all on channel 0.

	# Kind of non obvious but we're waiting for a response from the server to
	# our initial headers.
	$self->rpc_request(
		channel => 0,
		output => [ Net::AMQP::Protocol->header ],
		response_type => 'Net::AMQP::Protocol::Connection::Start',
	);

	my %client_properties = (
		# Can plug all sorts of random stuff in here.
		platform => 'Perl/NetAMQP',
		product => Cwd::abs_path( $PROGRAM_NAME ),
		information => 'http://github.com/Humanstate/net-amqp-rabbitmq',
		version => $VERSION,
		host => hostname(),
	);

	$client_properties{capabilities}{consumer_cancel_notify} = Net::AMQP::Value::true;

	my $servertuning = $self->rpc_request(
		channel => 0,
		output => [
			Net::AMQP::Protocol::Connection::StartOk->new(
				client_properties => \%client_properties,
				mechanism => 'AMQPLAIN',
				response => {
					LOGIN => $username,
					PASSWORD => $password,
				},
				locale => 'en_US',
			),
		],
		response_type => 'Net::AMQP::Protocol::Connection::Tune',
	);

	my $serverheartbeat = $servertuning->heartbeat;
	my $heartbeat = $args{heartbeat} || 0;

	if( $serverheartbeat != 0 && $serverheartbeat < $heartbeat ) {
		$heartbeat = $serverheartbeat;
	}

	# Respond to the tune request with tuneok and then officially kick off a
	# connection to the virtual host.
	$self->rpc_request(
		channel => 0,
		output => [
			Net::AMQP::Protocol::Connection::TuneOk->new(
				channel_max => 2047,
				frame_max => 131072,
				heartbeat => $heartbeat,
			),
			Net::AMQP::Protocol::Connection::Open->new(
				virtual_host => $virtualhost,
			),
		],
		response_type => 'Net::AMQP::Protocol::Connection::OpenOk',
	);

	return;
}

sub rpc_request {
	my ( $self, %args ) = @_;
	my $channel = $args{channel};
	my @output = @{ $args{output} || [] };

	my @responsetype ;
	if( $args{response_type} ) {
		@responsetype = ref $args{response_type}
			? @{ $args{response_type} }
			: ( $args{response_type} );
	}

	foreach my $output ( @output ) {
		$self->_send(
			channel => $channel,
			output => $output,
		);
	}

	if( ! @responsetype ) {
		return;
	}

	return $self->_local_receive(
		channel => $channel,
		method_frame => [ @responsetype ],
	)->method_frame;
}

sub _backlog {
	my ( $self, $backlog ) = @_;
	$self->{backlog} = $backlog if $backlog;
	return $self->{backlog};
}

sub _select {
	my ( $self, $select ) = @_;
	$self->{select} = $select if $select;
	return $self->{select};
}

sub _clear_handle {
	my ( $self ) = @_;
	$self->_set_handle( undef );
	return;
}

sub _set_handle {
	my ( $self, $handle ) = @_;
	$self->{handle} = $handle;
	return;
}

sub _get_handle {
	my ( $self ) = @_;
	my $handle = $self->{handle};
	if( ! $handle ) {
		Carp::croak "Not connected to broker.";
	}
	return $handle;
}

sub _read_length {
	my ( $self, $data, $length ) = @_;
	my $bytesread = $self->_get_handle->sysread( $$data, $length );
	if( ! defined $bytesread ) {
		Carp::croak "Read error: $OS_ERROR";
	}
	elsif( $bytesread == 0 ) {
		$self->_clear_handle;
		Carp::croak "Connection closed";
	}
	return $bytesread;
}

sub _read {
	my ( $self, %args ) = @_;
	my $data;
	my $stack;

	my $timeout = $args{timeout};
	if( ! $timeout || $self->_select->can_read( $timeout ) ) {
		# read length (in bytes) of incoming frame, by reading first 8 bytes and
		# unpacking.
		my $bytesread = $self->_read_length( \$data, 8 );

		$stack .= $data;
		my ( $type_id, $channel, $length ) = unpack 'CnN', substr $data, 0, 7, '';
		$length ||= 0;

		# read until $length bytes read
		while ( $length > 0 ) {
			$bytesread = $self->_read_length( \$data, $length );
			$length -= $bytesread;
			$stack .= $data;
		}

		return Net::AMQP->parse_raw_frames( \$stack );
	}
	return ();
}

sub _check_frame {
	my( $self, $frame, %args ) = @_;

	if( defined $args{channel} && $frame->channel != $args{channel} ) {
		return 0;
	}

	if( defined $args{type} && $args{type} ne ref $frame ) {
		return 0;
	}

	if( defined $args{method_frame} &&
		! List::MoreUtils::any { ref $frame->{method_frame} eq $_ } @{ $args{method_frame} } ) {
		return 0;
	}

	if( defined $args{header_frame} &&
		! List::MoreUtils::any { ref $frame->{header_frame} eq $_ } @{ $args{header_frame} } ) {
		return 0
	}

	return 1;
}

sub _first_in_frame_list {
	my( $self, $list, %args ) = @_;
	my $firstindex = List::MoreUtils::firstidx { $self->_check_frame( $_, %args) } @{ $list };
	my $frame;
	if( $firstindex >= 0 ) {
		$frame = $list->[$firstindex];
		splice @{ $list }, $firstindex, 1;
	}
	return $frame;
}

sub _receive_cancel {
	my( $self, %args ) = @_;

	my $cancel_frame = $args{cancel_frame};

	if( my $sub = $self->basic_cancel_callback ) {
		$sub->(
			cancel_frame => $cancel_frame,
		);
	};

	return;
}

sub _local_receive {
	my( $self, %args ) = @_;

	# Check the backlog first.
	if( my $frame = $self->_first_in_frame_list( $self->_backlog, %args ) ) {
		return $frame;
	}

	my $due_by = Time::HiRes::time() + ($args{timeout} || 0);

	while( 1 ) {
		my $timeout = $args{timeout} ? $due_by - Time::HiRes::time() : 0;
		if( $args{timeout} && $timeout <= 0 ) {
			return;
		}

		my @frames = $self->_read(
			timeout => $timeout,
		);

		foreach my $frame ( @frames ) {
			# TODO March of the ugly.
			# TODO Reasonable cancel handlers look like ?
			if( $self->_check_frame( $frame, ( method_frame => [ 'Net::AMQP::Protocol::Basic::Cancel' ] ) ) ) {
				$self->_receive_cancel(
					cancel_frame => $frame,
				);
			}

			# TODO This is ugly as sin.
			# Messages on channel 0 saying that the connection is closed. That's
			# a big error, we should probably mark this session as invalid.
			# TODO could combine checks, mini optimization
			if( $self->_check_frame( $frame, ( method_frame => [ 'Net::AMQP::Protocol::Connection::Close'] ) ) ) {
				$self->_clear_handle;
				Carp::croak sprintf 'Connection closed %s', $frame->method_frame->reply_text;
			}
			# TODO only filter for the channel we passed?
			elsif( $self->_check_frame( $frame, ( method_frame => [ 'Net::AMQP::Protocol::Channel::Close'] ) ) ) {
				# TODO Mark the channel as dead?
				Carp::croak sprintf 'Channel %d closed %s', $frame->channel, $frame->method_frame->reply_text;
			}
		}

		my $frame = $self->_first_in_frame_list( \@frames, %args );
		push @{ $self->_backlog }, @frames;
		return $frame if $frame;
	}

	return;
}

sub _receive_delivery {
	my ( $self, %args ) = @_;

	my $headerframe = $self->_local_receive(
		channel => $args{channel},
		header_frame => [ 'Net::AMQP::Protocol::Basic::ContentHeader' ],
	);

	my $length = $headerframe->{body_size};
	my $payload = '';

	while( length( $payload ) < $length ) {
		my $frame = $self->_local_receive(
			channel => $args{channel},
			type => 'Net::AMQP::Frame::Body',
		);
		$payload .= $frame->{payload};
	}

	return (
        content_header_frame => $headerframe,
        payload => $payload,
        ( $args{delivery_tag} ? ( delivery_tag => $args{delivery_tag} ) : () )
	);
}

sub receive {
	my ( $self, %args ) = @_;

	my $nextframe = $self->_local_receive(
		timeout => $args{timeout},
		channel => $args{channel},
	);

	if( ref $nextframe eq 'Net::AMQP::Frame::Method' ) {
		my $method_frame = $nextframe->method_frame;

		if( ref $method_frame eq 'Net::AMQP::Protocol::Basic::Deliver' ) {
			return {
				$self->_receive_delivery(
					channel => $nextframe->channel,
				),
				delivery_frame => $nextframe,
			};
		}
	}

	return $nextframe;
}

sub disconnect {
	my($self, $args ) = @_;

	$self->rpc_request(
		channel => 0,
		output => [
			Net::AMQP::Protocol::Connection::Close->new(
			),
		],
		resposnse_type => 'Net::AMQP::Protocol::Connection::CloseOk',
	);

	if( ! $self->_get_handle->close() ) {
		$self->_clear_handle;
		Carp::croak "Could not close socket: $OS_ERROR";
	}

	return;
}

sub _send {
	my ( $self, %args ) = @_;
	my $channel = $args{channel};
	my $output = $args{output};

	my $write;
	if( ref $output ) {
		if ( $output->isa('Net::AMQP::Protocol::Base') ) {
			$output = $output->frame_wrap;
		}

		if( ! defined $output->channel ) {
			$output->channel( $channel )
		}

		$write = $output->to_raw_frame();
	}
	else {
		$write = $output;
	}

	$self->_get_handle->syswrite( $write ) or
		Carp::croak "Could not write to socket: $OS_ERROR";

	return;
}

sub channel_open {
	my ( $self, %args ) = @_;

	my $channel = $args{channel};

	return $self->rpc_request(
		channel => $channel,
		output => [
			Net::AMQP::Protocol::Channel::Open->new(
			),
		],
		response_type => 'Net::AMQP::Protocol::Channel::OpenOk',
	);
}

sub exchange_declare {
	my ( $self, %args ) = @_;

	my $channel = $args{channel};

	return $self->rpc_request(
		channel => $channel,
		output => [
			Net::AMQP::Protocol::Exchange::Declare->new(
				exchange => $args{exchange},
				type => $args{exchange_type},
				passive => $args{passive},
				durable => $args{durable},
				auto_delete => $args{auto_delete},
				internal => $args{internal},
				arguments => {
					$self->_default( 'alternate_exchange', $args{alternate_exchange} ),
				},
			),
		],
		response_type => 'Net::AMQP::Protocol::Exchange::DeclareOk',
	);
}

sub exchange_delete {
	my ( $self, %args ) = @_;

	my $channel = $args{channel};

	return $self->rpc_request(
		channel => $channel,
		output => [
			Net::AMQP::Protocol::Exchange::Delete->new(
				exchange => $args{exchange},
				if_unused => $args{if_unused},
			),
		],
		response_type => 'Net::AMQP::Protocol::Exchange::DeleteOk',
	);
}

sub queue_declare {
	my ( $self, %args ) = @_;

	my $channel = $args{channel};

	return $self->rpc_request(
		channel => $channel,
		output => [
			 Net::AMQP::Protocol::Queue::Declare->new(
				queue => $args{queue},
				passive => $args{passive},
				durable => $args{durable},
				exclusive => $args{exclusive},
				auto_delete => $args{auto_delete},
				arguments => {
					$self->_default( 'x-expires', $args{expires} ),
					$self->_default( 'x-message-ttl', $args{message_ttl} ),
				},
			),
		],
		response_type => 'Net::AMQP::Protocol::Queue::DeclareOk',
	);
}

sub queue_bind {
	my ( $self, %args ) = @_;

	my $channel = $args{channel};

	my %flags = (
		queue => $args{queue},
		exchange => $args{exchange},
		routing_key => $args{routing_key},
		arguments => {
			%{ $args{headers} || {} },
			$self->_default( 'x-match', $args{x_match} ),
		},
	);

	return $self->rpc_request(
		channel => $channel,
		output => [
			Net::AMQP::Protocol::Queue::Bind->new( %flags ),
		],
		response_type => 'Net::AMQP::Protocol::Queue::BindOk',
	);
}

sub queue_delete {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Queue::Delete->new(
				queue => $args{queue},
				if_empty => $args{if_empty},
				if_unused => $args{if_unused},
			),
		],
		response_type => 'Net::AMQP::Protocol::Queue::DeleteOk',
	);
}

sub queue_unbind {
	my ( $self, %args ) = @_;

	my $channel = $args{channel};

	my %flags = (
		queue => $args{queue},
		exchange => $args{exchange},
		routing_key => $args{routing_key},
		arguments => {
			%{ $args{headers} || {} },
			$self->_default( 'x-match', $args{x_match} ),
		},
	);

	return $self->rpc_request(
		channel => $channel,
		output => [
			Net::AMQP::Protocol::Queue::Unbind->new( %flags ),
		],
		response_type => 'Net::AMQP::Protocol::Queue::UnbindOk',
	);
}

sub queue_purge {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Queue::Purge->new(
				queue => $args{queue},
			),
		],
		response_type => 'Net::AMQP::Protocol::Queue::PurgeOk',
	);
}

sub basic_ack {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Basic::Ack->new(
				delivery_tag => $args{delivery_tag},
				multiple => $args{multiple},
			),
		],
	);
}

sub basic_cancel_callback {
	my ( $self, %args ) = @_;
	$self->{basic_cancel_callback} = $args{callback} if( $args{callback} );
	return $self->{basic_cancel_callback};
}

sub basic_cancel {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Basic::Cancel->new(
				queue => $args{queue},
				consumer_tag => $args{consumer_tag},
			),
		],
		response_type => 'Net::AMQP::Protocol::Basic::CancelOk',
	);
}

sub basic_get {
	my ( $self, %args ) = @_;

	my $channel = $args{channel};

	my $get = $self->rpc_request(
		channel => $channel,
		output => [
			Net::AMQP::Protocol::Basic::Get->new(
				queue => $args{queue},
				no_ack => $args{no_ack},
			),
		],
		response_type => [qw(
			Net::AMQP::Protocol::Basic::GetEmpty
			Net::AMQP::Protocol::Basic::GetOk
		)],
	);

	if( ref $get eq 'Net::AMQP::Protocol::Basic::GetEmpty' ) {
		return;
	}
	else {
        my $delivery_tag = $get->delivery_tag;
		return {
			$self->_receive_delivery(
				channel      => $channel,
                delivery_tag => $delivery_tag,
			),
		}
	}
}

sub basic_publish {
	my ( $self, %args ) = @_;

	my $channel = $args{channel};
	my $payload = $args{payload};

	return $self->rpc_request(
		channel => $channel,
		output => [
			Net::AMQP::Protocol::Basic::Publish->new(
				exchange => $args{exchange},
				routing_key => $args{routing_key},
				mandatory => $args{mandatory},
				immediate => $args{immediate},
			),
			Net::AMQP::Frame::Header->new(
				body_size => length( $payload ),
				channel => $channel,
				header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(
					map { $args{props}{$_} ? ( $_ => $args{props}{$_} ) : () } qw(
						content_type
						content_encoding
						headers
						delivery_mode
						priority
						correlation_id
						reply_to
						expiration
						message_id
						timestamp
						type
						user_id
						app_id
						cluster_id
					),
				),
			),
			Net::AMQP::Frame::Body->new(
				payload => $payload,
			),
		],
	);
}

sub basic_consume {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Basic::Consume->new(
				queue => $args{queue},
				consumer_tag => $args{consumer_tag},
				exclusive => $args{exclusive},
				no_ack => $args{no_ack},
			),
		],
		response_type => 'Net::AMQP::Protocol::Basic::ConsumeOk',
	);
}

sub basic_reject {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Basic::Reject->new(
				delivery_tag => $args{delivery_tag},
				requeue => $args{requeue},
			),
		],
	);
}

sub basic_qos {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Basic::Qos->new(
				global => $args{global},
				prefetch_count => $args{prefetch_count},
				prefect_size => $args{prefetch_size},
			),
		],
		response_type => 'Net::AMQP::Protocol::Basic::QosOk',
	);
}

sub transaction_select {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Tx::Select->new(
			),
		],
		response_type => 'Net::AMQP::Protocol::Tx::SelectOk',
	);
}

sub transaction_commit {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Tx::Commit->new(
			),
		],
		response_type => 'Net::AMQP::Protocol::Tx::CommitOk',
	);
}

sub transaction_rollback {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Tx::Rollback->new(
			),
		],
		response_type => 'Net::AMQP::Protocol::Tx::RollbackOk',
	);
}

sub confirm_select {
	my ( $self, %args ) = @_;

	return $self->rpc_request(
		channel => $args{channel},
		output => [
			Net::AMQP::Protocol::Confirm::Select->new(
			),
		],
		response_type => 'Net::AMQP::Protocol::Confirm::SelectOk',
	);
}

sub heartbeat {
	my ( $self, %args ) = @_;
	return $self->_send(
		channel => 0,
		output => Net::AMQP::Frame::Heartbeat->new(
		),
	);
}

1;

__END__

=head1 NAME

Net::AMQP::RabbitMQ::PP - Pure perl AMQP client for RabbitMQ

=for html
<a href='https://travis-ci.org/Humanstate/net-amqp-rabbitmq?branch=master'><img src='https://travis-ci.org/Humanstate/net-amqp-rabbitmq.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/Humanstate/net-amqp-rabbitmq?branch=master'><img src='https://coveralls.io/repos/Humanstate/net-amqp-rabbitmq/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Net::AMQP::RabbitMQ::PP;

    my $connection = Net::AMQP::RabbitMQ::PP->new();
    $connection->connect;
    $connection->basic_publish(
        payload => "Foo",
        routing_key => "foo.bar",
    );
    $connection->disconnect

=head1 DESCRIPTION

Like L<Net::RabbitMQ> but pure perl rather than a wrapper around librabbitmq.

=head1 VERSION

0.09

=head1 SUBROUTINES/METHODS

A list of methods with their default arguments (undef = no default)

=head2 new

Loads the AMQP protocol definition, primarily. Will not be an active
connection until ->connect is called.

	my $mq = Net::AMQP::RabbitMQ::PP->new;

=head2 connect

Connect to the server. Default arguments are shown below:

	$mq->connect(
		host           => "localhost",
		port           => 5672,
		timeout        => undef,
		username       => 'guest',
		password       => 'guest',
		virtualhost    => '/',
		heartbeat      => undef,
		socket_timeout => 5,
	);

connect can also take a secure flag for SSL connections, this will only work if
L<IO::Socket::SSL> is available. You can also pass SSL specific arguments through
in the connect method and these will be passed through

	$mq->connect(
		...
		secure => 1,
		SSL_blah_blah => 1,
	);

=head2 disconnect

Disconnects from the server

	$mq->disconnect;

=head2 set_keepalive

Set a keep alive poller. Note: requires L<Socket::Linux>

	$mq->set_keepalive(
		idle     => $secs, # time between last meaningful packet and first keep alive
		count    => $n,    # number of failures to allow,
		interval => $secs, # time between keep alives
	);

=head2 receive

Receive the nextframe

	my $rv = $mq->receive;

Content or $rv will look something like:

	{
		payload              => $str,
		content_header_frame => Net::AMQP::Frame::Header,
		delivery_frame       => Net::AMQP::Frame::Method,
	}

=head2 channel_open

Open the given channel:

	$mq->channel_open( channel => undef );

=head2 exchange_declare

Instantiate an exchange with a previously opened channel:

	$mq->exchange_declare(
		channel            => undef,
		exchange           => undef,
		exchange_type      => undef,
		passive            => undef,
		durable            => undef,
		auto_delete        => undef,
		internal           => undef,
		alternate_exchange => undef,
	);

=head2 exchange_delete

Delete a previously instantiated exchange

	$mq->exchange_delete(
		channel   => undef,
		exchange  => undef,
		if_unused => undef,
	);

=head2 queue_declare

	$mq->exchange_declare(
		channel     => undef,
		queue       => undef,
		exclusive   => undef,
		passive     => undef,
		durable     => undef,
		auto_delete => undef,
		expires     => undef,
		message_ttl => undef,
	);

=head2 queue_bind

	$mq->queue_bind(
		channel     => undef,
		queue       => undef,
		exchange    => undef,
		routing_key => undef,
		headers     => {},
		x_match     => undef,
	);

=head2 queue_delete

	$mq->queue_delete(
		channel   => undef,
		queue     => undef,
		if_empty  => undef,
		if_unused => undef,
	);

=head2 queue_unbind

	$mq->queue_bind(
		channel     => undef,
		queue       => undef,
		exchange    => undef,
		routing_key => undef,
		headers     => {},
		x_match     => undef,
	);

=head2 queue_purge

	$mq->queue_purge(
		channel => undef,
		queue   => undef,
	);

=head2 basic_ack

	$mq->basic_ack(
		channel      => undef,
		delivery_tag => undef,
		multiple     => undef,
	);

=head2 basic_cancel_callback

	$mq->basic_cancel_callback(
		callback => undef,
	);

=head2 basic_cancel

	$mq->basic_cancel(
		channel      => undef,
		queue        => undef,
		consumer_tag => undef,
	);

=head2 basic_get

	$mq->basic_get(
		channel => undef,
		queue   => undef,
		no_ack  => undef,
	);

=head2 basic_publish

	$mq->basic_publish(
		channel     => undef,
		payload     => undef,
		exchange    => undef,
		routing_key => undef,
		mandatory   => undef,
		immediate   => undef,
		props       => {
			content_type     => undef,
			content_encoding => undef,
			headers          => undef,
			delivery_mode    => undef,
			priority         => undef,
			correlation_id   => undef,
			reply_to         => undef,
			expiration       => undef,
			message_id       => undef,
			timestamp        => undef,
			type             => undef,
			user_id          => undef,
			app_id           => undef,
			cluster_id       => undef,
		},
	);

=head2 basic_consume

	$mq->basic_consume(
		channel      => undef,
		queue        => undef,
		consumer_tag => undef,
		exclusive    => undef,
		no_ack       => undef,
	);

=head2 basic_reject

	$mq->basic_reject(
		channel      => undef,
		delivery_tag => undef,
		requeue      => undef,
	);

=head2 basic_qos

	$mq->basic_qos(
		channel        => undef,
		global         => undef,
		prefetch_count => undef,
		prefetch_size  => undef,
	);

=head2 transaction_select

=head2 transaction_commit

=head2 transaction_rollback

=head2 confirm_select

All take channel => $channel as args.

=head2 heartbeat

TODO

=head1 BUGS, LIMITATIONS, AND CAVEATS

Please report all bugs to the issue tracker on github.
https://github.com/Humanstate/net-amqp-rabbitmq/issues

One known limitation is that we cannot automatically send heartbeat frames in
a useful way.

A caveat is that I (LEEJO) didn't write this, I just volunteered to take
over maintenance and upload to CPAN since it is used in our stack. So I
apologize for the poor documentation. Have a look at the tests if any of the
documentation is not clear.

Another caveat is that the tests require MQHOST=a.rabbitmq.host to be of any
use, they used to default to dev.rabbitmq.com but that is currently MIA. If
MQHOST is not set they will be skipped.

=head1 SUPPORT

Use the issue tracker on github to reach out for support.
https://github.com/Humanstate/net-amqp-rabbitmq/issues

=head1 AUTHOR

Originally:

	Eugene Marcotte
	athenahealth
	emarcotte@athenahealth.com
	http://athenahealth.com

Current maintainer:

	leejo@cpan.org

Contributors:

	Ben Kaufman
	Jonathan Briggs
	Piotr Malek

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Eugene Marcotte

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Net::RabbitMQ>

L<Net::AMQP>

=cut
