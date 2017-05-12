#!/usr/bin/perl

use warnings;
use strict;

# this is for my dev lib
use lib qw(../lib);

use Symbol qw(gensym);
use POE;
use POE::Component::Client::MSN;

our $VERSION = (qw($Revision: 1.3 $))[1];

my %config;
my %sn;

select(STDERR); $| = 1;
select(STDOUT); $| = 1;

if (-e "$ENV{HOME}/.msnconfig") {
	if (open(FH,"$ENV{HOME}/.msnconfig")) {
		my @t = <FH>;
		chomp(@t);
		foreach (@t) {
			my ($k,$v) = split(/=/);
			$config{$k} = $v;
		}
		close(FH);
	}
}

unless ($config{username} && $config{password}) {
	print "You must create $ENV{HOME}/.msnconfig and put:\n";
	print "username=<your msn/hotmail user name>\n";
	print "password=<your password>\n";
	print "files_dir=/path/to/files\n";
	print "admin_user=<another msn/hotmail user name>\n";
	print "all_chat_talk_me=<another msn/hotmail user name>\n";
	print "The last option is optional, when somone talks to the bot,\n";
	print "it auto invites this person\n";
	exit;
}

# spawn MSN session
POE::Component::Client::MSN->spawn(Alias => 'msn');

POE::Session->create(
	inline_states => {
		_start         => \&start_guts,
		_default       => \&print_to_window,
		registered => sub {
			my ($kernel, $data) = @_[KERNEL, ARG0];
			print "Connecting\n";
		
			$kernel->post($data => connect => {
				username => $config{username},
				password => $config{password},
			});
		},
		msn_got_message => \&msn_got_message,
		msn_got_typing_user => \&msn_got_typing_user,
		msn_file_request => \&msn_file_request,
		msn_chat_socket_closed => \&msn_chat_socket_closed,
		msn_chat_socket_opened => \&msn_chat_socket_opened,
		msn_out_chat_opened => \&msn_out_chat_opened,
		msn_file_data_stream => \&msn_file_data_stream,
		msn_chat_debug => \&msn_chat_debug,
		msn_file_send => \&msn_file_send,
		msn_file_cancel => \&msn_file_cancel,
		msn_file_stream => \&msn_file_stream,
		msn_disconnected => sub {
				# put reconnect code here
		},
		msn_chat_bye => sub {
			my ($kernel, $data) = @_[KERNEL, ARG0];
			eval {
				my $id = $data->{session_id};
				my $name = $data->{command}->args->[0];
				foreach my $k (keys %sn) {
					if ($sn{$k}{email} eq $name) {
						$name = $sn{$k}{nick}." <".$name.">";
						last;
					}
				}
				print "$name left the conversation\n";
				foreach my $k (keys %sn) {
					#if ($k != $id) {
						$kernel->post($k => send_message => "(co) $name left the conversation");
					#}
				}
			};
			print "$@\n" if ($@);
		},
		msn_chat_start => sub {
			my ($kernel, $data) = @_[KERNEL, ARG0];
			eval {
				my $id = $data->{session_id};
				my $name = $data->{command}->args->[3]." <".$data->{command}->args->[2].">";
				print "$name joined the conversation\n";
				$sn{$id}{nick} = $data->{command}->args->[3];
				$sn{$id}{email} = $data->{command}->args->[2];
				foreach my $k (keys %sn) {
					if ($k != $id) {
						$kernel->post($k => send_message => "(co) $name joined the conversation",2);
					}
				}
			};
			print "$@\n" if ($@);
		},
		msn_chat_join => sub {
			my ($kernel, $data) = @_[KERNEL, ARG0];
			eval {
				my $id = $data->{session_id};
				my $name = $data->{command}->args->[1]." <".$data->{command}->args->[0].">";
				print "$name joined the conversation\n";
				$sn{$id}{nick} = $data->{command}->args->[1];
				$sn{$id}{email} = $data->{command}->args->[0];
				foreach my $k (keys %sn) {
					if ($k != $id) {
						$kernel->post($k => send_message => "(co) $name joined the conversation",2);
					}
				}
			};
			print "$@\n" if ($@);
		},
		msn_chat_nak => sub {
			my ($kernel, $data) = @_[KERNEL, ARG0];
			eval {
				my $id = $data->{session_id};
				print "Message couldn't be delivered on session $id\n";
				delete $sn{$id};
			};
			print "$@\n" if ($@);
		},
		msn_chat_ring => sub {
			my ($kernel, $command) = @_[KERNEL, ARG0];
			my $name = $command->args->[4]." <".$command->args->[3].">";
			print "$name is trying to talk to me\n";
			$kernel->post(msn => accept_call => $command);
		},
		msn_got_NLN => sub {
			my ($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
			my $obj = $command->args->[4];
			if ($obj) {
#				print urldecode($obj));
			}
		},
		msn_got_ADD => sub {
			my ($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
# broken
#			eval {
#				require Data::Dumper;
#				print Data::Dumper->Dump([\$command],['command']);
#				
#				if ($command->args->[0] eq 'RL') {
#					$kernel->post(msn => "put", "ADD", 'AL '.$command->args->[2].' '.$command->args->[3]);
#					$kernel->post(msn => "put", "ADD", 'FL '.$command->args->[2].' '.$command->args->[3]);
#				} else {
#					print "unhandled ADD ".$command->args->[0]."\n";
#				}
#			};
#			if ($@) {
#				print "$@\n";
#			}
		},
		'die' => sub {
				die;
		},
	}
);

$poe_kernel->run();

exit;

sub msn_file_data_stream {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

	# TODO this is crap, keep an open file handle, and do some kind of timeout checking
	eval {
		if (exists($data->{eof})) {
			# eof!
		} else {
			if ($data->{stream}) {
				open(FH, ">>$config{files_dir}/".$data->{file_name});
				binmode(FH);
				print FH $data->{stream};
				close(FH);
			}
		}
	};
	print "$@" if ($@);
}

sub msn_chat_socket_opened {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
	
	my $id = $data->{session_id};
	
	$sn{$id}{debug} = 0;
	
	my $command = \$data->{command};
	
	print " session opened: $id";

	eval {
		$sn{$id}{email} = $data->{buddy_email};
		$sn{$id}{nick} = $data->{buddy_nick};
	};
	if ($@) {
		print "$@\n";
	}

	my $msg = "Hello there, I'm an MSN bot written in perl using POE::Component::Client::MSN by David Davis [mailto:xantus\@cpan.org]\r\nYou are currently in conference mode.";

	$kernel->post($id => send_message => "$msg\r\n(co) Type .help for a list of commands",1);

	if ($config{all_chat_talk_me}) {
		if ($sn{$id}{email} ne lc($config{all_chat_talk_me})) {
			my $found = 0;
			foreach my $k (keys %sn) {
				if ($sn{$k}{email} eq lc($config{all_chat_talk_me})) {
					$found = 1;
					last;
				}
			}
			unless ($found == 1) {
				$kernel->post(msn => talk_user => $config{all_chat_talk_me});
			}
		}
	}
}

sub msn_out_chat_opened {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
	
	my $id = $data->{session_id};
	
	$sn{$id}{debug} = 0;

	my $command = \$data->{command};
	
	print " session opened: $id\n";
}

sub msn_chat_socket_closed {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

	my $id = $data->{session_id};
	
	delete $sn{$id};
}

sub msn_file_request {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
	
	my $id = $data->{session_id};
	
	eval {
		$sn{$id}{test} = 1;
		
		print "File transfer request from session: $id\n";
	
		my $file = $data->{fields}{'Application-File'};
		
		my $msg = '';
		if (-e "$config{files_dir}/$file") {
			$kernel->post($id => send_cancel_invite => $data->{command});
			$kernel->post($id => send_message => "(co) What am I going to do with this file? I already have it!");
			$msg = ", but I already have this one.";
		} else {
			$kernel->post($id => accept_file => $data );
		}
	
		foreach my $k (keys %sn) {
			if ($k != $id) {
				$kernel->post($k => send_message => "(co) $sn{$id}{nick} <$sn{$id}{email}> is sending me a file: $file$msg");
			}
		}
	};
	if ($@) {
			print "$@\n";
	}
}

sub msn_file_cancel {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
	
	my $id = $data->{session_id};
	if ($data->{for_session_id}) {
		$id = $data->{for_session_id};
		if ($sn{$id}{file_send} && $sn{$id}{file_send}{file_handle}) {
			close($sn{$id}{file_send}{file_handle});
		}
	}
	
	print "File transfer canceled on session $id\n";

	delete $sn{$id}{file_send};
}

# NOT called anymore
sub msn_file_send {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
	
	my $id = $data->{session_id};
	
	eval {
		$sn{$id}{test} = 1;
		
		print "File transfer accepted from session $id\n";

		unless ($sn{$id}{file_send}) {
				print "file_send on invalid session\n";
				return;
		}
	
		my $file = $sn{$id}{file_send}{name};
	
		if (-e "$sn{$id}{file_send}{path}") {
			$kernel->post($id => accept_send => $data );		
		} else {
			$kernel->post($id => send_cancel_invite => $data->{command});
			$kernel->post($id => send_message => "(co) File not found");
		}
	
		foreach my $k (keys %sn) {
			if ($k != $id) {
				$kernel->post($k => send_message => "(co) Sending $file to $sn{$id}{nick} <$sn{$id}{email}>");
			}
		}
	};
	if ($@) {
			print "$@\n";
	}
}

sub msn_file_stream {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
	
	eval {
		my $id = $data->{for_session_id};

		unless ($sn{$id}{file_send}) {
			# we get here on the final flush
			#print "NO file_send for $id\n";
			return;
		}

		unless ($sn{$id}{file_send}{file_handle}) {
			my $file_handle = $sn{$id}{file_send}{file_handle} = gensym();
			open($file_handle,"<".$sn{$id}{file_send}{path}) or do {
				$kernel->post($id => send_message => "(co) Send failed: $!");
				#$kernel->post($id => send_cancel_invite => $data->{command});
				return;
			};
			binmode($file_handle);
			foreach my $k (keys %sn) {
				if ($k != $id) {
					$kernel->post($k => send_message => "(co) Sending $sn{$id}{file_send}{name} to $sn{$id}{nick} <$sn{$id}{email}>");
				}
			}	
		}

		my $bytes_read = sysread($sn{$id}{file_send}{file_handle}, my $buffer = '', 2045);
		if ($bytes_read) {
			$sn{$id}{file_send}{bytes_sent} += $bytes_read;
			$data->{sock}->put({ stream => $buffer});
		} else {
			close($sn{$id}{file_send}{file_handle});
			print $sn{$id}{file_send}{bytes_sent}." Total bytes sent\n";
			delete $sn{$id}{file_send};
			$data->{sock}->put({ eof => 1 });
#			$kernel->post($data->{session_id} => 'send_bye');
		}
	};
	if ($@) {
		print "$@\n";
	}
}

sub msn_chat_debug {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
	
	my $id = $data->{session_id};
	
	$sn{$id}{debug} = 0 || $sn{$id}{debug};
	
	unless ($data->{command}) {
			print "no cmd in debug call\n";
			return;
	}
	
	my $command = \$data->{command};
	
	require Data::Dumper;
	my $dumped = Data::Dumper->Dump([\$command],['cmd']);
	$dumped =~ s/\n/\\n/g;
	
	foreach my $k (keys %sn) {
		if ($sn{$k}{debug} == 1) {
			$kernel->post($k => send_message => $id."-debug>$dumped");
		}
	}
}

sub msn_got_typing_user {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
	
	my $id = $data->{session_id};

	$sn{$id}{test} = 1;

	foreach my $k (keys %sn) {
		print "Typing $data->{typing_user}\n";
		if ($k != $id) {
			$kernel->post($k => 'typing_user');
		}
	}
	
	return;
}

sub msn_got_message {
	my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
	
	my $id = $data->{session_id};

	$sn{$id}{test} = 1;
	
	my $command = \$data->{command};
	$sn{$id}{email} = $data->{command}->args->[0];
	$sn{$id}{nick} = $data->{command}->args->[1];
	
	print $data->{command}->args->[1].">".join('\r\n',@{$data->{command}->{message}->{mail_inet_body}})."\n";
	
#	require Data::Dumper;
#	print Data::Dumper->Dump([$command]));
	
	my $msg = join("\r\n",@{$data->{command}->{message}->{mail_inet_body}});
	if ($msg =~ m/^\.([^\s]+)\s?(.*)?/) {
		my $cmd = lc($1);
		my $par = $2;
		#$kernel->post($id => send_message => $data->{command}->args->[1]." (to yourself)>$msg [$cmd] [$par]");
		if ($cmd eq 'help') {
			$kernel->post($id => send_message => "(co) Help\r\n.who\t\tShows who is here\r\n.invite <email>\tTries to invite that person to chat\r\n.uninvite <email>\tCloses chat with person\r\n.ls\t\t\tList files I have\r\n.dir\t\t\tSame as .ls\r\n.get <file>\t\tGet a file that I have (broken)");
			return;
		} elsif ($cmd eq 'who') {
			eval {
			my @list;
			foreach my $k (keys %sn) {
					if ($k != $id) {
						if (exists($sn{$k}{nick})) {
							push(@list,$sn{$k}{nick}."[".$sn{$k}{email}."]");
						} else {
							delete $sn{$k};
						}
					}
			}
			if (@list) {
				$kernel->post($id => send_message => "(co) There are ".scalar(@list)." people in the room: ".join(',',@list));
			} else {
				$kernel->post($id => send_message => "(co) There's noone here");
			}
			};
			if ($@) {
					print "$@\n";
			}
		} elsif ($cmd eq 'invite') {
			if ($par =~ m/\@/) {
					$kernel->post($id => send_message => "(co) Inviting $par");
					foreach my $k (keys %sn) {
							if ($k != $id) {
								$kernel->post($k => send_message => "(co) $sn{$id}{nick} <$sn{$id}{email}> is inviting $par");
							}
					}
					$kernel->post(msn => talk_user => "$par");
			} else {
					$kernel->post($id => send_message => "(co) That doesn't look like an email address");
			}
		} elsif ($cmd eq 'uninvite') {
			if ($par =~ m/\@/) {
					$kernel->post($id => send_message => "(co) UnInviting $par");
					my $found = 0;
					foreach my $k (keys %sn) {
							if ($sn{$k}{email} eq lc($par)) {
									$found = $k;
							}
#							if ($k != $id) {
#								$kernel->post($k => send_message => "(co) $sn{$id}{nick} <$sn{$id}{email}> is Uninviting $par");
#							}
					}
					if ($found == 0) {
						$kernel->post($id => send_message => "(co) That person isn't here");
						return;
					}
					$kernel->post($found => 'disconnect');
			} else {
					$kernel->post($id => send_message => "(co) That doesn't look like an email address");
			}
		} elsif ($cmd eq 'call') {
			if ($par =~ m/\@/) {
					$kernel->post($id => send_message => "(co) Calling $par");
					$kernel->post($id => invite_user => "$par");
			} else {
					$kernel->post($id => send_message => "(co) That doesn't look like an email address");
			}
		} elsif ($cmd eq 'debug' && $data->{command}->args->[0] eq lc($config{admin_user})) {
			$sn{$id}{debug} = ($par eq '1') ? 1 : 0;
			$kernel->post($id => send_message => "(co) Debug: $sn{$id}{debug}");
		} elsif ($cmd eq 'snd' && $data->{command}->args->[0] eq lc($config{admin_user})) {
			$kernel->post($id => send_message => "(co) Sending $par");
			$kernel->post(msn => put => split(/\s/,$par));
		} elsif ($cmd eq 'die' && $data->{command}->args->[0] eq lc($config{admin_user})) {
			$kernel->post($id => send_message => "(co) Ohhh, the humanity! Goodbye cruel world!");
			foreach my $k (keys %sn) {
				if ($k != $id) {
					$kernel->post($k => send_message => "(co) Oh crap, I'm dieing!");
				}
			}
			$kernel->delay('die' => 3);
		} elsif ($cmd eq 'get') {
			$par =~ s/\.{2,}//g;
			$par = "$config{files_dir}/$par";
			unless (-e $par) {
				$kernel->post($id => send_message => "(co) $par does not exist");
				return;
			}
			my $size = (-s $par);
			my $file_name = $par;
			$file_name =~ s#.*/(.+)$#$1#;

			print "sending file: $file_name size:$size\n";
			
			$kernel->post($id => send_message => "(co) Sending file $file_name Size:$size bytes");
			
			$kernel->post($id => send_file => { file_name => $file_name, file_size => $size });
			$sn{$id}{file_send}{path} = $par;
			$sn{$id}{file_send}{name} = $file_name;
		} elsif ($cmd eq 'ls' || $cmd eq 'dir') {
			my $ls = '';
			opendir(DIR,"$config{files_dir}/");
			while (my $d = readdir(DIR)) {
				next if ($d =~ m/^\./);
				my $size = (-s "$config{files_dir}/$d");
				$ls .= "$size\t\t$d\r\n";
			}
			closedir(DIR);
			$ls = "No files" if ($ls eq '');
			$kernel->post($id => send_message => $ls);
		} else {
			$kernel->post($id => send_message => "(co) Unknown Command");
		}
	} else {
		foreach my $k (keys %sn) {
			if ($k != $id) {
#				$kernel->post($k => 'typing_user');
				$kernel->post($k => send_message => $data->{command}->args->[1].">$msg");
			}
		}
	}
}

sub start_guts {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->post(msn => 'register');
}

sub print_to_window {
	my ($kernel, $heap, $arg0) = @_[KERNEL, HEAP, ARG0];

	print "::$arg0\n";

	return undef;
}

####################################
# Not Events
####################################

sub urlencode {
	my $i = shift;
	$i =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
	return $i;
}

sub urldecode {
	my $i = shift;
	$i =~ s/%{..}/chr(ord($1))/eg;
	return $i;
}

