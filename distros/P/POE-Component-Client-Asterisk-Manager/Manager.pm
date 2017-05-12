package POE::Component::Client::Asterisk::Manager;

######################################################################
### POE::Component::Client::Asterisk::Manager
### David Davis (xantus@cpan.org)
###
### Copyright (c) 2003-2005 David Davis and Teknikill.  All Rights
### Reserved. This module is free software; you can redistribute it
### and/or modify it under the same terms as Perl itself.
######################################################################

use strict;
use warnings;

our $VERSION = '0.08';

use Carp qw(croak);
use POE qw( Component::Client::TCP );
use Digest::MD5;

sub DEBUG { 0 }

sub new {
	my $package = shift;
	croak "$package requires an even number of parameters" if @_ % 2;
	my %params = @_;
	my $alias = $params{'Alias'};

	$alias = 'asterisk_client' unless defined($alias) and length($alias);

	my $listen_port = $params{listen_port} || 5038;

	POE::Session->create(
		#options => {trace=>1},
		args => [ %params ],
		package_states => [
			'POE::Component::Client::Asterisk::Manager' => {
				_start       => '_start',
				_stop        => '_stop',
				signals      => 'signals',
			}
		],
		inline_states => $params{inline_states},
#		{
#			_default => sub {
#				print STDERR "$_[STATE] called\n";
#			},
#		},
	);

	return 1;
}

sub _start {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	my %params = splice(@_,ARG0);

	if (ref($params{Options}) eq 'HASH') {
		$session->option( %{$params{Options}} );
	}

	$params{reconnect_time} = $params{reconnect_time} || 5;
	$params{requeue_posts} = $params{requeue_posts} || undef;

	$kernel->alias_set($params{Alias});

	# watch for SIGINT
#	$kernel->sig('INT', 'signals');

	$heap->{client} = POE::Component::Client::TCP->new(
		RemoteAddress => $params{RemoteHost},
		RemotePort => $params{RemotePort},
		# no longer a seperate package - see below
		Filter     => "POE::Filter::Asterisk::Manager",
		Alias => "$params{Alias}_client",
		Args => [ \%params ],
		Started => sub {
			$_[HEAP]->{params} = $_[ARG0];
		},
		Disconnected => sub {
			$_[KERNEL]->delay(reconnect => $_[HEAP]->{params}->{reconnect_time});
		},
		Connected => sub {
			my $heap = $_[HEAP];
			DEBUG && print STDERR sprintf("connected to %s:%s\n",$heap->{params}->{RemoteHost},$heap->{params}->{RemotePort});
			$heap->{_connected} = 0;
			$heap->{_logged_in} = 0;
			$heap->{_auth_stage} = 0;
			$_[KERNEL]->delay( recv_timeout => 5 );

                      if ($heap->{params}->{Astmanproxy}) {
                              # For astmanproxy?  Don't wait for a response
                              $heap->{_connected} = 1;
                              $kernel->call($_[SESSION] => login => splice(@_,ARG0));
                      }
		},
		ConnectError => sub {
			my $heap = $_[HEAP];
			DEBUG && print STDERR sprintf("could not connect to %s:%s, reconnecting in %s seconds...\n"
				,$heap->{params}->{RemoteHost},$heap->{params}->{RemotePort},$heap->{params}->{reconnect_time});
			$_[KERNEL]->delay(reconnect => $heap->{params}->{reconnect_time});
		},
		ServerInput => sub {
			my ( $kernel, $heap, $input ) = @_[KERNEL, HEAP, ARG0];

			DEBUG && do {
				require Data::Dumper;
				print Data::Dumper->Dump([$input],['input']);
			};

			if ($heap->{_logged_in} == 0 && $heap->{_connected} == 0) {
				$kernel->delay( recv_timeout => 5 );
				if ($input->{acm_version}) {
					$heap->{_version} = $input->{acm_version};
					$heap->{_connected} = 1;
					$kernel->call($_[SESSION] => login => splice(@_,ARG0));
				} else {
					print STDERR "Invalid Protocol (wrong port?)\n";
					$kernel->yield("shutdown");
				}
			} elsif ($heap->{_connected} == 1 && $heap->{_logged_in} == 0) {
				$kernel->call($_[SESSION] => login => splice(@_,ARG0));
			} elsif ($heap->{_logged_in} == 1) {
				$kernel->call($_[SESSION] => callbacks => splice(@_,ARG0));
			}
		},

		InlineStates => {
			_put => sub {
				my $heap = $_[HEAP];
				if ($heap->{server}) {
					$heap->{server}->put($_[ARG0]);
				} else {
					if ($heap->{requeue_posts}) {
						push(@{$heap->{queued}},$_[ARG0]);
					} else {
						print STDERR "cannot send when not connected! -ignored-\n";
					}
				}
			},
			login_complete => sub {
				my ( $kernel, $heap ) = @_[KERNEL, HEAP];
				DEBUG && print STDERR "logged in and ready to process events\n";
				# call the _connected state
				$kernel->yield("_connected" => splice(@_,ARG0));
			},
			recv_timeout => sub {
				my ( $kernel, $heap ) = @_[KERNEL, HEAP];
				unless ($heap->{_connected} == 1) {
					print STDERR "Timeout waiting for response\n";
					$heap->{_connected} = 0;
					$heap->{_logged_in} = 0;
					$kernel->yield("shutdown");
				}
			},
			login => sub {
				my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
				if ($heap->{_logged_in} == 1) {
					# shouldn't get here
					DEBUG && print STDERR "Login called when already logged in\n";
					#$kernel->yield(callbacks => splice(@_,ARG0));
					return;
				}
				if ($heap->{_auth_stage} == 0) {
					$heap->{server}->put({'Action' => 'Challenge', 'AuthType' => 'MD5'});
					$heap->{_auth_stage} = 1;
				} elsif ($heap->{_auth_stage} == 1) {
					unless ($input->{Response} && lc($input->{Response}) eq 'success') {
						print STDERR "AuthType MD5 may not be supported\n";
						$kernel->yield("shutdown");
						return;
					}
					if ($input->{Challenge}) {
						if (! defined $heap->{params}->{Password}) {
							print STDERR "No password provided\n";
							$kernel->yield("shutdown");
							return;
						}

						my $digest = Digest::MD5::md5_hex("$input->{Challenge}$heap->{params}->{Password}");
						$heap->{server}->put({'Action' => 'Login', 'AuthType' => 'MD5', 'Username' => $heap->{params}->{Username}, 'Key' => $digest });
						$heap->{_auth_stage} = 2;
					}
				} elsif ($heap->{_auth_stage} == 2) {
					if ($input->{Message} && lc($input->{Message}) eq 'authentication accepted') {
						delete $heap->{_auth_stage};
						$heap->{_logged_in} = 1;
						# I remembered inline_states not working (above), so i put this in
						foreach my $k (keys %{$heap->{params}->{inline_states}}) {
							$kernel->state($k => $heap->{params}->{inline_states}{$k});
						}
						if (ref($heap->{queued}) eq 'ARRAY') {
							foreach my $a (@{$heap->{queued}}) {
								$heap->{server}->put($a);
							}
							delete $heap->{queued};
						}
						$kernel->yield(login_complete => splice(@_,ARG0));
					} elsif ($input->{Message} && lc($input->{Message}) eq 'authentication failed') {
						print STDERR "Authentication failed.\n";
						$heap->{_connected} = 0;
						$heap->{_logged_in} = 0;
						$kernel->yield("shutdown");
					}
				}
			},
			callbacks => sub {
				my ($kernel, $heap, $session, $input) = @_[KERNEL, HEAP, SESSION, ARG0];
				# TODO this stuff needs some work
				next unless (ref($input));
				my $qual = 0;
				foreach my $k (keys %{$heap->{params}->{CallBacks}}) {
					my $match = 0;
					if (ref($heap->{params}->{CallBacks}{$k}) eq 'HASH') {
						foreach my $c (keys %{$heap->{params}->{CallBacks}{$k}}) {
							last if ($match == 1);
							if (exists($input->{$c}) && $heap->{params}->{CallBacks}{$k}{$c} eq $input->{$c}) {
								$match = 2;
								$qual++;
							} else {
								$match = 1;
							}
						}
						# matched ALL of the callback (not 2 of them like it looks like)
						if ($match == 2) {
							# callback good
							DEBUG && print STDERR "callback $k is good\n";
							$kernel->yield($k => $input);
						}
					} elsif ($heap->{params}->{CallBacks}{$k} eq ':all' || $heap->{params}->{CallBacks}{$k} eq 'default') {
						$kernel->yield($k => $input);
					} else {
						print STDERR "Incorrectly written callback $k\n";
					}
				}
				# use the :all qualifier now
				#if ($qual == 0) {
				#	$kernel->yield("default" => splice(@_,ARG0));
				#}
			},
		},
	);
	DEBUG && print STDERR "Client started.\n";
}

sub _stop {
	$_[KERNEL]->yield("shutdown");
	DEBUG && print STDERR "Client stopped.\n";
}

# Handle incoming signals (INT)

# TODO disconnect gracefully
sub signals {
	my $signal_name = $_[ARG0];
		
#	DEBUG && print STDERR "Client caught SIG$signal_name\n";
	
	# do not handle the signal
	return 0;
}


1;

package POE::Filter::Asterisk::Manager;

use strict;
use Carp qw(croak);

sub DEBUG { 0 };

sub new {
	my $type = shift;
	my $self = {
		buffer => '',
		crlf => "\x0D\x0A",
	};
	bless $self, $type;
	$self;
}

sub get {
	my ($self, $stream) = @_;

	# Accumulate data in a framing buffer.
	$self->{buffer} .= join('', @$stream);

	my $many = [];
	while (1) {
		my $input = $self->get_one([]);
		if ($input) {
			push(@$many,@$input);
		} else {
			last;
		}
	}

	return $many;
}

sub get_one_start {
	my ($self, $stream) = @_;

	DEBUG && do {
		my $temp = join '', @$stream;
		$temp = unpack 'H*', $temp;
		warn "got some raw data: $temp\n";
	};

	# Accumulate data in a framing buffer.
	$self->{buffer} .= join('', @$stream);
}

sub get_one {
	my $self = shift;

	return [] if ($self->{finish});


	if ($self->{buffer} =~ s#^(?:Asterisk|Aefirion) Call Manager(?: Proxy)?/(\d+\.\d+\w*)$self->{crlf}##is) {
		return [{ acm_version => $1 }];
	}

	return [] unless ($self->{crlf});
	my $crlf = $self->{crlf};

	# collect lines in buffer until we find a double line
	return [] unless($self->{buffer} =~ m/${crlf}${crlf}/s);


	$self->{buffer} =~ s/(^.*?)(${crlf}${crlf})//s;

	my $buf = "$1${crlf}";
	
	my $kv = {};

	foreach my $line (split(/(:?${crlf})/,$buf)) {
		my $tmp = $line;
		$tmp =~ s/\r|\n//g;
		next unless($tmp);

		if ($line =~ m/([\w\-]+)\s*:\s+(.*)/) {
			my $key = $1;
			my $val = $2;
			DEBUG && print "recv key $key: $val\n";

			if ($key eq 'Variable',) {
				for my $v( split /\r/, $val ) {
					$v =~ s/^Variable\:\s*//;
					my @parts = split /=/, $v;
					$kv->{$key}{$parts[0]} = $parts[1];
					DEBUG && print "  recv variable: $parts[0] => $parts[1]\n";
				}
			} else {
				$kv->{$key} = $val;
			}
		} else {
			$kv->{content} .= "$line";
		}
	}

	return (keys %$kv) ? [$kv] : [];
}

sub put {
	my ($self, $hrefs) = @_;
	my @raw;
	for my $i ( 0 .. $#{$hrefs} ) {
		if (ref($hrefs->[$i]) eq 'HASH') {
			foreach my $k (keys %{$hrefs->[$i]}) {
				DEBUG && print "send key $k: $hrefs->[$i]{$k}\n";
				push(@raw,"$k: $hrefs->[$i]{$k}$self->{crlf}");
			}
		} elsif (ref($hrefs->[$i]) eq 'ARRAY') {
			push(@raw, join("$self->{crlf}", @{$hrefs->[$i]}, ""));
		} elsif (ref($hrefs->[$i]) eq 'SCALAR') {
			push(@raw, $hrefs->[$i]);
		} else {
			croak "unknown type ".ref($hrefs->[$i])." passed to ".__PACKAGE__."->put()";
		}
		push(@raw,"$self->{crlf}");
	}
	\@raw;
}

sub get_pending {
	my $self = shift;
	return [ $self->{buffer} ] if length $self->{buffer};
	return undef;
}

1;

__END__

=head1 NAME

POE::Component::Client::Asterisk::Manager - Event-based Asterisk / Aefirion Manager Client

=head1 SYNOPSIS

  use POE qw( Component::Client::Asterisk::Manager );

  POE::Component::Client::Asterisk::Manager->new(
	Alias           => 'monitor',
	RemoteHost		=> 'localhost',
	RemotePort      => 5038, # default port
	CallBacks  => {
		input => ':all',  # catchall for all manager events
		ring => {
			'Event' => 'Newchannel',
			'State' => 'Ring',
		},
	},
	inline_states => {
		input => sub {
			my $input = $_[ARG0];
			# good for figuring out what manager events look like
			require Data::Dumper;
			print Data::Dumper->Dump([$input]);
		},
		ring => sub {
			my $input = $_[ARG0];
			# $input is a hash ref with info from 
			print STDERR "RING on channel $input->{Channel}\n";
		},	
	},
  );

  $poe_kernel->run();

=head1 DESCRIPTION

POE::Component::Client::Asterisk::Manager is an event driven Asterisk manager
client.  This module should also work with Aefirion.

=head1 METHODS

=head2 new()

This method creates a POE::Component::Client::TCP session and works inside
that session. You can specify the alias, host, port and inline_states.
See the synopsis for an example.

=head1 CALLBACKS

Callbacks are events that meet a criteria specified in a hash ref

For example:

	ring => {
		'Event' => 'Newchannel',
		'State' => 'Ring',
	},

The event 'ring' will be called with a hash href in ARG0 when the component
receives a manager event matching 'Newchannel' and manager state 'Ring'.

You can specify a catch all event like this:

	catch_all => ':all'

Note: This was changed from 'default' to ':all' in an effort to make it 
more clear.  'default' will also work.

=head1 BUGS

Please report them via RT:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE%3A%3AComponent%3A%3AClient%3A%3AAsterisk%3A%3AManager>

=head1 EXAMPLES

There are a few examples in the examples directory that can get you going.

=head1 AUTHOR

David Davis, E<lt>xantus@cpan.orgE<gt>

=head1 SEE ALSO

perl(1), POE::Filter::Asterisk::Manager, L<http://aefirion.org/>, L<http://asterisk.org/>,
L<http://teknikill.net/>

=cut
