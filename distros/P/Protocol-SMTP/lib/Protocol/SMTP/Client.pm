package Protocol::SMTP::Client;
$Protocol::SMTP::Client::VERSION = '0.002';
use strict;
use warnings;
use utf8;

use curry;
use Future;
use Future::Utils qw(try_repeat fmap_void);
use Authen::SASL;
use MIME::Base64 qw(encode_base64 decode_base64);
use Encode;

=head1 NAME

Protocol::SMTP::Client - abstract client support for mail sending

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Provides a client implementation for interacting with SMTP servers.

=cut

=head1 METHODS

=head2 new

Instantiates an SMTP client instance.

Takes no parameters.

=cut

sub new {
	my $class = shift;
	my $self = bless {@_}, $class;
	$self->{auth_methods} = [];
	$self->{task_queue} = [];
	$self->{multi} = [];
	$self
}

=head2 auth_mechanism_override

Set this on instantiation to pick a specific auth method.

=cut

sub auth_mechanism_override { shift->{auth_mechanism_override} }

=head2 login

Attempts to log in to the server. Takes the following named parameters:

=over 4

=item * user - the username we're logging in with, might be your email address
or a plain username

=item * pass - used for password-based auth mechanisms such as PLAIN or MD5

=back

Note that other auth mechanisms may provide additional fields - this will
mostly be determined by how L<Authen::SASL> deals with the authentication
process.

Returns a L<Future> which resolves once login completes or fails.

=cut

sub login {
	my $self = shift;
	return $self->new_future->fail('no auth?') unless my @auth = $self->auth_methods;

	my %args = @_;
	my $auth_string = join ' ', @auth;
	$self->debug_printf("Auth mechanisms [%s]", $auth_string);
	$auth_string = $self->auth_mechanism_override if $self->auth_mechanism_override;
	my $f = $self->new_future;
	$self->add_task(sub {
		my $sasl = Authen::SASL->new(
			mechanism => $auth_string,
			callback => {
				user => sub { $args{user} },
				authname => sub { $args{user} },
				pass => sub { $args{pass} },
			},
		);
		my $client = $sasl->client_new(
			'smtp',
			$args{host},
			0,
		);

		my $rslt = $client->client_start;
		$rslt = (defined($rslt) && length($rslt)) ? encode_base64($rslt, '') : '';
		$self->write_line(join ' ',
			'AUTH',
			$client->mechanism,
			$rslt
		);
		$self->{auth_handler} = sub {
			my $code = shift;
			if($code =~ /^5/) {
				delete $self->{auth_handler};
				return $f->fail(shift);
			} elsif($code =~ /^3/) {
				my $data = decode_base64(shift);
				$self->write_line(
					encode_base64(
						$client->client_step($data),
						''
					)
				);
			} elsif($code =~ /2/) {
				delete $self->{auth_handler};
				$f->done
			}
		};
		$f
	});
	$f;
}


=head2 send

Attempts to send the given email.

Expects the following named parameters:

=over 4

=item * to - single email address or arrayref of recipients

=item * from - envelope sender

=item * data - the email content itself, currently needs to be 8BITMIME
encoded, please raise an RT if other formats are required.

=item * content - the email as a Perl Unicode string, this is mutually
exclusive with the data parameter

=back

Returns a L<Future> which will resolve when the send is complete.

=cut

sub send {
	my $self = shift;
	my %args = @_;
	my $f = $self->new_future;
	$self->add_task(sub {
		$self->send_mail(
			%args
		)->on_ready($f);
	});
	$f
}

=head1 INTERNAL METHODS

The following are used internally. They are not likely to be of much
use to client code, but may need to be called by implementations.
See L<Net::Async::SMTP> for a reference.

=head2 new_future

Instantiates a new L<Future>. Sometimes implementations may want
a L<Future> subclass which knows how to C<get>. Defaults to L<Future>.

=cut

sub new_future {
	my $factory = shift->{future_factory};
	$factory ? $factory->() : Future->new;
}

=head2 debug_printf

Used internally for debugging, returns an empty list.

=cut

sub debug_printf {
	return unless $ENV{'PERL_SMTP_DEBUG'};
	my $self = shift;
	my $fmt = shift;
	printf "$fmt\n", @_;
	return;
}

=head2 write

Uses the configured writer to send data to the remote.

=cut

sub write {
	my $self = shift;
	$self->{writer}->(@_);
}

=head2 have_active_task

Returns true if we're partway through processing something.

=cut

sub have_active_task { exists shift->{active_task} }

=head2 write_line

Frames a line appropriately for sending to a remote.

=cut

sub write_line {
	my $self = shift;
	my $line = shift;
	my $f = defined(wantarray) ? $self->new_future : undef;
	$self->debug_printf("Writing %s", $line);
	$self->write($line . "\x0D\x0A",
		defined(wantarray)
		? (on_flush => sub { $f->done })
		: ()
	);
	$f
}

=head2 body_encoding

Body encoding, currently hardcoded as 8BITMIME.

=cut

sub body_encoding { '8BITMIME' }

=head2 send_mail

Sequence of writes to send email to the remote. Normally you wouldn't use
this directly, it'd be queued as a task by L</send>.

=cut

sub send_mail {
	my $self = shift;
	my %args = @_;
	my @recipient = (ref($args{to}) eq 'ARRAY') ? @{$args{to}} : $args{to};

	die "Must specify either data or content" unless 1 == grep exists $args{$_}, qw(data content);

	# We accept pre-encoded data or a Perl Unicode string.
	$args{data} = Encode::encode('UTF-8' => delete $args{content}) if exists $args{content};

	# TODO Since our email content is not particularly heavy, and we're
	# dealing with 8bitmime, this uses the naïve split-into-lines approach
	# with the entire message in memory. Binary attachments, alternative
	# encodings and larger messages are not well handled here.
	# This is fixed by using Aliran, of course, but we don't have that option
	# just yet.
	my @mail = split /\x0D\x0A/, $args{data};

	{
		my $mail_line = 'MAIL FROM:<' . $args{from} . '>';
		$mail_line .= ' BODY=' . $self->body_encoding if $self->body_encoding;
		$self->write_line($mail_line);
	}
	$self->wait_for(250)
	->then(sub {
		fmap_void {
			$self->write_line(q{RCPT TO:<} . shift . q{>});
			# Each recipient line should be acknowledged with 250 if valid.
			$self->wait_for(250)
		} foreach => \@recipient
	})->then(sub {
		$self->write_line(q{DATA});
		$self->wait_for(354)
	})->then(sub {
		$self->{sending_content} = 1;
		(fmap_void {
			my $line = shift;
			# RFC2821 section 4.5.2
			$line = ".$line" if substr($line, 0, 1) eq '.';
			$self->write_line($line);
		} generate => sub {
			return unless @mail;
			shift @mail
		})
	})->then(sub {
		$self->{sending_content} = 0;
		$self->write_line('.');
		$self->wait_for(250)
	});
}

=head2 check_next_task

Called internally to check whether we have any other tasks we could be doing.

=cut

sub check_next_task {
	my $self = shift;
	return 0 unless @{$self->{task_queue}};

	my $next = shift(@{$self->{task_queue}});
	$self->{active_task} = 1;
	my $f = $next->();
	$f->on_ready(sub {
		delete $self->{active_task};
		$self->check_next_task;
		undef $f
	});
	return 1;
}

=head2 has_feature

Returns true if we have the given feature.

=cut

sub has_feature { $_[0]->{features}{$_[1]} }

=head2 remote_feature

Marks the given feature from EHLO response as supported.

Also applies AUTH values.

=cut

sub remote_feature {
	my $self = shift;
	my ($feature, $param) = @_;
	if($feature eq 'AUTH') {
		$self->{auth_methods} = [split ' ', $param] unless $self->{auth_method_override};
	} else {
		$self->{features}{$feature} = $param // 1;
	}
}

=head2 auth_methods

Internal accessor, returns the list of defined authentication methods.

=cut

sub auth_methods { @{shift->{auth_methods}} }

=head2 send_greeting

Sends the EHLO greeting and handles the resulting feature list.

=cut

sub send_greeting {
	my $self = shift;
	# Start with our greeting, which should receive back a nice list of features
	$self->write_line(
		q{EHLO localhost}
	);
	$self->wait_for(250)->on_done(sub {
		$self->{remote_domain} = shift;
		for (@_) {
			my ($feature, $param) = /^(\S+)(?: (.*))?$/;
			$self->remote_feature($feature => $param);
		}
	});
}

=head2 starttls

Switch to TLS mode.

=cut

sub starttls {
	my $self = shift;
	$self->write_line(q{STARTTLS});
	$self->wait_for(220)
}

=head2 startup

Get initial startup banner.

=cut

sub startup {
	my $self = shift;
	$self->wait_for(220)->on_done(sub {
		$self->{remote_banner} = shift;
	});
}

=head2 wait_for

Waits for the given status code.

If we get something else, will mark as a failure.

=cut

sub wait_for {
	my $self = shift;
	my $code = shift;
	my $f = $self->new_future;
	push @{$self->{pending}}, [ $code => $f ];
	$f
}

=head2 handle_line

Handle input line from remote.

=cut

sub handle_line {
	my $self = shift;
	my $line = shift;
	$self->debug_printf("Received line: %s", $line);

	my ($code, $multi, $remainder) = $line =~ /^(\d{3})([- ])(.*)$/;
	if($self->{auth_handler}) {
		return $self->{auth_handler}->($code, $remainder);
	}

	push @{$self->{multi}}, $remainder;

	if($multi eq ' ') {
		my $task = shift @{$self->{pending}};
		if($task->[0] == $code) {
			$self->debug_printf("Applying line [$_] for multi-line task") for @{$self->{multi}};
			$task->[1]->done(@{$self->{multi}});
		} else {
			$self->debug_printf("We had an unexpected code - $code instead of " . $task->[0]);
			$task->[1]->fail($code => $remainder, 'expected ' . $task->[0]);
		}
		$self->{multi} = [];
		$self->check_next_task unless @{$self->{pending}};
	}
}

=head2 add_task

Add another task to the queue.

=cut

sub add_task {
	my $self = shift;
	my $task = shift;
	push @{$self->{task_queue}}, $task;
	$self->check_next_task unless $self->have_active_task;
}

1;

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
