package Mojo::SMTP::Client;

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use Mojo::IOLoop::Client;
use Mojo::IOLoop::Delay;
use Mojo::IOLoop::Stream;
use Mojo::Util 'b64_encode';
use Mojo::SMTP::Client::Response;
use Mojo::SMTP::Client::Exception;
use Scalar::Util 'weaken';
use Carp;

our $VERSION = '0.17';

use constant {
	CMD_OK       => 2,
	CMD_MORE     => 3,
	
	CMD_CONNECT  => 1,
	CMD_EHLO     => 2,
	CMD_HELO     => 3,
	CMD_STARTTLS => 10,
	CMD_AUTH     => 11,
	CMD_FROM     => 4,
	CMD_TO       => 5,
	CMD_DATA     => 6,
	CMD_DATA_END => 7,
	CMD_RESET    => 8,
	CMD_QUIT     => 9,
};

our %CMD = (
	&CMD_CONNECT  => 'CMD_CONNECT',
	&CMD_EHLO     => 'CMD_EHLO',
	&CMD_HELO     => 'CMD_HELO',
	&CMD_STARTTLS => 'CMD_STARTTLS',
	&CMD_AUTH     => 'CMD_AUTH',
	&CMD_FROM     => 'CMD_FROM',
	&CMD_TO       => 'CMD_TO',
	&CMD_DATA     => 'CMD_DATA',
	&CMD_DATA_END => 'CMD_DATA_END',
	&CMD_RESET    => 'CMD_RESET',
	&CMD_QUIT     => 'CMD_QUIT',
);

has address            => 'localhost';
has port               => sub { $_[0]->tls ? 465 : 25 };
has tls                => 0;
has 'tls_ca';
has 'tls_cert';
has 'tls_key';
has tls_verify         => 1;
has hello              => 'localhost.localdomain';
has connect_timeout    => sub { $ENV{MOJO_CONNECT_TIMEOUT} || 10 };
has inactivity_timeout => sub { $ENV{MOJO_INACTIVITY_TIMEOUT} // 20 };
has ioloop             => sub { Mojo::IOLoop->new };
has autodie            => 0;

sub new {
	my $class = shift;
	
	my $self = $class->SUPER::new(@_);
	weaken(my $this = $self);
	
	$self->{resp_checker} = sub {
		my ($delay, $resp) = @_;
		$this->emit(response => $this->{last_cmd}, $resp);
		
		unless (substr($resp->code, 0, 1) == $this->{expected_code}) {
			die $resp->error(Mojo::SMTP::Client::Exception::Response->new($resp->message)->code($resp->code));
		}
		$delay->pass($resp);
	};
	
	$self->{cmds} = [];
	
	$self;
}

sub send {
	my $self = shift;
	my $cb = @_ % 2 == 0 ? undef : pop;
	
	my @steps;
	$self->{nb} = $cb ? 1 : 0;
	
	# user changed SMTP server or server sent smth while it shouldn't
	if ($self->{stream} && (($self->{server} ne $self->_server) ||
	     ($self->{stream}->is_readable && !$self->{starttls} && !$self->{authorized} && 
	      grep {$self->{last_cmd} == $_} (CMD_CONNECT, CMD_DATA_END, CMD_RESET)))
	) {
		$self->_rm_stream();
	}
	
	unless ($self->{stream}) {
		push @steps, sub {
			my $delay = shift;
			# connect
			$self->{starttls} = $self->{authorized} = 0;
			$self->emit('start');
			$self->{server} = $self->_server;
			$self->{last_cmd} = CMD_CONNECT;
			
			my $connect_cb = $delay->begin;
			$self->{client} = Mojo::IOLoop::Client->new(reactor => $self->_ioloop->reactor);
			$self->{client}->on(connect => $connect_cb);
			$self->{client}->on(error => $connect_cb);
			$self->{client}->connect(
				address    => $self->address,
				port       => $self->port,
				timeout    => $self->connect_timeout,
				tls        => $self->tls,
				tls_ca     => $self->tls_ca,
				tls_cert   => $self->tls_cert,
				tls_key    => $self->tls_key,
				tls_verify => $self->tls_verify,
			);
		},
		sub {
			# read response
			my $delay = shift;
			delete $self->{client};
			# check is this a handle
			Mojo::SMTP::Client::Exception::Stream->throw($_[0]) unless eval { *{$_[0]} };
			
			$self->_make_stream($_[0], $self->_ioloop);
			$self->_read_response($delay->begin);
			$self->{expected_code} = CMD_OK;
		},
		# check response
		$self->{resp_checker};
		
		if (!@_ || $_[0] ne 'hello') {
			unshift @_, hello => $self->hello;
		}
	}
	else {
		$self->{stream}->start;
	}
	
	push @{$self->{cmds}}, @_;
	push @steps, $self->_make_cmd_steps();
	
	# non-blocking
	my $delay = $self->{delay} = Mojo::IOLoop::Delay->new(ioloop => $self->_ioloop)->steps(@steps);
	$self->{finally} = sub {
		shift if @_ == 2; # delay
		
		if ($cb) {
			my $r = $_[0];
			unless ($r->isa('Mojo::SMTP::Client::Response')) {
				# some error occured, which throwed an exception
				$r = Mojo::SMTP::Client::Response->new('', error => $r);
			}
			
			delete $self->{delay};
			delete $self->{finally};
			
			$cb->($self, $r);
			$cb = undef;
		}
	};
	$delay->catch($self->{finally});
	
	# blocking
	my $resp;
	unless ($self->{nb}) {
		$cb = sub {
			$resp = pop;
		};
		$delay->wait;
		return $self->autodie && $resp->error ? die $resp->error : $resp;
	}
}

sub prepend_cmd {
	my $self = shift;
	croak "no active `send' calls" unless exists $self->{delay};
	
	unshift @{ $self->{cmds} }, @_;
}

sub _ioloop {
	my ($self) = @_;
	return $self->{nb} ? Mojo::IOLoop->singleton : $self->ioloop;
}

sub _server {
	my $self = shift;
	return $self->address.':'.$self->port.':'.$self->tls;
}

sub _make_stream {
	my ($self, $sock, $loop) = @_;
	
	weaken $self;
	my $error_handler = sub {
		delete($self->{cleanup_cb})->() if $self->{cleanup_cb};
		$self->_rm_stream();
		
		# Remaining delay steps skipped automatically somehow (at least for now)
		$self->{finally}->($_[0]);
	};
	
	$self->{stream} = Mojo::IOLoop::Stream->new($sock);
	$self->{stream}->reactor($loop->reactor);
	$self->{stream}->start;
	$self->{stream}->on(timeout => sub {
		$error_handler->(Mojo::SMTP::Client::Exception::Stream->new('Inactivity timeout'));
	});
	$self->{stream}->on(error => sub {
		$error_handler->(Mojo::SMTP::Client::Exception::Stream->new($_[-1]));
	});
	$self->{stream}->on(close => sub {
		$error_handler->(Mojo::SMTP::Client::Exception::Stream->new('Socket closed unexpectedly by remote side'));
	});
}

sub _make_cmd_steps {
	my ($self) = @_;
	
	my ($cmd, $arg) = splice @{ $self->{cmds} }, 0, 2;
	unless ($cmd) {
		# no more commands
		if ($self->{stream}) {
			$self->{stream}->timeout(0);
			$self->{stream}->stop;
		}
		return $self->{finally};
	}
	
	if ( my $sub = $self->can("_cmd_$cmd") ) {
		return (
			$self->$sub($arg), sub {
				my ($delay, $resp) = @_;
				
				$delay->pass($resp);
				$delay->steps( $self->_make_cmd_steps() );
			}
		);
	}
	
	croak 'unrecognized command: ', $cmd;
}

# EHLO/HELO
sub _cmd_hello {
	my ($self, $arg) = @_;
	weaken $self;
	
	return (
		sub {
			my $delay = shift;
			$self->_write_cmd('EHLO ' . $arg, CMD_EHLO);
			$self->_read_response($delay->begin);
			$self->{expected_code} = CMD_OK;
		}, 
		sub {
			eval { $self->{resp_checker}->(@_); $_[1]->{checked} = 1 };
			if (my $e = $@) {
				die $e unless $e->isa('Mojo::SMTP::Client::Response');
				my $delay = shift;
				
				$self->_write_cmd('HELO ' . $arg, CMD_HELO);
				$self->_read_response($delay->begin);
			}
		},
		sub {
			my ($delay, $resp) = @_;
			return $delay->pass($resp) if delete $resp->{checked};
			$self->{resp_checker}->($delay, $resp);
		}
	);
}

# STARTTLS
sub _cmd_starttls {
	my ($self, $arg) = @_;
	weaken $self;
	
	require IO::Socket::SSL and IO::Socket::SSL->VERSION(0.98);
	
	return (
		sub {
			my $delay = shift;
			$self->_write_cmd('STARTTLS', CMD_STARTTLS);
			$self->_read_response($delay->begin);
			$self->{expected_code} = CMD_OK;
		},
		$self->{resp_checker},
		sub {
			my ($delay, $resp) = @_;
			$self->{stream}->stop;
			$self->{stream}->timeout(0);
			
			my ($tls_cb, $tid, $loop, $sock);
			
			my $error_handler = sub {
				$loop->remove($tid);
				$loop->reactor->remove($sock);
				$sock = undef;
				$tls_cb->($delay, undef, @_>=2 ? $_[1] : 'Inactivity timeout');
				$tls_cb = $delay = undef;
			};
			
			$sock = IO::Socket::SSL->start_SSL(
				$self->{stream}->steal_handle,
				SSL_ca_file         => $self->tls_ca,
				SSL_cert_file       => $self->tls_cert,
				SSL_key_file        => $self->tls_key,
				SSL_verify_mode     => $self->tls_verify,
				SSL_verifycn_name   => $self->address,
				SSL_verifycn_scheme => $self->tls_ca ? 'smtp' : undef,
				SSL_startHandshake  => 0,
				SSL_error_trap      => $error_handler
			)
			or return $delay->pass(0, $IO::Socket::SSL::SSL_ERROR);
			
			$tls_cb = $delay->begin;
			$loop = $self->_ioloop;
			
			$tid = $loop->timer($self->inactivity_timeout => $error_handler);
			
			$loop->reactor->io($sock => sub {
				if ($sock->connect_SSL) {
					$loop->remove($tid);
					$loop->reactor->remove($sock);
					$self->_make_stream($sock, $loop);
					$self->{starttls} = 1;
					$sock = $loop = undef;
					$tls_cb->($delay, $resp);
					$tls_cb = $delay = undef;
					return;
				}
				
				return $loop->reactor->watch($sock, 1, 0)
					if $IO::Socket::SSL::SSL_ERROR == IO::Socket::SSL::SSL_WANT_READ();
				return $loop->reactor->watch($sock, 0, 1)
					if $IO::Socket::SSL::SSL_ERROR == IO::Socket::SSL::SSL_WANT_WRITE();
				
			})->watch($sock, 0, 1);
		},
		sub {
			my ($delay, $resp, $error) = @_;
			unless ($resp) {
				$self->_rm_stream();
				Mojo::SMTP::Client::Exception::Stream->throw($error);
			}
			
			$delay->pass($resp);
		}
	);
}

# AUTH
sub _cmd_auth {
	my ($self, $arg) = @_;
	weaken $self;
	
	my $type = lc($arg->{type} // 'plain');
	
	my $set_auth_ok = sub {
		my ($delay, $resp) = @_;
		$self->{authorized} = 1;
		$delay->pass($resp);
	};
	
	if ($type eq 'plain') {
		return (
			sub {
				my $delay = shift;
				$self->_write_cmd('AUTH PLAIN '.b64_encode(join("\0", '', $arg->{login}, $arg->{password}), ''), CMD_AUTH);
				$self->_read_response($delay->begin);
				$self->{expected_code} = CMD_OK;
			},
			$self->{resp_checker},
			$set_auth_ok
		);
	}
	
	if ($type eq 'login') {
		return (
			# start auth
			sub {
				my $delay = shift;
				$self->_write_cmd('AUTH LOGIN', CMD_AUTH);
				$self->_read_response($delay->begin);
				$self->{expected_code} = CMD_MORE;
			},
			$self->{resp_checker},
			# send username
			sub {
				my $delay = shift;
				$self->_write_cmd(b64_encode($arg->{login}, ''), CMD_AUTH);
				$self->_read_response($delay->begin);
				$self->{expected_code} = CMD_MORE;
			},
			$self->{resp_checker},
			# send password
			sub {
				my $delay = shift;
				$self->_write_cmd(b64_encode($arg->{password}, ''), CMD_AUTH);
				$self->_read_response($delay->begin);
				$self->{expected_code} = CMD_OK;
			},
			$self->{resp_checker},
			$set_auth_ok
		);
	}
	
	croak 'unrecognized auth method: ', $type;
}

# FROM
sub _cmd_from {
	my ($self, $arg) = @_;
	weaken $self;
	
	return (
		sub {
			my $delay = shift;
			$self->_write_cmd('MAIL FROM:<'.$arg.'>', CMD_FROM);
			$self->_read_response($delay->begin);
			$self->{expected_code} = CMD_OK;
		},
		$self->{resp_checker}
	);
}

# TO
sub _cmd_to {
	my ($self, $arg) = @_;
	weaken $self;
	
	my @steps;
	
	for my $to (ref $arg ? @$arg : $arg) {
		push @steps, sub {
			my $delay = shift;
			$self->_write_cmd('RCPT TO:<'.$to.'>', CMD_TO);
			$self->_read_response($delay->begin);
			$self->{expected_code} = CMD_OK;
		},
		$self->{resp_checker}
	}
	
	return @steps;
}

# DATA
sub _cmd_data {
	my ($self, $arg) = @_;
	weaken $self;
	
	my @steps;
	
	push @steps, sub {
		my $delay = shift;
		$self->_write_cmd('DATA', CMD_DATA);
		$self->_read_response($delay->begin);
		$self->{expected_code} = CMD_MORE;
	},
	$self->{resp_checker};
	
	if (ref $arg eq 'CODE') {
		my ($data_writer, $data_writer_cb);
		my $was_nl;
		my $last_ch;
		
		$data_writer = sub {
			my $delay = shift;
			unless ($data_writer_cb) {
				$data_writer_cb = $delay->begin;
				$self->{cleanup_cb} = sub {
					undef $data_writer;
				};
			}
			
			my $data = $arg->();
			$data = $$data if ref $data;
			
			unless (length($data) > 0) {
				$self->_write_cmd(($was_nl ? '' : Mojo::SMTP::Client::Response::CRLF).'.', CMD_DATA_END);
				$self->_read_response($data_writer_cb);
				$self->{expected_code} = CMD_OK;
				return delete($self->{cleanup_cb})->();
			}
			# The following part if heavily inspired by Net::Cmd
			my $first_ch = '';
			# We have not send anything yet, so last_ch = "\012" means we are at the start of a line (^. -> ..)
			$last_ch = "\012" unless defined $last_ch;
			if ($last_ch eq "\015") {
				# Remove \012 so it does not get prefixed with another \015 below
				# and escape the . if there is one following it because the fixup
				# below will not find it
				$first_ch = "\012" if $data =~ s/^\012(\.?)/$1$1/;
			}
			elsif ($last_ch eq "\012") {
				# Fixup below will not find the . as the first character of the buffer
				$first_ch = "." if $data =~ /^\./;
			}
			$data =~ s/\015?\012(\.?)/\015\012$1$1/g;
			substr($data, 0, 0) = $first_ch;
			$last_ch = substr($data, -1, 1);
			$was_nl = _has_nl($data);
			$self->{stream}->write($data, $data_writer);
		};
		
		push @steps, $data_writer, $self->{resp_checker};
	}
	else {
		push @steps, sub {
			my $delay = shift;
			(ref $arg ? $$arg : $arg) =~ s/\015?\012(\.?)/\015\012$1$1/g; # turn . into .. if it's first character of the line and normalize newline
			$self->{stream}->write(ref $arg ? $$arg : $arg, $delay->begin);
		},
		sub {
			my $delay = shift;
			$self->_write_cmd((_has_nl($arg) ? '' : Mojo::SMTP::Client::Response::CRLF).'.', CMD_DATA_END);
			$self->_read_response($delay->begin);
			$self->{expected_code} = CMD_OK;
		},
		$self->{resp_checker}
	}
	
	return @steps;
}

# RESET
sub _cmd_reset {
	my ($self, $arg) = @_;
	weaken $self;
	
	return (
		sub {
			my $delay = shift;
			$self->_write_cmd('RSET', CMD_RESET);
			$self->_read_response($delay->begin);
			$self->{expected_code} = CMD_OK;
		},
		$self->{resp_checker}
	);
}

# QUIT
sub _cmd_quit {
	my ($self, $arg) = @_;
	weaken $self;
	
	return (
		sub {
			my $delay = shift;
			$self->_write_cmd('QUIT', CMD_QUIT);
			$self->_read_response($delay->begin);
			$self->{expected_code} = CMD_OK;
		},
		$self->{resp_checker}, sub {
			my $delay = shift;
			$self->_rm_stream();
			$delay->pass(@_);
		}
	);
}

sub _write_cmd {
	my ($self, $cmd, $cmd_const) = @_;
	$self->{last_cmd} = $cmd_const;
	$self->{stream}->write($cmd.Mojo::SMTP::Client::Response::CRLF);
}

sub _read_response {
	my ($self, $cb) = @_;
	$self->{stream}->timeout($self->inactivity_timeout);
	my $resp = '';
	
	$self->{stream}->on(read => sub {
		$resp .= $_[-1];
		if ($resp =~ /^\d+(?:\s[^\n]*)?\n$/m) {
			$self->{stream}->unsubscribe('read');
			$cb->($self, Mojo::SMTP::Client::Response->new($resp));
		}
	});
}

sub _rm_stream {
	my $self = shift;
	$self->{stream}->unsubscribe('close')
	               ->unsubscribe('timeout')
	               ->unsubscribe('error')
	               ->unsubscribe('read');
	delete $self->{stream};
}

sub _has_nl {
	substr(ref $_[0] ? ${$_[0]} : $_[0], -2, 2) eq Mojo::SMTP::Client::Response::CRLF;
}

sub DESTROY {
	my $self = shift;
	if ($self->{stream}) {
		$self->_rm_stream();
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mojo::SMTP::Client - non-blocking SMTP client based on Mojo::IOLoop

=head1 SYNOPSIS

=over

	# blocking
	my $smtp = Mojo::SMTP::Client->new(address => '10.54.17.28', autodie => 1);
	$smtp->send(
		from => 'me@from.org',
		to => 'you@to.org',
		data => join("\r\n", 'From: me@from.org',
		                     'To: you@to.org',
		                     'Subject: Hello world!',
		                     '',
		                     'This is my first message!'
		        ),
		quit => 1
	);
	warn "Sent successfully"; # else will throw exception because of `autodie'

=back

=over

	# non-blocking
	my $smtp = Mojo::SMTP::Client->new(address => '10.54.17.28');
	$smtp->send(
		from => 'me@from.org',
		to => 'you@to.org',
		data => join("\r\n", 'From: me@from.org',
		                     'To: you@to.org',
		                     'Subject: Hello world!',
		                     '',
		                     'This is my first message!'
	            ),
		quit => 1,
		sub {
			my ($smtp, $resp) = @_;
			warn $resp->error ? 'Failed to send: '.$resp->error : 'Sent successfully';
			Mojo::IOLoop->stop;
		}
	);
	
	Mojo::IOLoop->start;

=back

=head1 DESCRIPTION

With C<Mojo::SMTP::Client> you can easily send emails from your Mojolicious application without
blocking of C<Mojo::IOLoop>.

=head1 EVENTS

C<Mojo::SMTP::Client> inherits all events from L<Mojo::EventEmitter> and can emit the following new ones

=head2 start

	$smtp->on(start => sub {
		my ($smtp) = @_;
		# some servers delays first response to prevent SPAM
		$smtp->inactivity_timeout(5*60);
	});

Emitted whenever a new connection is about to start. You can interrupt sending by dying or throwing an exception
from this callback, C<error> attribute of the response will contain corresponding error.

=head2 response

	$smtp->on(response => sub {
		my ($smtp, $cmd, $resp) = @_;
		if ($cmd == Mojo::SMTP::Client::CMD_CONNECT) {
			# and after first response others should be fast enough
			$smtp->inactivity_timeout(10);
		}
	});

Emitted for each SMTP response from the server. C<$cmd> is a command L<constant|/CONSTANTS> for which this
response was sent. C<$resp> is L<Mojo::SMTP::Client::Response> object. You can interrupt sending by dying or
throwing an exception from this callback, C<error> attribute of the response will contain corresponding error.

=head1 ATTRIBUTES

C<Mojo::SMTP::Client> implements the following attributes, which you can set in the constructor or get/set later
with object method call

=head2 address

Address of SMTP server (ip or domain name). Default is C<localhost>

=head2 port

Port of SMTP server. Default is C<25> for plain connection and C<465> if TLS is enabled.

=head2 tls

Enable TLS. Should be true if SMTP server expects encrypted connection. Default is false.
Proper version of L<IO::Socket::SSL> should be installed for TLS support in L<Mojo::IOLoop::Client>,
which you can find with C<mojo version> command.

=head2 tls_ca

Path to TLS certificate authority file. Also activates hostname verification.

=head2 tls_cert

Path to the TLS certificate file.

=head2 tls_key

Path to the TLS key file.

=head2 tls_verify

TLS verification mode. Use C<0> to disable verification, which turned on by default.

=head2 hello

SMTP requires that you identify yourself. This option specifies a string to pass as your mail domain.
Default is C<localhost.localdomain>

=head2 connect_timeout

Maximum amount of time in seconds establishing a connection may take before getting canceled,
defaults to the value of the C<MOJO_CONNECT_TIMEOUT> environment variable or C<10>

=head2 inactivity_timeout

Maximum amount of time in seconds a connection can be inactive before getting closed,
defaults to the value of the C<MOJO_INACTIVITY_TIMEOUT> environment variable or C<20>.
Setting the value to C<0> will allow connections to be inactive indefinitely

=head2 ioloop

Event loop object to use for blocking I/O operations, defaults to a L<Mojo::IOLoop> object

=head2 autodie

Defines should or not C<Mojo::SMTP::Client> throw exceptions for any type of errors. This only usable for
blocking usage of C<Mojo::SMTP::Client>, because non-blocking one should never die. Throwed
exception will be one of the specified in L<Mojo::SMTP::Client::Exception>. When autodie attribute
has false value you should check C<$respE<gt>error> yourself. Default is false.

=head1 METHODS

C<Mojo::SMTP::Client> inherits all methods from L<Mojo::EventEmitter> and implements the following new ones

=head2 send

	$smtp->send(
		from => $mail_from,
		to   => $rcpt_to,
		data => $data,
		quit => 1,
		$nonblocking ? $cb : ()
	);

Send specified commands to SMTP server. Arguments should be C<key =E<gt> value> pairs where C<key> is a command 
and C<value> is a value for this command. C<send> understands the following commands:

=over

=item hello

Send greeting to the server. Argument to this command should contain your domain name. Keep in mind, that
C<Mojo::SMTP::Client> will automatically send greeting to the server right after connection if you not specified
C<hello> as first command for C<send>. C<Mojo::SMTP::Client> first tries C<EHLO> command for greeting and if
server doesn't accept it C<Mojo::SMTP::Client> retries with C<HELO> command.

	$smtp->send(hello => 'mymail.me');

=item starttls

Upgrades connection from plain to encrypted. Some servers requires this before sending any other commands.
L<IO::Socket::SSL> 0.98+ should be installed for this to work. See also L</tls_ca>, L</tls_cert>, L</tls_key>
attributes

	$smtp->tls_ca('/etc/ssl/certs/ca-certificates.crt');
	$smtp->send(starttls => 1);

=item auth

Authorize on SMTP server. Argument to this command should be a reference to a hash with C<type>,
C<login> and C<password> keys. Only PLAIN and LOGIN authorization are supported as C<type> for now.
You should authorize only once per session.

    $smtp->send(auth => {login => 'oleg', password => 'qwerty'});      # defaults to AUTH PLAIN
    $smtp->send(auth => {login => 'oleg', password => 'qwerty', type => 'login'}); # AUTH LOGIN

=item from

From which email this message was sent. Value for this cammand should be a string with email

	$smtp->send(from => 'root@cpan.org');

=item to

To which email(s) this message should be sent. Value for this cammand should be a string with email
or reference to array with email strings (for more than one recipient)

	$smtp->send(to => 'oleg@cpan.org');
	$smtp->send(to => ['oleg@cpan.org', 'do_not_reply@cpantesters.org']);

=item reset

After this command server should forget about any started mail transaction and reset it status as it was after response to C<EHLO>/C<HELO>.
Note: transaction considered started after C<MAIL FROM> (C<from>) command.

	$smtp->send(reset => 1);

=item data

Email body to be sent. Value for this command should be a string (or reference to a string) with email body or reference to subroutine
each call of which should return some chunk of the email as string (or reference to a string) and empty string (or reference to empty string)
at the end (useful to send big emails in memory-efficient way)

	$smtp->send(data => "Subject: This is my first message\r\n\r\nSent from Mojolicious app");
	$smtp->send(data => sub { sysread(DATA, my $buf, 1024); $buf });

=item quit

Send C<QUIT> command to SMTP server which will close the connection. So for the next use of this server connection will be
reestablished. If you want to send several emails with this server it will be more efficient to not quit
the connection until last email will be sent.

=back

For non-blocking usage last argument to C<send> should be reference to subroutine which will be called when result will
be available. Subroutine arguments will be C<($smtp, $resp)>. Where C<$resp> is object of L<Mojo::SMTP::Client::Response> class.
First you should check C<$resp-E<gt>error> - if it has true value this means that it was error somewhere while sending.
If C<error> has false value you can get code and message for response to last command with C<$resp-E<gt>code> (number) and
C<$resp-E<gt>message> (string).

For blocking usage C<$resp> will be returned as result of C<$smtp-E<gt>send> call. C<$resp> is the same as for
non-blocking result. If L</autodie> attribute has true value C<send> will throw an exception on any error.
Which will be one of C<Mojo::SMTP::Client::Exception::*> or an error throwed by the user inside event handler.

B<Note>. For SMTP protocol it is important to send commands in certain order. Also C<send> will send all commands in order you are
specified. So, it is important to pass arguments to C<send> in right order. For basic usage this will always be:
C<from -E<gt> to -E<gt> data -E<gt> quit>. You should also know that it is absolutely correct to specify several non-unique commands.
For example you can send several emails with one C<send> call:

	$smtp->send(
		from => 'someone@somewhere.com',
		to   => 'somebody@somewhere.net',
		data => $mail_1,
		from => 'frodo@somewhere.com',
		to   => 'garry@somewhere.net',
		data => $mail_2,
		quit => 1
	);

B<Note>. Connection to SMTP server will be made on first C<send> or for each C<send> when socket connection not already estabilished
(was closed by C<QUIT> command or errors in the stream). It is error to make several simultaneous non-blocking C<send> calls on the
same C<Mojo::SMTP::Client>, because each client has one global stream per client. So, you need to create several
clients to make simultaneous sending.

=head2 prepend_cmd

	$smtp->prepend_cmd(reset => 1, starttls => 1);

Prepend specified commands to the queue, so the next command sent to the server will be the first you specified in C<prepend_cmd>.
You can prepend commands only when sending already in progress and there are commands in the queue. So, the most common place to call
C<prepend_cmd> is inside C<response> event handler. For example this is how we can say "start SSL session if server supports it":

	$smtp->on(response => sub {
		my ($smtp, $cmd, $resp) = @_;
		if ($cmd == Mojo::SMTP::Client::CMD_EHLO && $resp->message =~ /STARTTLS/i) {
			$smtp->prepend_cmd(starttls => 1);
		}
	});
	$smtp->send(
		from => $from,
		to   => $to,
		data => $data,
		quit => 1
	);

C<prepend_cmd> accepts same commands as L</send>.

=head1 CONSTANTS

C<Mojo::SMTP::Client> has this non-importable constants

	CMD_CONNECT  # client connected to SMTP server
	CMD_EHLO     # client sent EHLO command
	CMD_HELO     # client sent HELO command
	CMD_STARTTLS # client sent STARTTLS command
	CMD_AUTH     # client sent AUTH command
	CMD_FROM     # client sent MAIL FROM command
	CMD_TO       # client sent RCPT TO command
	CMD_DATA     # client sent DATA command
	CMD_DATA_END # client sent . command
	CMD_RESET    # client sent RSET command
	CMD_QUIT     # client sent QUIT command

=head1 VARIABLES

C<Mojo::SMTP::Client> has this non-importable variables

=over

=item %CMD

Get human readable command by it constant

	print $Mojo::SMTP::Client::CMD{ Mojo::SMTP::Client::CMD_EHLO };

=back

=head1 COOKBOOK

=head2 How to send simple ASCII message

ASCII message is simple enough, so you can generate it by hand

	$smtp->send(
		from => 'me@home.org',
		to   => 'you@work.org',
		data => join(
			"\r\n",
			'MIME-Version: 1.0',
			'Subject: Subject of the message',
			'From: me@home.org',
			'To: you@work.org',
			'Content-Type: text/plain; charset=UTF-8',
			'',
			'Text of the message'
		)
	);

However it is not recommended to generate emails by hand if you are not
familar with MIME standard. For more convenient approaches see below.

=head2 How to send text message with possible non-ASCII characters

For more convinient way to generate emails we can use some email generators
available on CPAN. L<MIME::Lite> for example. With such modules we can get
email as a string and send it with C<Mojo::SMTP::Client>

	use MIME::Lite;
	use Encode qw(encode decode);
	
	my $msg = MIME::Lite->new(
		Type    => 'text',
		From    => 'me@home.org',
		To      => 'you@work.org',
		Subject => encode('MIME-Header', decode('utf-8', '世界, 労働, 5月!')),
		Data    => 'Novosibirsk (Russian: Новосибирск; IPA: [nəvəsʲɪˈbʲirsk]) is the third most populous '.
		           'city in Russia after Moscow and St. Petersburg and the most populous city in Asian Russia'
	);
	$msg->attr('content-type.charset' => 'UTF-8');
	
	$smtp->send(
		from => 'me@home.org',
		to   => 'you@work.org',
		data => $msg->as_string
	);

=head2 How to send message with attachment

This is also simple with help of L<MIME::Lite>

	use MIME::Lite;
	
	my $msg = MIME::Lite->new(
		Type    => 'multipart/mixed',
		From    => 'me@home.org',
		To      => 'you@work.org',
		Subject => 'statistic for 10.03.2015'
	);
	$msg->attach(Path => '/home/kate/stat/10032015.xlsx', Disposition => 'attachment', Type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
	
	$smtp->send(
		from => 'me@home.org',
		to   => 'you@work.org',
		data => $msg->as_string
	);

=head2 How to send message with BIG attachment

It will be not cool to get message with 50 mb attachment into memory before sending.
Fortunately with help of L<MIME::Lite> and L<MIME::Lite::Generator> we can generate
our email by small portions. As you remember C<data> command accepts subroutine reference
as argument, so it will be super easy to send our big email in memory-efficient way

	use MIME::Lite;
	
	my $msg = MIME::Lite->new(
		Type    => 'multipart/mixed',
		From    => 'me@home.org',
		To      => 'you@work.org',
		Subject => 'my home video'
	);
	# Note: MIME::Lite will not load this file into memory
	$msg->attach(Path => '/home/kate/videos/beach.avi', Disposition => 'attachment', Type => "video/msvideo");
	
	my $generator = MIME::Lite::Generator->new($msg);
	
	$smtp->send(
		from => 'me@home.org',
		to   => 'you@work.org',
		data => sub { $generator->get() }
	);

=head2 How to send message using public email services like Gmail

Most such services provides access via SMTP in addition to web interface, but needs authorization. To protect your
login and password most of them requires to start encrypted session (by upgrading plain connection with C<starttls>
or by initial C<tls> connection). For example Gmail supports both this ways:

	# make plain connection to port 25
	my $smtp = Mojo::SMTP::Client->new(address => 'smtp.gmail.com');
	# and upgrade it to TLS with starttls
	$smtp->send(
		starttls => 1,
		auth => {login => $login, password => $password},
		from => $from,
		to   => $to,
		data => $msg,
		quit => 1
	);
	
	# or make initial TLS connection to port 465
	my $smtp = Mojo::SMTP::Client->new(address => 'smtp.gmail.com', tls => 1);
	# no need to use starttls
	$smtp->send(
		auth => {login => $login, password => $password},
		from => $from,
		to   => $to,
		data => $msg,
		quit => 1
	);

=head2 How to send message directly, without using of MTAs such as sendmail, postfix, exim, ...

Sometimes it is more suitable to send message directly to SMTP server of recipient. For example
if you haven't any MTA available or want to check recipient's server responses (e.g. to know is
such user exists on this server [see L<Mojo::Email::Checker::SMTP>]). First you need to know address
of necessary SMTP server. We'll get it with help of L<Net::DNS>. Then we'll send it as usual

	# will use non-blocking approach in this example
	use strict;
	use MIME::Lite;
	use Net::DNS;
	use Mojo::SMTP::Client;
	use Mojo::IOLoop;
	
	use constant TO => 'oleg@cpan.org';
	
	my $loop = Mojo::IOLoop->singleton;
	my $resolver = Net::DNS::Resolver->new();
	my ($domain) = TO =~ /@(.+)/;
	
	# Get MX records
	my $sock = $resolver->bgsend($domain, 'MX');
	$loop->reactor->io($sock => sub {
		my $packet = $resolver->bgread($sock);
		$loop->reactor->remove($sock);
		
		my @mx;
		if ($packet) {
			for my $rec ($packet->answer) {
				push @mx, $rec->exchange if $rec->type eq 'MX';
			}
		}
		
		# Will try with first or plain domain name if no mx records found
		my $address = @mx ? $mx[0] : $domain;
		
		my $smtp = Mojo::SMTP::Client->new(
			address => $address,
			# it is important to properly identify yourself
			hello   => 'home.org'
		);
		
		my $msg = MIME::Lite->new(
			Type    => 'text',
			From    => 'me@home.org',
			To      => TO,
			Subject => 'Direct email',
			Data    => 'Get it!'
		);
		
		$smtp->on(response => sub {
			# some debug
			my ($smtp, $cmd, $resp) = @_;
			
			print ">>", $Mojo::SMTP::Client::CMD{$cmd}, "\n";
			print "<<", $resp, "\n";
		});
		
		$smtp->send(
			from => 'me@home.org',
			to   => TO,
			data => $msg->as_string,
			quit => 1,
			sub {
				my ($smtp, $resp) = @_;
				
				warn $resp->error ? 'Failed to send: '.$resp->error :
				                      'Sent successfully with code: ', $resp->code;
				
				$loop->stop;
			}
		);
	});
	$loop->reactor->watch($sock, 1, 0);
	
	$loop->start;

Note: some servers may check your PTR record, availability of SMTP server
on your domain and so on.

=head1 SEE ALSO

L<Mojo::SMTP::Client::Response>, L<Mojo::SMTP::Client::Exception>, L<Mojolicious>, L<Mojo::IOLoop>,
L<RFC5321 (SMTP)|https://tools.ietf.org/html/rfc5321>, L<RFC3207 (STARTTLS)|https://tools.ietf.org/html/rfc3207>,
L<RFC4616 (AUTH PLAIN)|https://tools.ietf.org/html/rfc4616>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
