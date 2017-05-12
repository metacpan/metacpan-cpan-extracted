package POE::TIKC;
# (c) Copyright 2004, David Davis

use POE qw( Filter::Reference Component::Server::TCP Component::Client::TCP );

use strict;
#use warnings FATAL => "all";

#$|++;

our $VERSION = '0.02';

sub DEBUG { 0 }

# the client and server use this hash
our %clients;
#{
#	tcp session id => {
#		alias => mock session id,
#		alias2 => another mock session id,
#	}
#}

our $connected = 0;

POE::Session->create(
	heap => {
		alias =>'_tikc_manager',
	},
	package_states => [
		'POE::TIKC' => [qw(
			_start
			shutdown
			create_session
			alias_list
		)],
	],
);

sub _start {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->alias_set($heap->{alias});
#	$kernel->delay_set(alias_list => 5);
}

sub shutdown {
	return if ($_[HEAP]->{shutdown});
	$_[HEAP]->{shutdown} = 1;
	foreach my $c (keys %clients) {
		$_[KERNEL]->call($c => 'shutdown');
	}
	$_[KERNEL]->call('_tikc_server' => 'shutdown');
	$_[KERNEL]->call('_tikc_client' => 'shutdown');
}

sub alias_list {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
			
	my @aliases;
	my $kr_sessions = $POE::Kernel::poe_kernel->[POE::Kernel::KR_SESSIONS];
	foreach my $key ( keys %$kr_sessions ) {
		next if $key =~ /POE::Kernel/;
		foreach my $a ($kernel->alias_list($kr_sessions->{$key}->[0])) {
			#next if ($a =~ m/^_tikc/);
			push(@aliases,$a);
		}
	}
	DEBUG && print "(s) aliases: ".join(',',@aliases)."\n";
	$kernel->delay_set(alias_list => 5);
}

sub create_session {
	my ($sid, $alias) = @_[ARG0,ARG1];					
	return if ($_[HEAP]->{shutdown});
	return POE::Session->create(
		heap => {
			_tikc_proxy_session => 1,
			client => $sid,
			alias => $alias,
		},
		inline_states => {
			_start => sub {
				DEBUG && print "proxy session ".$_[SESSION]->ID." startup as ".$_[HEAP]->{alias}."\n";
				$_[KERNEL]->alias_set($_[HEAP]->{alias});
			},
			_i_k_c_shutdown => sub {
				$_[HEAP]->{shutdown} = 1;
				DEBUG && print "proxy session ".$_[SESSION]->ID." shutdown called\n";
				$_[KERNEL]->alias_remove($_[HEAP]->{alias});
			},
			_stop => sub {
				DEBUG && print "proxy session ".$_[SESSION]->ID." stopped\n";
			},
			_default => sub {
				return undef if ($_[ARG0] =~ /^_signal/);
				return if ($_[HEAP]->{shutdown});
				DEBUG && print "(sp) calling $_[ARG0] in remote alias: $_[HEAP]->{alias} through proxy\n";
				$_[KERNEL]->call($_[HEAP]->{client} => _tikc_send => {
					action => 'post',
					event => $_[ARG0],
					alias => $_[HEAP]->{alias},
					args => splice(@_,ARG1),
				});
			},
		},
	)->ID;
}

sub create_server {
	my $class = shift;
	my $opt = shift || {};
	
	POE::Component::Server::TCP->new(
		Alias			=> "_tikc_server",
		Address			=> $opt->{address} || "127.0.0.1",
		Port			=> $opt->{port} || 2021,
		ClientFilter	=> "POE::Filter::Reference",
		ClientDisconnected => sub {
			my ($kernel,$sid) = ($_[KERNEL],$_[SESSION]->ID);
			if (ref($clients{$sid}) eq 'HASH') {
				my @aliases;
				foreach my $a (keys %{$clients{$sid}}) {
					# $a is an alias
					# value is a session id
					$kernel->call($clients{$sid}->{$a} => '_i_k_c_shutdown');
					push(@aliases, $a);
				}
				if (@aliases) {
					foreach my $c (keys %clients) {
						# skip the exiting client
						next if ($c == $sid);
						$kernel->call($c => _tikc_send => { type => 'server', action => 'remove', aliases => \@aliases });
					}
				}
			}
			delete $clients{$sid};
			$connected = 0;
			DEBUG && print "Client Disconnected!\n";
		},
		ClientShutdownOnError => 1,
		ClientError => sub {
			my ($kernel,$sid) = ($_[KERNEL],$_[SESSION]->ID);
			# shouldn't client error ALWAYS call client disconnected?
			if (ref($clients{$sid}) eq 'HASH') {
				my @aliases;
				foreach my $a (keys %{$clients{$sid}}) {
					# $a is an alias
					# value is a session id
					$kernel->call($clients{$sid}->{$a} => '_i_k_c_shutdown');
					push(@aliases, $a);
				}
				if (@aliases) {
					foreach my $c (keys %clients) {
						# skip the exiting client
						next if ($c == $sid);
						$kernel->call($c => _tikc_send => { type => 'server', action => 'remove', aliases => \@aliases });
					}
				}
			}
			delete $clients{$sid};
			$connected = 0;
			DEBUG && print "Client Error, disconnected: $_[ARG2]\n";
		},
		ClientConnected => sub {
			my ($kernel,$heap) = @_[KERNEL, HEAP];
			
			DEBUG && print "Client Connected!\n";
			# TODO put a timer here to disconnect clients that
			# don't auth before 15 seconds
			
			# tell the client what aliases the server already knows
			my %aliases;
			my $kr_sessions = $POE::Kernel::poe_kernel->[POE::Kernel::KR_SESSIONS];
			foreach my $key ( keys %$kr_sessions ) {
				next if $key =~ /POE::Kernel/;
				foreach my $a ($kernel->alias_list($kr_sessions->{$key}->[0])) {
					# skip over internal sessions
					next if ($a =~ m/^_tikc/);
					my $h = $kr_sessions->{$key}->[0]->get_heap();
					next if (ref($h) eq 'HASH' && $h->{_tikc_proxy_session});
					$aliases{$a}++;
				}
			}
			# tell this client about sessions that we know about from other clients
			foreach my $a (keys %clients) {
				foreach my $k (keys %{$clients{$a}}) {
					$aliases{$k}++;
				}
			}
			DEBUG && print "(s) sending  aliases: ".join(',',keys %aliases)."\n";
			$kernel->call($_[SESSION] => _tikc_send => { type => 'client', action => 'setup', aliases => [keys %aliases] });
		},
		ClientInput => \&input,
		InlineStates => {
			_tikc_send => sub {
				my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

				if ($heap->{client}) {
					DEBUG && print "(s) sending data to ".$_[SESSION]->ID."\n";
					$heap->{client}->put($data);
				} else {
					DEBUG && print "(s) data sent to client ".$_[SESSION]->ID." ignored\n";
				}
			},
		},
	);
}

sub create_client {
	my $class = shift;
	my $opt = shift || {};
	
	POE::Component::Client::TCP->new(
		Alias			=> "_tikc_client",
		RemoteAddress	=> $opt->{address} || "127.0.0.1",
		RemotePort		=> $opt->{port} || 2021,
		Filter			=> "POE::Filter::Reference",
		ConnectError => sub {
			my ($kernel,$sid) = ($_[KERNEL],$_[SESSION]->ID);
			
			$kernel->delay_set(reconnect => 2);
			
			if (ref($clients{$sid}) eq 'HASH') {
				foreach my $a (keys %{$clients{$sid}}) {
					# $a is an alias
					# value is a session id
					$kernel->call($clients{$sid}->{$a} => '_i_k_c_shutdown');
				}
			}
			
			delete $clients{$sid};
			$connected = 0;
			DEBUG && print "Connect error, $_[ARG2]\n";
		},
		Disconnected => sub {
			my ($kernel,$sid) = ($_[KERNEL],$_[SESSION]->ID);
	
			$kernel->delay_set(reconnect => 2);
			
			if (ref($clients{$sid}) eq 'HASH') {
				foreach my $a (keys %{$clients{$sid}}) {
					# $a is an alias
					# value is a session id
					$kernel->call($clients{$sid}->{$a} => '_i_k_c_shutdown');
				}
			}
			
			delete $clients{$sid};
			$connected = 0;	
			DEBUG && print "Disconnected! Reconnecting...\n";
		},
		Connected => sub {
			my ($kernel,$heap) = @_[KERNEL, HEAP];
	
			DEBUG && print "Connected!\n";
			# tell the server what aliases we have
			my @aliases;
			my $kr_sessions = $POE::Kernel::poe_kernel->[POE::Kernel::KR_SESSIONS];
			foreach my $key ( keys %$kr_sessions ) {
				next if $key =~ /POE::Kernel/;
				foreach my $a ($kernel->alias_list($kr_sessions->{$key}->[0])) {
					# skip over internal sessions
					next if ($a =~ m/^_tikc/);
					my $h = $kr_sessions->{$key}->[0]->get_heap();
					next if (ref($h) eq 'HASH' && $h->{_tikc_proxy_session});
					push(@aliases,$a);
				}
			}
			push(@aliases, map { keys %{$clients{$_}} } %clients);
			DEBUG && print "(c) sending  aliases: ".join(',',@aliases)."\n";
			$kernel->call($_[SESSION] => _tikc_send => { type => 'server', action => 'setup', aliases => \@aliases });
		},
		ServerInput => \&input,
		InlineStates => {
			_tikc_send => sub {
				my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

				if ($heap->{server}) {
					DEBUG && print "(c) sending data to ".$_[SESSION]->ID."\n";
					$heap->{server}->put($data);
				} else {
					DEBUG && print "(c) data sent to server ".$_[SESSION]->ID." ignored\n";
				}
			},
		},
	);
}

sub input {
	my ( $heap, $kernel, $data ) = @_[ HEAP, KERNEL, ARG0 ];

	if (ref($data) eq 'HASH') {
		if (exists($data->{action})) {
			if ($data->{action} eq 'post') {
				# if this session isn't a 'real' session
				# _default of our mock session forwards it to the server
				DEBUG && print "(i) searching for == $data->{alias} ==\n";
				my $sr = $kernel->alias_resolve($data->{alias});
				if (ref($sr)) {
					my $h = $sr->get_heap();
					DEBUG && print "(i) posting to $data->{alias}\n";
					if (@{$data->{args}}) {
						$kernel->call($sr => $data->{event} => @{$data->{args}});
					} else {
						$kernel->call($sr => $data->{event});
					}
				} else {
					# XXX notify client?
					DEBUG && print "(i) client posted to invalid alias $data->{alias}, ignoring\n";
				}
			} elsif ($data->{action} eq 'setup') {
				foreach my $i (@{$data->{aliases}}) {
					my $sr = $kernel->alias_resolve($i);
					if (ref($sr)) {
						warn "Session (alias $i) already exists as session_id: ".$sr->ID."\n";
						my $h = $sr->get_heap();
						if (ref($h) eq 'HASH' && $h->{_tikc_proxy_session}) {
							warn "!!!! it is a tikc proxy session, I'll use that session\n";
							$clients{$_[SESSION]->ID}->{$i} = $sr->ID;
						}
					} else {
						DEBUG && print "(i) creating proxy session for remote alias $i\n";
						my $sid = $_[SESSION]->ID;
						# create a client key with the session id

						$clients{$sid}->{$i} = $kernel->call(_tikc_manager => 'create_session' => $sid => $i);

						DEBUG && do {
							require Data::Dumper;
							print Data::Dumper->Dump([\%clients]);
						};
					}
				}
				foreach my $c (keys %clients) {
					next if ($c == $_[SESSION]->ID);
					$kernel->call($c => _tikc_send => {
						action => 'setup',
						aliases => $data->{aliases},
					});
				}
				# we're considered connected after the first setup command
				$connected = 1;
			} elsif ($data->{action} eq 'remove') {
				my $sid = $_[SESSION]->ID;
				DEBUG && print "(i) I was told me to remove aliases: ".join(',',@{$data->{aliases}})."\n";
				foreach my $a (@{$data->{aliases}}) {
					if (exists($clients{$sid}->{$a})) {
						DEBUG && print "(i) shutting down session $clients{$sid}->{$a}\n";
						$kernel->call($clients{$sid}->{$a} => '_i_k_c_shutdown');
					}
				}
			}
		} else {
			DEBUG && print "Received response from TIKC without action\n";
		}
	} else {
		DEBUG && print "Received an unknown response from TIKC type: ", ref($data)."\n";
	}
}

1;

__END__

=head1 NAME

POE::TIKC - Transparent Inter-Kernel Communication (IKC)

=head1 SYNOPSIS

	use POE qw(TIKC);

	POE::TIKC->create_server({
		address => '127.0.0.1',	# default
		port => '2021',			# default
	});

# You can now assume all connected clients' aliases are available
# AFTER...you check if $POE::TIKC::connected == 1 before starting.

=head1 DESCRIPTION

This module connects many clients to one server and creates proxy sessions
in the client and the server for all aliases.  When you post to a proxied
session, it is sent to the right client and reposted there.

=head1 BUGS

Probably, its not fully tested.  So use this at your own risk of life and data.

=head1 FEATURES

You can't post globs

You can't use session ids

You must check $POE::TIKC::connected == 1 before posting events until I can
fix this by queueing the posts until a connection is made

You must make sure Storable is the same version on all machines using TIKC

Using $_[SENDER] for anything would be bad

Using call() instead of post will not return usefull info from the remote
kernel

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by David Davis and Teknikill Software

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
