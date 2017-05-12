package Protocol::PostgreSQL;
# ABSTRACT: PostgreSQL wire protocol
use strict;
use warnings;
use parent qw(Mixin::Event::Dispatch);

our $VERSION = '0.008';

=head1 NAME

Protocol::PostgreSQL - support for the PostgreSQL wire protocol

=head1 VERSION

version 0.008

=head1 SYNOPSIS

 use strict; use warnings;
 package PostgreSQL::Client;
 use parent q{Protocol::PostgreSQL::Client};

 sub new { my $self = shift->SUPER::new(@_); $self->{socket} = $self->connect(...); $self }
 sub on_send_request { shift->socket->send(@_) }
 sub socket { shift->{socket} }

 sub connect { ... } # provide a method to connect to the server
 sub incoming { shift->socket->read(@_) } # provide a method which passes on data from server

 package main;
 my $client = PostgreSQL::Client->new(user => ..., server => ..., database => ...);
 $client->simple_query(sql => q{select * from table}, on_data_row => sub {
 	my ($client, %args) = @_;
	my @cols = $args{row};
	print join(',', @cols) . "\n";
 });

=head1 DESCRIPTION

Provides protocol-level support for PostgreSQL 7.4+, as defined in L<http://www.postgresql.org/docs/current/static/protocol.html>.

=head2 CALLBACKS

The following callbacks can be provided either as parameters to L</new> or as methods in subclasses:

=over 4

=item * on_send_request - Called each time there is a new message to be sent to the other side of the connection.

=item * on_authenticated - Called when authentication is complete

=item * on_copy_data - we have received data from an ongoing COPY request

=item * on_copy_complete - the active COPY request has completed

=back

For the client, the following additional callbacks are available:

=over 4

=item * on_request_ready - the server is ready for the next request

=item * on_bind_complete - a Bind request has completed

=item * on_close_complete - the Close request has completed

=item * on_command_complete - the requested command has finished, this will typically be followed by an on_request_ready event

=item * on_copy_in_response - indicates that the server is ready to receive COPY data

=item * on_copy_out_response - indicates that the server is ready to send COPY data

=item * on_copy_both_response - indicates that the server is ready to exchange COPY data (for replication)

=item * on_data_row - data from the current query

=item * on_empty_query - special-case response when sent an empty query, can be used for 'ping'. Typically followed by on_request_ready

=item * on_error - server has raised an error

=item * on_function_call_result - results from a function call

=item * on_no_data - indicate that a query returned no data, typically followed by on_request_ready

=item * on_notice - server has sent us a notice

=item * on_notification - server has sent us a NOTIFY

=item * on_parameter_description - parameters are being described

=item * on_parameter_status - parameter status...

=item * on_parse_complete - parsing is done

=item * on_portal_suspended - the portal has been suspended, probably hit the row limit

=item * on_ready_for_query - we're ready for queries

=item * on_row_description - descriptive information about the rows we're likely to be seeing shortly

=back

And the server can send these events:

=over 4

=item * on_copy_fail - the frontend is indicating that the copy has failed

=item * on_describe - request for something to be described

=item * on_execute - request execution of a given portal

=item * on_flush - request flush

=item * on_function_call - request execution of a given function

=item * on_parse - request to parse something

=item * on_password - password information

=item * on_query - simple query request

=item * on_ssl_request - we have an SSL request

=item * on_startup_message - we have an SSL request

=item * on_sync - sync request

=item * on_terminate - termination request

=back

=cut

use Digest::MD5 ();
use Time::HiRes ();
use POSIX qw{strftime};
use Protocol::PostgreSQL::RowDescription;
use Protocol::PostgreSQL::Statement;

# Currently v3.0, which is used in PostgreSQL 7.4+
use constant PROTOCOL_VERSION	=> 0x00030000;

# Currently-allowed list of callbacks (can be set via ->configure)
our @CALLBACKS_ALLOWED = qw(
	on_send_request
	on_authenticated
	on_copy_data
	on_copy_complete
	on_request_ready
	on_bind_complete
	on_close_complete
	on_command_complete
	on_copy_in_response
	on_copy_out_response
	on_copy_both_response
	on_data_row
	on_empty_query
	on_error
	on_function_call_result
	on_no_data
	on_notice
	on_notification
	on_parameter_description
	on_parameter_status
	on_parse_complete
	on_portal_suspended
	on_ready_for_query
	on_row_description
	on_copy_fail
	on_describe
	on_execute
	on_flush
	on_function_call
	on_parse
	on_password
	on_query
	on_ssl_request
	on_startup_message
	on_sync
	on_terminate
);
# Hash form for convenience
my %CALLBACK_MAP = map { $_ => 1 } @CALLBACKS_ALLOWED;

# Types of authentication response
my %AUTH_TYPE = (
	0	=> 'AuthenticationOk',
	2	=> 'AuthenticationKerberosV5',
	3	=> 'AuthenticationCleartextPassword',
	5	=> 'AuthenticationMD5Password',
	6	=> 'AuthenticationSCMCredential',
	7	=> 'AuthenticationGSS',
	9	=> 'AuthenticationSSPI',
	8	=> 'AuthenticationGSSContinue',
);

# Transaction states the backend can be in
my %BACKEND_STATE = (
	I	=> 'idle',
	T	=> 'transaction',
	E	=> 'error'
);

# used for error and notice responses
my %NOTICE_CODE = (
	S	=> 'severity',
	C	=> 'code',
	M	=> 'message',
	D	=> 'detail',
	H	=> 'hint',
	P	=> 'position',
	p	=> 'internal_position',
	q	=> 'internal_query',
	W	=> 'where',
	F	=> 'file',
	L	=> 'line',
	R	=> 'routine'
);

# Mapping from name to backend message code (single byte)
our %MESSAGE_TYPE_BACKEND = (
	AuthenticationRequest	=> 'R',
	BackendKeyData		=> 'K',
	BindComplete		=> '2',
	CloseComplete		=> '3',
	CommandComplete		=> 'C',
	CopyData		=> 'd',
	CopyDone		=> 'c',
	CopyInResponse		=> 'G',
	CopyOutResponse		=> 'H',
	CopyBothResponse	=> 'W',
	DataRow			=> 'D',
	EmptyQueryResponse	=> 'I',
	ErrorResponse		=> 'E',
	FunctionCallResponse	=> 'V',
	NoData			=> 'n',
	NoticeResponse		=> 'N',
	NotificationResponse	=> 'A',
	ParameterDescription	=> 't',
	ParameterStatus		=> 'S',
	ParseComplete		=> '1',
	PortalSuspended		=> 's',
	ReadyForQuery		=> 'Z',
	RowDescription		=> 'T',
);
our %BACKEND_MESSAGE_CODE = reverse %MESSAGE_TYPE_BACKEND;

# Mapping from name to frontend message code (single byte)
our %MESSAGE_TYPE_FRONTEND = (
	Bind			=> 'B',
	Close			=> 'C',
	CopyData		=> 'd',
	CopyDone		=> 'c',
	CopyFail		=> 'f',
	Describe		=> 'D',
	Execute			=> 'E',
	Flush			=> 'H',
	FunctionCall		=> 'F',
	Parse			=> 'P',
	PasswordMessage		=> 'p',
	Query			=> 'Q',
# Both of these are handled separately
#	SSLRequest		=> '',
#	StartupMessage		=> '',
	Sync			=> 'S',
	Terminate		=> 'X',
);
our %FRONTEND_MESSAGE_CODE = reverse %MESSAGE_TYPE_FRONTEND;

# Defined message handlers for outgoing frontend messages
our %FRONTEND_MESSAGE_BUILDER = (
# Bind parameters to an existing prepared statement
	Bind => sub {
		my $self = shift;
		my %args = @_;

		$args{param} ||= [];
		my $param = '';
		my $count = scalar @{$args{param}};
		foreach my $p (@{$args{param}}) {
			if(!defined $p) {
				$param .= pack('N1', 0xFFFFFFFF);
			} else {
				$param .= pack('N1a*', length($p), $p);
			}
		}
		my $msg = pack('Z*Z*n1n1a*n1',
			defined($args{portal}) ? $args{portal} : '',
			defined($args{statement}) ? $args{statement} : '',
			0,		# Parameter types
			$count,		# Number of bound parameters
			$param,		# Actual parameter values
			0		# Number of result column format definitions (0=use default text format)
		);
		push @{$self->{pending_bind}}, $args{sth} if $args{sth};
		$self->debug(sub {
			join('',
				"Bind",
				defined($args{portal}) ? " for portal [" . $args{portal} . "]" : '',
				defined($args{statement}) ? " for statement [" . $args{statement} . "]" : '',
				" with $count parameter(s): ",
				join(',', @{$args{param}})
			)
		});
		return $self->_build_message(
			type	=> 'Bind',
			data	=> $msg,
		);
	},
	CopyData => sub {
		my $self = shift;
		my %args = @_;
		return $self->_build_message(
			type	=> 'CopyData',
			data	=> pack('a*', $args{data})
		);
	},
	Close => sub {
		my $self = shift;
		my %args = @_;

		my $msg = pack('a1Z*',
			exists $args{portal} ? 'P' : 'S', # close a portal or a statement
			  defined($args{statement})
			? $args{statement}
			:  (defined($args{portal})
			  ? $args{portal}
			  : ''
			)
		);
		push @{$self->{pending_close}}, $args{on_complete} if $args{on_complete};
		return $self->_build_message(
			type	=> 'Close',
			data	=> $msg,
		);
	},
	CopyDone => sub {
		my $self = shift;
		return $self->_build_message(
			type	=> 'CopyDone',
			data	=> '',
		);
	},
# Describe expected SQL results
	Describe => sub {
		my $self = shift;
		my %args = @_;

		my $msg = pack('a1Z*', exists $args{portal} ? 'P' : 'S', defined($args{statement}) ? $args{statement} : (defined($args{portal}) ? $args{portal} : ''));
		push @{$self->{pending_describe}}, $args{sth} if $args{sth};
		return $self->_build_message(
			type	=> 'Describe',
			data	=> $msg,
		) . $self->_build_message(
			type	=> 'Query',
			data	=> "\0"
		);
	},
# Execute either a named or anonymous portal (prepared statement with bind vars)
	Execute => sub {
		my $self = shift;
		my %args = @_;

		my $msg = pack('Z*N1', defined($args{portal}) ? $args{portal} : '', $args{limit} || 0);
		push @{$self->{pending_execute}}, $args{sth} if $args{sth};
		$self->debug("Executing " . (defined($args{portal}) ? "portal " . $args{portal} : "default portal") . ($args{limit} ? " with limit " . $args{limit} : " with no limit"));
		return $self->_build_message(
			type	=> 'Execute',
			data	=> $msg,
		);
	},
# Parse SQL for a prepared statement
	Parse => sub {
		my $self = shift;
		my %args = @_;
		die "No SQL provided" unless defined $args{sql};

		my $msg = pack('Z*Z*n1', (defined($args{statement}) ? $args{statement} : ''), $args{sql}, 0);
		return $self->_build_message(
			type	=> 'Parse',
			data	=> $msg,
		);
	},
# Password data, possibly encrypted depending on what the server specified
	PasswordMessage => sub {
		my $self = shift;
		my %args = @_;

		my $pass = $args{password};
		if($self->{password_type} eq 'md5') {
			# md5hex of password . username,
			# then md5hex result with salt appended
			# then stick 'md5' at the front.
			$pass = 'md5' . Digest::MD5::md5_hex(
				Digest::MD5::md5_hex($pass . $self->{user})
				. $self->{password_salt}
			);
		}

		# Yes, protocol requires zero-terminated string format even
		# if we have a binary password value.
		return $self->_build_message(
			type	=> 'PasswordMessage',
			data	=> pack('Z*', $pass)
		);
	},
# Simple query
	Query => sub {
		my $self = shift;
		my %args = @_;
		return $self->_build_message(
			type	=> 'Query',
			data	=> pack('Z*', $args{sql})
		);
	},
# Initial mesage informing the server which database and user we want
	StartupMessage	=> sub {
		my $self = shift;
		die "Not first message" unless $self->is_first_message;

		my %args = @_;
		my $parameters = join('', map { pack('Z*', $_) } map { $_, $args{$_} } grep { exists $args{$_} } qw(user database options));
		$parameters .= "\0";

		return $self->_build_message(
			type	=> undef,
			data	=> pack('N*', PROTOCOL_VERSION) . $parameters
		);
	},
# Synchonise after a prepared statement has finished execution.
	Sync => sub {
		my $self = shift;
		return $self->_build_message(
			type	=> 'Sync',
			data	=> '',
		);
	},
	Terminate => sub {
		my $self = shift;
		return $self->_build_message(
			type	=> 'Terminate',
			data	=> '',
		);
	},
);

# Handlers for specification authentication messages from backend.
my %AUTH_HANDLER = (
	AuthenticationOk => sub {
		my ($self, $msg) = @_;
		$self->invoke_event('authenticated');
		$self->invoke_event('request_ready');
		return $self;
	},
	AuthenticationKerberosV5 => sub {
		my ($self, $msg) = @_;
		die "Not yet implemented";
	},
	AuthenticationCleartextPassword => sub {
		my ($self, $msg) = @_;
		$self->{password_type} = 'plain';
		$self->invoke_event('password');
		return $self;
	},
	AuthenticationMD5Password => sub {
		my ($self, $msg) = @_;
		(undef, undef, undef, my $salt) = unpack('C1N1N1a4', $msg);
		$self->{password_type} = 'md5';
		$self->{password_salt} = $salt;
		$self->invoke_event('password');
		return $self;
	},
	AuthenticationSCMCredential => sub {
		my ($self, $msg) = @_;
		die "Not yet implemented";
		return $self;
	},
	AuthenticationGSS => sub {
		my ($self, $msg) = @_;
		die "Not yet implemented";
	},
	AuthenticationSSPI => sub {
		my ($self, $msg) = @_;
		die "Not yet implemented";
	},
	AuthenticationGSSContinue => sub {
		my ($self, $msg) = @_;
		die "Not yet implemented";
	}
);

# Defined message handlers for incoming messages from backend
our %BACKEND_MESSAGE_HANDLER = (
# We had some form of authentication request or response, pass it over to an auth handler to deal with it further.
	AuthenticationRequest	=> sub {
		my $self = shift;
		my $msg = shift;

		my (undef, undef, $auth_code) = unpack('C1N1N1', $msg);
		my $auth_type = $AUTH_TYPE{$auth_code} or die "Invalid auth code $auth_code received";
		$self->debug("Auth message [$auth_type]");
		return $AUTH_HANDLER{$auth_type}->($self, $msg);
	},
# Key data for cancellation requests
	BackendKeyData	=> sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size, my $pid, my $key) = unpack('C1N1N1N1', $msg);
		$self->invoke_event('backendkeydata',
			pid	=> $pid,
			key	=> $key
		);
		return $self;
	},
# A bind operation has completed
	BindComplete	=> sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size) = unpack('C1N1', $msg);
		if(my $sth = shift(@{$self->{pending_bind}})) {
			$self->debug("Pass over to statement $sth");
			$sth->bind_complete;
		}
		$self->invoke_event('bind_complete');
		return $self;
	},
# We have closed the connection to the server successfully
	CloseComplete	=> sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size) = unpack('C1N1', $msg);

		# Handler could be undef - we always push something to keep things symmetrical
		if(my $handler = shift @{$self->{pending_close}}) {
			$handler->($self);
		}
		$self->invoke_event('close_complete');
		return $self;
	},
# A command has completed, we should see a ready response immediately after this
	CommandComplete => sub {
		my $self = shift;
		my $msg = shift;
		my (undef, undef, $result) = unpack('C1N1Z*', $msg);
		if(@{$self->{pending_execute}}) {
			my $last = shift @{$self->{pending_execute}};
			$self->debug("Finished command for $last");
			$last->command_complete if $last;
		}
		$self->invoke_event('command_complete', result => $result);
		return $self;
	},
# We have a COPY response from the server indicating that it's ready to accept COPY data
	CopyInResponse => sub {
		my $self = shift;
		my $msg = shift;
		(undef, undef, my $type, my $count) = unpack('C1N1C1n1', $msg);
		substr $msg, 0, 8, '';
		my @formats;
		for (1..$count) {
			push @formats, unpack('n1', $msg);
			substr $msg, 0, 2, '';
		}
		$self->invoke_event('copy_in_response', count => $count, columns => \@formats);
		return $self;
	},
# The basic SQL result - a single row of data
	DataRow => sub {
		my $self = shift;
		my $msg = shift;
		my (undef, undef, $count) = unpack('C1N1n1', $msg);
		substr $msg, 0, 7, '';
		my @fields;
		# TODO Tidy this up
		my $sth = @{$self->{pending_execute}} ? $self->{pending_execute}[0] : $self->active_statement;
		my $desc = $sth ? $sth->row_description : $self->row_description;
		foreach my $idx (0..$count-1) {
			my $field = $desc->field_index($idx);
			my ($size) = unpack('N1', $msg);
			substr $msg, 0, 4, '';
			my $data;
			my $null = ($size == 0xFFFFFFFF);
			unless($null) {
				$data = $field->parse_data($msg, $size);
				substr $msg, 0, $size, '';
			}
			push @fields, {
				null		=> $null,
				description	=> $field,
				data		=> $null ? undef : $data,
			}
		}
		$sth->data_row(\@fields) if $sth;
		$self->invoke_event('data_row', row => \@fields);
		return $self;
	},
# Response given when empty query (whitespace only) is provided
	EmptyQueryResponse => sub {
		my $self = shift;
		my $msg = shift;
		if(@{$self->{pending_execute}}) {
			my $last = shift @{$self->{pending_execute}};
			$self->debug("Finished command for $last");
		}
		$self->invoke_event('empty_query');
		return $self;
	},
# An error occurred, can indicate that connection is about to close or just be a warning
	ErrorResponse => sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size) = unpack('C1N1', $msg);
		substr $msg, 0, 5, '';
		my %notice;
		FIELD:
		while(length($msg)) {
			my ($code, $str) = unpack('A1Z*', $msg);
			last FIELD unless $code && $code ne "\0";

			die "Unknown NOTICE code [$code]" unless exists $NOTICE_CODE{$code};
			$notice{$NOTICE_CODE{$code}} = $str;
			substr $msg, 0, 2+length($str), '';
		}
		if(@{$self->{pending_execute}}) {
			my $last = shift @{$self->{pending_execute}};
			$self->debug("Error for $last");
		}
		$self->invoke_event('error', error => \%notice);
		return $self;
	},
# Result from calling a function
	FunctionCallResponse	=> sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size, my $len) = unpack('C1N1N1', $msg);
		substr $msg, 0, 9, '';
		my $data = ($len == 0xFFFFFFFF) ? undef : substr $msg, 0, $len;
		$self->invoke_event('function_call_response', data => $data);
		return $self;
	},
# No data follows
	NoData	=> sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size) = unpack('C1N1', $msg);
		$self->invoke_event('no_data');
		return $self;
	},
# We have a notice, which is like an error but can be just informational
	NoticeResponse => sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size) = unpack('C1N1', $msg);
		substr $msg, 0, 5, '';
		my %notice;
		FIELD:
		while(length($msg)) {
			my ($code, $str) = unpack('A1Z*', $msg);
			last FIELD unless $code && $code ne "\0";

			die "Unknown NOTICE code [$code]" unless exists $NOTICE_CODE{$code};
			$notice{$NOTICE_CODE{$code}} = $str;
			substr $msg, 0, 2+length($str), '';
		}
		$self->invoke_event('notice', notice => \%notice);
		return $self;
	},
# LISTEN/NOTIFY mechanism
	NotificationReponse => sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size, my $pid, my $channel, my $data) = unpack('C1N1N1Z*Z*', $msg);
		$self->invoke_event('notification', pid => $pid, channel => $channel, data => $data);
		return $self;
	},
# Connection parameter information
	ParameterStatus	=> sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size) = unpack('C1N1', $msg);
		substr $msg, 0, 5, '';
		my %status;
		# Series of key,value pairs
		PARAMETER:
		while(1) {
			my ($k, $v) = unpack('Z*Z*', $msg);
			last PARAMETER unless defined($k) && length($k);
			$status{$k} = $v;
			substr $msg, 0, length($k) + length($v) + 2, '';
		}
		$self->invoke_event('parameter_status', status => \%status);
		return $self;
	},
# Description of the format that subsequent parameters are using, typically plaintext only
	ParameterDescription => sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size, my $count) = unpack('C1N1n1', $msg);
		substr $msg, 0, 7, '';
		my @oid_list;
		for my $idx (1..$count) {
			my ($oid) = unpack('N1', $msg);
			substr $msg, 0, 4, '';
			push @oid_list, $oid;
		}
		$self->invoke_event('parameter_description', parameters => \@oid_list);
		return $self;
	},
# Parse request succeeded
	ParseComplete	=> sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size) = unpack('C1N1', $msg);
		$self->active_statement->parse_complete if $self->active_statement;
		$self->invoke_event('parse_complete');
		return $self;
	},
# Portal has sent enough data to meet the row limit, should be requested again if more is required
	PortalSuspended	=> sub {
		my $self = shift;
		my $msg = shift;
		(undef, my $size) = unpack('C1N1', $msg);
		if(@{$self->{pending_execute}}) {
			my $last = shift @{$self->{pending_execute}};
			$self->debug("Suspended portal for $last");
		}
		$self->invoke_event('portal_suspended');
		return $self;
	},
# All ready to accept queries
	ReadyForQuery	=> sub {
		my $self = shift;
		my $msg = shift;
		my (undef, undef, $state) = unpack('C1N1A1', $msg);
		$self->debug("Backend state is $state");
		$self->backend_state($BACKEND_STATE{$state});
		$self->is_ready(1);
		return $self->send_next_in_queue if $self->has_queued;
		$self->invoke_event('ready_for_query');
		return $self;
	},
# Information on the row data that's expected to follow
	RowDescription => sub {
		my $self = shift;
		my $msg = shift;
		my (undef, undef, $count) = unpack('C1N1n1', $msg);
		my $row = Protocol::PostgreSQL::RowDescription->new;
		substr $msg, 0, 7, '';
		foreach my $id (0..$count-1) {
			my ($name, $table_id, $field_id, $data_type, $data_size, $type_modifier, $format_code) = unpack('Z*N1n1N1n1N1n1', $msg);
			my %data = (
				name		=> $name,
				table_id	=> $table_id,
				field_id	=> $field_id,
				data_type	=> $data_type,
				data_size	=> $data_size,
				type_modifier	=> $type_modifier,
				format_code	=> $format_code
			);
			$self->debug($_ . ' => ' . $data{$_}) for sort keys %data;
			my $field = Protocol::PostgreSQL::FieldDescription->new(%data);
			$row->add_field($field);
			substr $msg, 0, 19 + length($name), '';
		}
		$self->row_description($row);
		if(my $last = shift @{$self->{pending_describe}}) {
			$last->row_description($row);
		}
		$self->invoke_event('row_description', description => $row);
		return $self;
	},
);

=head1 METHODS

=cut

=head2 new

Instantiate a new object. Blesses an empty hashref and calls L</configure>, subclasses can bypass this entirely
and just call L</configure> directly after instantiation.

=cut

sub new {
	my $self = bless {
	}, shift;
	$self->configure(@_);
	return $self;
}

=head2 configure

Does the real preparation for the object.

Takes callbacks as named parameters, including:

=over 4

=item * on_error

=item * on_data_row

=item * on_ready_for_query

=back

=cut

sub configure {
	my $self = shift;
	my %args = @_;

# Init parameters - should only be needed on first call
	$self->{$_} = [] for grep !exists $self->{$_}, qw(pending_execute pending_describe message_queue);
	$self->{$_} = 0 for grep !exists $self->{$_}, qw(authenticated message_count);
	$self->{wait_for_startup} = 1 unless exists $self->{wait_for_startup};

	$self->{debug} = delete $args{debug} if exists $args{debug};

	$self->{user} = delete $args{user} if exists $args{user};
	$self->{pass} = delete $args{pass} if exists $args{pass};
	$self->{database} = delete $args{database} if exists $args{database};

# Callbacks
	foreach my $k (grep /on_(.+)$/, keys %args) {
		my ($event) = $k =~ /on_(.+)$/;
		die "Unknown callback '$k'" unless exists $CALLBACK_MAP{$k};
		$self->add_handler_for_event($event => delete $args{$k});
	}
	return %args;
}

=head2 has_queued

Returns number of queued messages.

=cut

sub has_queued { scalar(@{$_[0]->{message_queue}}) }

=head2 is_authenticated

Returns true if we are authenticated (and can start sending real data).

=cut

sub is_authenticated { shift->{authenticated} ? 1 : 0 }

=head2 is_first_message

Returns true if this is the first message, as per L<http://developer.postgresql.org/pgdocs/postgres/protocol-overview.html>:

 "For historical reasons, the very first message sent by the client (the startup message)
  has no initial message-type byte."

=cut

sub is_first_message { shift->{message_count} < 1 }

=head2 initial_request

Generate and send the startup request.

=cut

sub initial_request {
	my $self = shift;
	my %args = @_;
	my %param = map { $_ => exists $args{$_} ? delete $args{$_} : $self->{$_} } qw(database user);
	delete @param{grep { !defined($param{$_}) } keys %param};
	die "don't know how to handle " . join(',', keys %args) if keys %args;

	$self->send_message('StartupMessage', %param);
	$self->{wait_for_startup} = 0;
	return $self;
}

=head2 send_message

Send a message.

=cut

sub send_message {
	my $self = shift;

# Clear the ready-to-send flag since we're about to throw a message over to the
# server and we don't want any others getting in the way.
	$self->{is_ready} = 0;

	my $msg = $self->message(@_);
	die "Empty message?" unless defined $msg;

# Use the coderef form of the debug call since the packet breakdown is a slow operation.
	$self->debug(sub {
		"send data: [" .
		join(" ", map sprintf("%02x", ord($_)), split //, $msg) . "], " .
		(($self->is_first_message ? "startup packet" : $FRONTEND_MESSAGE_CODE{substr($msg, 0, 1)}) || 'unknown message') .  " (" . 
		join('', '', map { (my $txt = defined($_) ? $_ : '') =~ tr/ []"'!#$%*&=:;A-Za-z0-9,()_ -/./c; $txt } split //, $msg) . ")"
	});
	$self->invoke_event('send_request', $msg);
	return $self;
}

=head2 queue

Queue up a message for sending. The message will only be sent when we're in ReadyForQuery
mode, which could be immediately or later.

=cut

sub queue {
	my $self = shift;
	my %args = @_;

# Get raw message data to send, could be passed as a ready-built message packet or a set of parameters.
	my $msg = delete $args{message};
	unless($msg) {
		# Might get a message with no parameters
		$msg = $self->message(delete $args{type}, @{ delete $args{parameters} || [] });
	}

# Add this to the queue
	push @{$self->{message_queue}}, {
		message	=> $msg,
		%args
	};

# Send immediately if we're in a ready state
	$self->send_next_in_queue if $self->is_ready;
	return $self;
}

=head2 send_next_in_queue

Send the next queued message.

=cut

sub send_next_in_queue {
	my $self = shift;

# TODO Clean up the duplication between this method and L</send_message>.
	if(my $info = shift @{$self->{message_queue}}) {
		my $msg = delete $info->{message};

# Clear flag so we only send a single message rather than hammering the server with everything in the queue
		$self->{is_ready} = 0;
		$self->debug(sub {
			"send data: [" . join(" ", map sprintf("%02x", ord($_)), split //, $msg) . "], " . $FRONTEND_MESSAGE_CODE{substr($msg, 0, 1)} . " (" . join("", grep { /^([a-z0-9,()_ -])$/ } split //, $msg) . ")"
		});
		$self->invoke_event('send_request', $msg);

# Ping the callback to let it know message is now in flight
		$info->{callback}->($self, $info) if exists $info->{callback};
	}
	return $self;
}

=head2 message

Creates a new message of the given type.

=cut

sub message {
	my $self = shift;
	my $type = shift;
	die "Message $type unknown" unless exists $FRONTEND_MESSAGE_BUILDER{$type};

	my $msg = $FRONTEND_MESSAGE_BUILDER{$type}->($self, @_);
	++$self->{message_count};
	return $msg;
}

=head2 attach_event

Attach new handler(s) to the given event(s).

=cut

sub attach_event {
	my $self = shift;
	my %args = @_;
	$self->debug("Using old ->attach_event interface, suggest ->add_handler_for_event from Mixin::Event::Dispatch instead for %s", join(',', keys %args));
	$self->add_handler_for_event(
		map { $_ => sub { $args{$_}->(@_); 1 } } keys %args
	);
	for (keys %args) {
		my $k = "on_$_";
		die "Unknown callback '$_'" unless exists $CALLBACK_MAP{$k};
		$self->{_callback}->{$k} = $args{$_};
	}
	return $self;
}

=head2 detach_event

Detach handler(s) from the given event(s). Not implemented.

=cut

sub detach_event {
	my $self = shift;
	warn "detach_event not implemented, see ->add_handler_for_event in Mixin::Event::Dispatch";
	return $self;
}

=head2 debug

Helper method to report debug information. Can take a string or a coderef.

=cut

sub debug {
	my $self = shift;
	return unless $self->{debug};

	my $msg = shift(@_);
	$msg = $msg->() if ref $msg && ref $msg eq 'CODE';
	if(!ref $self->{debug}) {
		my $now = Time::HiRes::time;
		warn strftime("%Y-%m-%d %H:%M:%S", gmtime($now)) . sprintf(".%03d", int($now * 1000.0) % 1000.0) . " $msg\n";
		return;
	}
	if(ref $self->{debug} eq 'CODE') {
		$self->{debug}->($msg, @_);
		return;
	}
	die "Unknown debug setting " . $self->{debug};
}

=head2 handle_message

Handle an incoming message from the server.

=cut

sub handle_message {
	my $self = shift;
	my $msg = shift;
	$self->debug(sub {
		"recv data: [" . join(" ", map sprintf("%02x", ord($_)), split //, $msg) . "], " . $BACKEND_MESSAGE_CODE{substr($msg, 0, 1)}
	});

# Extract code and identify which message handler to use
	my $code = substr $msg, 0, 1;
	my $type = $BACKEND_MESSAGE_CODE{$code};
	$self->debug("Handle     [$type] message");
	die "No handler for $type" unless exists $BACKEND_MESSAGE_HANDLER{$type};

# Clear the ready-to-send flag until we've processed this
	$self->{is_ready} = 0;
	return $BACKEND_MESSAGE_HANDLER{$type}->($self, $msg);
}

=head2 message_length

Returns the length of the given message.

=cut

sub message_length {
	my $self = shift;
	my $msg = shift;
	return undef unless length($msg) >= 5;
	my ($code, $len) = unpack('C1N1', substr($msg, 0, 5));
	return $len;
}

=head2 simple_query

Send a simple query to the server - only supports plain queries (no bind parameters).

=cut

sub simple_query {
	my $self = shift;
	my $sql = shift;
	die "Invalid backend state" if $self->backend_state eq 'error';

	$self->debug("Running query [$sql]");
	$self->queue(
		message	=> $self->message('Query', sql => $sql)
	);
	return $self;
}

=head2 copy_data

Send copy data to the server.

=cut

sub copy_data {
	my $self = shift;
	my $data = shift;
	die "Invalid backend state" if $self->backend_state eq 'error';

	$self->send_message('CopyData', data => $data);
	return $self;
}

=head2 copy_done

Indicate that the COPY data from the client is complete.

=cut

sub copy_done {
	my $self = shift;
	my $data = shift;
	die "Invalid backend state" if $self->backend_state eq 'error';

	$self->send_message('CopyDone');
	return $self;
}

=head2 backend_state

Accessor for current backend state.

=cut

sub backend_state {
	my $self = shift;
	if(@_) {
		my $state = shift;
		die "bad state code" unless grep { $state eq $_ } qw(idle transaction error);

		$self->{backend_state} = $state;
		return $self;
	}
	return $self->{backend_state};
}

=head2 active_statement

Returns the currently active L<Protocol::PostgreSQL::Statement> if we have one.

=cut

sub active_statement {
	my $self = shift;
	if(@_) {
		$self->{active_statement} = shift;
		return $self;
	}
	return $self->{active_statement};
}

=head2 row_description

Accessor for row description.

=cut

sub row_description {
	my $self = shift;
	if(@_) {
		$self->{row_description} = shift;
		return $self;
	}
	return $self->{row_description};
}

=head2 prepare

Prepare a L<Protocol::PostgreSQL::Statement>. Intended to be mostly compatible with the L<DBI>
->prepare method.

=cut

sub prepare {
	my $self = shift;
	my $sql = shift;
	return $self->prepare_async(sql => $sql);
}

=head2 prepare_async

Set up a L<Protocol::PostgreSQL::Statement> allowing callbacks and other options to be provided.

=cut

sub prepare_async {
	my $self = shift;
	my %args = @_;
	die "SQL statement not provided" unless defined $args{sql};

	my $sth = Protocol::PostgreSQL::Statement->new(
		dbh	=> $self,
		%args,
	);
	return $sth;
}

=head2 is_ready

Returns true if we're ready to send more data to the server.

=cut

sub is_ready {
	my $self = shift;
	if(@_) {
		$self->{is_ready} = shift;
		return $self;
	}
	return 0 if $self->{wait_for_startup};
	return $self->{is_ready};
}

=head2 send_copy_data

Send COPY data to the server. Takes an arrayref and replaces any reserved characters with quoted versions.

=cut

sub send_copy_data  {
	my $self = shift;
	my $data = shift;
	my $content = pack 'a*', (join("\t", map {
		if(defined) {
			s/\\/\\\\/g if index($_, "\\") >= 0;
			s/\x08/\\b/g if index($_, "\x08") >= 0;
			s/\f/\\f/g if index($_, "\f") >= 0;
			s/\n/\\n/g if index($_, "\n") >= 0;
			s/\t/\\t/g if index($_, "\t") >= 0;
			s/\v/\\v/g if index($_, "\r") >= 0;
		} else {
			$_ = '\N';
		}
		$_;
	} @$data) . "\n");
	
	$self->invoke_event('send_request', $MESSAGE_TYPE_FRONTEND{'CopyData'} . pack('N1', 4 + length $content) . $content);
	return $self;
}

=head2 _build_message

Construct a new message.

=cut

sub _build_message {
	my $self = shift;
	my %args = @_;

# Can be undef
	die "No type provided" unless exists $args{type};
	die "No data provided" unless exists $args{data};

# Length includes the 4-byte length field, but not the type byte
	my $length = length($args{data}) + 4;
	my $msg = ($self->is_first_message ? '' : $MESSAGE_TYPE_FRONTEND{$args{type}}) . pack('N1', $length) . $args{data};
	return $msg;
}

1;

__END__

=head1 SEE ALSO

L<DBD::Pg>, which uses the official library and (unlike this module) provides full support for L<DBI>.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2011. Licensed under the same terms as Perl itself.
