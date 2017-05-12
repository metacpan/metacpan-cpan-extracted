package POE::Component::Client::MSN;

# vim:set ts=4

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use vars qw($Default);
$Default = {
    port => 1863,
    hostname => 'messenger.hotmail.com',
};
use Time::HiRes;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW Filter::Line Filter::Stream
	   Filter::MSN Component::Client::HTTP Component::Server::TCP);
use Symbol qw(gensym);

use POE::Component::Client::MSN::Command;
use HTTP::Request;
use Digest::MD5;
use Socket;
use URI::Escape ();

sub spawn {
    my($class, %args) = @_;
    $args{Alias} ||= 'msn';

    # session for myself
    POE::Session->create(
		inline_states => {
		    _start => \&_start,
		    _stop  => \&_stop,
	
		    # internals
		    _sock_up   => \&_sock_up,
		    _sock_down => \&_sock_down,
		    _sb_sock_up => \&_sb_sock_up,
		    _unregister => \&_unregister,
	
		    # API
		    notify     => \&notify,
		    register   => \&register,
		    unregister => \&unregister,
		    connect    => \&connect,
		    login      => \&login,
		    put	       => \&put,
	
		    filter_debug => sub {
				my $arg = $_[ARG0];
				$POE::Filter::MSN::Debug = $arg;
		    },

		    handle_event => \&handle_event,
	
		    # commands
		    VER => \&got_version,
		    CVR => \&got_client_version,
		    CHG => \&got_change_status,
		    XFR => \&got_xfer,
		    USR => \&got_user,
		    #			ILN => \&got_goes_online,
		    #			# user change status to online
		    NLN => \&handle_common,
		    FLN => \&handle_common,
		    # start chat session
		    RNG => \&got_ring,
		    # got a message
		    MSG => \&handle_common,
		    # challenge
		    CHL => \&got_challenge,
		    QRY => \&handle_common,
		    # sync
		    SYN => \&got_synchronization,
		    # group list
		    LSG => \&got_group,
		    # buddy list
		    LST => \&got_list,
			# buddy added you to thier list
			ADD => \&handle_common,
			# buddy removed you from thier list
			REM => \&handle_common,
			# signed in at other location, or going down for maintenance
			#			UOT => \&got_kicked,
			#			OUT => \&got_kicked,
	
			# states
			got_1st_response => \&got_1st_response,
			passport_login   => \&passport_login,
			got_2nd_response => \&got_2nd_response,
			accept_call => \&accept_call,
			talk_user => \&talk_user,
		},
		args => [ \%args ],
    );

    # HTTP cliens session
    POE::Component::Client::HTTP->spawn(Protocol => 'HTTP/1.1', Agent => 'MSN Session', Alias => 'ua');
}

sub _start {
    $_[KERNEL]->alias_set($_[ARG0]->{Alias});
    $_[HEAP]->{transaction} = 0;
}

sub _stop { }

sub register {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->refcount_increment($sender->ID, __PACKAGE__);
    $heap->{listeners}->{$sender->ID} = 1;
    $kernel->post($sender->ID => "registered" => $_[SESSION]->ID);
}


sub unregister {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->yield(_unregister => $sender->ID);
}

sub _unregister {
    my($kernel, $heap, $session) = @_[KERNEL, HEAP, ARG0];
    $kernel->refcount_decrement($session, __PACKAGE__);
    delete $heap->{listeners}->{$session};
}

sub notify {
    my($kernel, $heap, $name, $data) = @_[KERNEL, HEAP, ARG0, ARG1];
    #	$data ||= POE::Component::Client::MSN::Event::Null->new;
    #	$kernel->post($_ => "msn_$name" => $data->args) for keys %{$heap->{listeners}};
    $kernel->post($_ => "msn_$name" => $data) for keys %{$heap->{listeners}};
}

sub connect {
    my($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
    # set up parameters
    $heap->{$_} = $args->{$_} for qw(username password);
    $heap->{$_} = $args->{$_} || $Default->{$_} for qw(hostname port);

    return if $heap->{sock};
    $heap->{sock} = POE::Wheel::SocketFactory->new(
		SocketDomain => AF_INET,
		SocketType => SOCK_STREAM,
		SocketProtocol => 'tcp',
		RemoteAddress => $heap->{hostname},
		RemotePort => $heap->{port},
		SuccessEvent => '_sock_up',
		FailureEvent => '_sock_failed',
    );
}

sub _sock_up {
    my($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
    # new ReadWrite wheel for the socket
    $heap->{sock} = POE::Wheel::ReadWrite->new(
		Handle => $socket,
		Driver => POE::Driver::SysRW->new,
		Filter => POE::Filter::MSN->new,
		ErrorEvent => '_sock_down',
    );
    $heap->{sock}->event(InputEvent => 'handle_event');
    $heap->{sock}->put(
		POE::Component::Client::MSN::Command->new(VER => "MSNP9 CVR0" => $heap),
    );
    $kernel->yield(notify => 'connected');
}

sub _sock_failed {
    my($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->yield(notify => socket_error => ());
    for my $session (keys %{$heap->{listeners}}) {
		$kernel->yield(_unregister => $session);
    }
}

sub _sock_down {
    my($kernel, $heap) = @_[KERNEL, HEAP];
    warn "sock is down\n";
    delete $heap->{sock};
    $kernel->yield(notify => 'disconnected');
}

sub handle_event {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    if ($command->errcode) {
		warn "got error: ", $command->errcode;
		$kernel->yield(notify => got_error => $command);
    } else {
		$kernel->yield($command->name, $command);
    }
}

sub handle_common {
    my $event = $_[ARG0]->name;
    $_[KERNEL]->yield(notify => "got_$event" => $_[ARG0]);
}


sub got_version {
    $_[HEAP]->{sock}->put(
		POE::Component::Client::MSN::Command->new(CVR => "0x0409 winnt 5.1 i386 MSNMSGR 6.0.0602 MSMSGS $_[HEAP]->{username}" => $_[HEAP]),
    );
}

sub got_client_version {
    $_[HEAP]->{sock}->put(
		POE::Component::Client::MSN::Command->new(USR => "TWN I $_[HEAP]->{username}" => $_[HEAP]),
    );
}

sub got_xfer {
    my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
    if ($command->args->[0] eq 'NS') {
		@{$heap}{qw(hostname port)} = split /:/, $command->args->[1];
		# switch to Notification Server
		$_[HEAP]->{sock} = POE::Wheel::SocketFactory->new(
		    SocketDomain => AF_INET,
		    SocketType => SOCK_STREAM,
		    SocketProtocol => 'tcp',
		    RemoteAddress => $heap->{hostname},
		    RemotePort => $heap->{port},
		    SuccessEvent => '_sock_up',
		    FailureEvent => '_sock_failed',
		);
    } elsif ($command->args->[0] eq 'SB') {
		POE::Session->create(
		    inline_states => {
				_start => \&sb_start_xfr,
				_sb_sock_up => \&sb_sock_up_xfr,
				_sb_sock_down => \&sb_sock_down,
				_default => \&sb_chat_debug,
				handle_event => \&sb_handle_event,
				MSG => \&sb_got_message,
				USR => \&sb_got_user,
				send_message => \&sb_send_message,
				accept_file => \&sb_accept_file,
				send_file => \&sb_send_file,
				accept_send => \&sb_accept_send,
				typing_user	=> \&sb_send_typing_user,
				send_reject_invite => \&sb_send_reject_invite,
				send_cancel_invite => \&sb_send_cancel_invite,
				invite_user => \&sb_send_invite_user,
				disconnect => sub {
   		 			my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
					my $cmd = POE::Component::Client::MSN::Command->new(OUT => "");
					$cmd->{name_only} = 1;
					$heap->{sock}->put($cmd);
					$kernel->yield("BYE", $cmd);
				},
				put => \&put,
				_stop => \&sb_sock_down,
				BYE => sub {
   		 			my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
					$kernel->post($heap->{parent} => notify => chat_bye => { command => $command, session_id => $session->ID } ); 
				},
				NAK => sub {
   			 		my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
					$kernel->post($heap->{parent} => notify => chat_nak => { command => $command, session_id => $session->ID } );
				},
				JOI => sub {
   					my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
					$kernel->post($heap->{parent} => notify => chat_join => { command => $command, session_id => $session->ID } );
				},
				IRO => sub {
   					my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
					$kernel->post($heap->{parent} => notify => chat_start => { command => $command, session_id => $session->ID } );
				},
				_default => sub {
					my $arg = $_[ARG0];
#					my $name = $arg->name;
#					if ($arg->errname) {
#						$name .= " ".$arg->errname;
#					}
					print STDERR "XCHAT\:\:$arg\n";
					return undef;
			    },
			},
		    args => [ $command, $session->ID, $heap ],
		);
    }
}

sub got_user {
    my $event = $_[ARG0];
    if ($event->args->[1] eq 'S') {
		$_[HEAP]->{cookie} = $event->args->[2];
		my $request = HTTP::Request->new(GET => 'https://nexus.passport.com/rdr/pprdr.asp');
		$_[KERNEL]->post(ua => request => got_1st_response => $request);
		print STDERR "getting passport\n";
    } elsif ($event->args->[0] eq 'OK') {
		$_[KERNEL]->yield(notify => signin => $event);
		# set initial status
		$_[HEAP]->{sock}->put(
		    POE::Component::Client::MSN::Command->new(CHG => "NLN" => $_[HEAP]),
		);
    }
}

sub got_1st_response {
    my($request_packet, $response_packet) = @_[ARG0, ARG1];
    my $response = $response_packet->[0];
#	require Data::Dumper;
#	print Data::Dumper->Dump([$response]);
#	print STDERR "got passport 1st response\n";
	unless ($response->header('PassportURLs')) {
		print STDERR "failed to find correct header, your POE::Component::Client::HTTP is broken\n";
		return;
	}
    my $passport_url = (_fake_header($response, 'PassportURLs') =~ /DALogin=(.*?),/)[0]
	or warn $response->as_string;
    if ($passport_url) {
		print STDERR "getting https://$passport_url\n";
		$_[KERNEL]->yield(passport_login => "https://$passport_url");
    }
}

sub passport_login {
    my $passport_url = $_[ARG0];
    my $request = HTTP::Request->new(GET => $passport_url);
    my $sign_in  = URI::Escape::uri_escape($_[HEAP]->{username});
    my $password = URI::Escape::uri_escape($_[HEAP]->{password});
    $request->header(Authorization => "Passport1.4 OrgVerb=GET,OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom,sign-in=$sign_in,pwd=$password,$_[HEAP]->{cookie}");
    $_[KERNEL]->post(ua => request => got_2nd_response => $request);
}

sub got_2nd_response {
    my($request_packet, $response_packet) = @_[ARG0, ARG1];
    my $response = $response_packet->[0];
    #	my $auth_info = $response->header('Authentication-Info');
    my $auth_info = _fake_header($response, 'Authentication-Info');
	print STDERR "got 2nd response: $auth_info $response->{_content} \n";
    if ($auth_info =~ /da-status=redir/) {
		my $new_location = _fake_header($response, 'Location');
		print STDERR "redirecting to $new_location\n";
		$_[KERNEL]->yield(passport_login => $new_location);
    } elsif ($auth_info =~ /PP='(.*?)'/) {
		my $credential = $1;
		$_[HEAP]->{sock}->put(
		    POE::Component::Client::MSN::Command->new(USR => "TWN S $credential" => $_[HEAP]),
		);
    }
}

sub _fake_header {
    my($response, $key) = @_;
    # seems to be a bug. it's in body
    return $response->header($key) || ($response->content =~ /^$key: (.*)$/m)[0];
}

sub got_challenge {
    my $challenge = $_[ARG0]->args->[0];
    my $response = sprintf "%s %d\r\n%s",'msmsgs@msnmsgr.com', 32, Digest::MD5::md5_hex($challenge . "Q1P7W2E4J9R8U3S5");
    $_[HEAP]->{sock}->put(
		POE::Component::Client::MSN::Command->new(QRY => $response => $_[HEAP], 1),
    );
}

sub got_change_status {
    if ($_[ARG0]->args->[0] eq 'NLN') {
	# normal status
	my $cl_version = $_[HEAP]->{CL_version} || 0;
	$_[HEAP]->{sock}->put(
	    POE::Component::Client::MSN::Command->new(SYN => $cl_version => $_[HEAP]),
	);
    }
}

sub got_synchronization {
    my($version, $lst_num, $lsg_num) = $_[ARG0]->args;
    if (!$_[HEAP]->{CL_version} || $version > $_[HEAP]->{CL_version}) {
	#		warn "synchronize CL version to $version";
	$_[HEAP]->{CL_version} = $version;
	$_[KERNEL]->yield(notify => 'got_synchronization' => $_[ARG0]);
    }
}

sub got_list {
    my($account, $screen_name, $listmask, $groups) = $_[ARG0]->args;
    my @groups = split /,/, $groups;
    $_[HEAP]->{buddies}->{$account} = {
		screen_name => $screen_name,
		listmask    => $listmask,
		groups      => @groups,
    };
    $_[KERNEL]->yield(notify => 'got_list' => $_[ARG0]);
}

sub got_group {
    my($group, $gid) = $_[ARG0]->args;
    $_[HEAP]->{groups}->{$gid} = $group;
    $_[KERNEL]->yield(notify => 'got_group' => $_[ARG0]);
}

sub put {
    $_[HEAP]->{sock}->put(
	POE::Component::Client::MSN::Command->new(@_[ARG0, ARG1], $_[HEAP]),
    );
}

sub got_ring {
    my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];

    $kernel->yield(notify => chat_ring => $command );
}

sub talk_user {
    my($kernel, $heap, $session, $email) = @_[KERNEL, HEAP, SESSION, ARG0];
	
	$heap->{buddy_email} = $email;

	# need a postback or something here
    $heap->{sock}->put(
		POE::Component::Client::MSN::Command->new("XFR" => "SB", $heap),
    );
}

sub accept_call {
    my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];

    POE::Session->create(
	inline_states => {
	    _start => \&sb_start,
	    _sb_sock_up => \&sb_sock_up,
	    _sb_sock_down => \&sb_sock_down,
	    _default => \&sb_chat_debug,
	    handle_event => \&sb_handle_event,
	    MSG => \&sb_got_message,
	    send_message => \&sb_send_message,
	    accept_file => \&sb_accept_file,
	    send_file => \&sb_send_file,
		accept_send => \&sb_accept_send,
	    typing_user	=> \&sb_send_typing_user,
	    send_reject_invite => \&sb_send_reject_invite,
		send_cancel_invite => \&sb_send_cancel_invite,
	    invite_user => \&sb_send_invite_user,
		disconnect => sub {
   		 	my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
			my $cmd = POE::Component::Client::MSN::Command->new(OUT => "");
			$cmd->{name_only} = 1;
			$heap->{sock}->put($cmd);
		},
	    put => \&put,
		_stop => \&sb_sock_down,
		BYE => sub {
    		my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
			# someone left conversation
			$kernel->post($heap->{parent} => notify => chat_bye => { command => $command, session_id => $_[SESSION]->ID } ); 
		},
		NAK => sub {
    		my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
			$kernel->post($heap->{parent} => notify => chat_nak => { command => $command, session_id => $_[SESSION]->ID } );
		},
		JOI => sub {
    		my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
			$kernel->post($heap->{parent} => notify => chat_join => { command => $command, session_id => $_[SESSION]->ID } );
		},
		IRO => sub {
    		my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
			$kernel->post($heap->{parent} => notify => chat_start => { command => $command, session_id => $_[SESSION]->ID } );
		},
	    _default => sub {
			my $arg = $_[ARG0];
			print STDERR "CHAT\:\:$arg\n";
			return undef;
	    },
	},
	args => [ $command, $session->ID, $heap ],
    );
}

sub sb_start {
    my($kernel, $heap, $command, $parent, $old_heap) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    $heap->{parent} = $parent;
    $heap->{session} = $command->transaction;
    $heap->{transaction} = $old_heap->{transaction} + 1;
    $heap->{username} = $old_heap->{username};
    @{$heap}{qw(hostname port)} = split /:/, $command->args->[0];
    $heap->{key} = $command->args->[2];
    $heap->{buddy_email} = $command->args->[3];
	$heap->{old_heap} = $old_heap; # might need this
    $heap->{sock} = POE::Wheel::SocketFactory->new(
		SocketDomain => AF_INET,
		SocketType => SOCK_STREAM,
		SocketProtocol => 'tcp',
		RemoteAddress => $heap->{hostname},
		RemotePort => $heap->{port},
		SuccessEvent => '_sb_sock_up',
		FailureEvent => '_sb_sock_failed',
    );
}

sub sb_start_xfr {
    my($kernel, $heap, $command, $parent, $old_heap) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    eval {
	$heap->{parent} = $parent;
	$heap->{session} = $command->transaction;
	$heap->{transaction} = $old_heap->{transaction} + 1;
	$heap->{username} = $old_heap->{username};
	$heap->{buddy_email} = delete $old_heap->{buddy_email};
	@{$heap}{qw(hostname port)} = split /:/, $command->args->[1];
	$heap->{key} = $command->args->[3];
	$heap->{sock} = POE::Wheel::SocketFactory->new(
	    SocketDomain => AF_INET,
	    SocketType => SOCK_STREAM,
	    SocketProtocol => 'tcp',
	    RemoteAddress => $heap->{hostname},
	    RemotePort => $heap->{port},
	    SuccessEvent => '_sb_sock_up',
	    FailureEvent => '_sb_sock_failed',
	);
    };
    if ($@) {
		print STDERR "$@\n";
    }
}

sub sb_sock_up {
    my($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
    $heap->{sock} = POE::Wheel::ReadWrite->new(
		Handle => $socket,
		Driver => POE::Driver::SysRW->new,
		Filter => POE::Filter::MSN->new,
		ErrorEvent => '_sb_sock_down',
		InputEvent => 'handle_event',
    );
    $heap->{sock}->put(
		POE::Component::Client::MSN::Command->new(
		    ANS => "$heap->{username} $heap->{key} $heap->{session}" => $heap,
		),
    );
    $kernel->post($heap->{parent} => notify => chat_socket_opened => { buddy_email => $heap->{buddy_email}, buddy_nick => $heap->{buddy_nick}, session_id => $_[SESSION]->ID } );
}

sub sb_sock_up_xfr {
    my($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
    $heap->{sock} = POE::Wheel::ReadWrite->new(
		Handle => $socket,
		Driver => POE::Driver::SysRW->new,
		Filter => POE::Filter::MSN->new,
		ErrorEvent => '_sb_sock_down',
		InputEvent => 'handle_event',
    );
    $heap->{sock}->put(
		POE::Component::Client::MSN::Command->new(
		    USR => "$heap->{username} $heap->{key}" => $heap,
		),
    );
	# we don't have nick yet, so use thier email as buddy_nick
    $kernel->post($heap->{parent} => notify => chat_socket_opened => { buddy_email => $heap->{buddy_email}, buddy_nick => $heap->{buddy_nick}, session_id => $_[SESSION]->ID } );
}

sub sb_sock_down {
    my($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
    delete $heap->{sock};
    #	if (exists($heap->{parent})) {
    eval {
	$kernel->post($heap->{parent} => notify => chat_socket_closed => { session_id => $session->ID } );
    };
    print STDERR "$@\n" if ($@);
    #	}
}

sub sb_handle_event {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    $kernel->yield($command->name, $command);
}

sub sb_send_invite_user {
    my($kernel, $heap, $user) = @_[KERNEL, HEAP, ARG0];

    return unless ($user);
	
    $heap->{sock}->put(
		POE::Component::Client::MSN::Command->new(
		    CAL => "$user" => $heap,
		),
    );
}

sub sb_got_user {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
	
	#OK xantus@teknikill.net Telstron(6)
    $kernel->post($heap->{parent} => notify => out_chat_opened =>
		      { command => $command, session_id => $_[SESSION]->ID });

	$kernel->yield(invite_user => $heap->{buddy_email});
}

sub sb_chat_debug {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];

    $kernel->post($heap->{parent} => notify => chat_debug => { command => $command, session_id => $_[SESSION]->ID });
}

sub sb_got_message {
    my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
	
    if ($command->{'message'} && $command->{'message'}->{'mail_inet_head'}) {
		my $ct;
		
		eval { $ct = ${$command->{'message'}->{'mail_inet_head'}->{'mail_hdr_hash'}->{'Content-Type'}->[0]}; };
		
		if ($@) {
			print STDERR "$@";
			return;
		}
	
		if ($ct =~ m#^Content-Type: text/x-clientcaps#) {
			# Gaim and others send this
			$kernel->post($heap->{parent} => notify => got_clientcaps => { command => $command, session_id => $session->ID });
		} elsif ($ct =~ m#^Content-Type: application/x-msnmsgrp2p#) {
			# p2p stuff
			# TODO
			require Data::Dumper;
			print STDERR Data::Dumper->Dump([$command]);
	    } elsif ($ct =~ m#^Content-Type: text/x-mms-emoticon#) {
			# emote icon
			# TODO
			print STDERR "received emoticon, nothing done\n";
	    } elsif ($ct =~ m#^Content-Type: text/plain#) {
			# regular text message
			$kernel->post($heap->{parent} => notify => got_message => { command => $command, session_id => $session->ID });
	    } elsif ($ct =~ m#^Content-Type: text/x-msmsgscontrol#) {
			# typing
			eval {
				my $typing = ${$command->{'message'}->{'mail_inet_head'}->{'mail_hdr_hash'}->{'Typinguser'}->[0]};
				$typing =~ s/^Typinguser: //i;
				$kernel->post($heap->{parent} => notify => typing_user => { command => $command, typing_user => $typing, session_id => $session->ID });
			};
			if ($@) { print "$@\n"; }
		} elsif ($ct =~ m#^Content-Type: text/x-msmsgsinvite#) {
			# Invitations

			# we have header type fields in the body, parse those
			my %fields;
			foreach (@{$command->{'message'}->{'mail_inet_body'}}) {
			    my ($k,$v) = split(/:\s/);
			    $fields{$k} = $v;
			}

			# TODO better handling of CANCEL's   Invitation-Command: CANCEL and Cancel-Code: FTTIMEOUT ect, ect
			if ($heap->{inv_cookie} && $fields{'Invitation-Cookie'} && ($heap->{inv_cookie} eq $fields{'Invitation-Cookie'})) {
				# valid invitation!
				# is it a cancel?
				if ($fields{'Invitation-Command'} eq 'CANCEL') {
					$kernel->post($heap->{parent} => notify => file_cancel =>
						{ command => $command, session_id => $session->ID, fields => { %fields } });
				} elsif ($fields{'Invitation-Command'} eq 'ACCEPT') {
					# elimitated a whole step here
#					$kernel->post($heap->{parent} => notify => file_send =>
#						{ command => $command, session_id => $session->ID, fields => { %fields } });
					$kernel->yield(accept_send => { command => $command, session_id => $session->ID, fields => { %fields } });
				} else {
					print STDERR "Unknown invite: ".$fields{'Invitation-Command'}."\n";
				}
				return;
			}
		
			# file transfer? notify listeners about it or deny it
			if ($fields{'Application-GUID'} =~ m#5D3E02AB-6190-11d3-BBBB-00C04F795683#) {
				# this was an interesting delve into the kernel and session modules to find this
				# We look at our listening sessions and check if they have the msn_file_request state registered
				# meaning if they do, then pass 
				eval {
					my $found = 0;
    				foreach my $sid (keys %{$heap->{old_heap}->{listeners}}) {
						my $sess = $kernel->ID_id_to_session($sid);
						if ($sess->[POE::Session::SE_STATES]->{msn_file_request}) {
							$kernel->post($sid => msn_file_request =>
						      { command => $command, session_id => $session->ID, fields => { %fields } });
					  		$found = 1;
						}
					}
					unless ($found == 1) {
						# no listening sessions have file handlers, so reject thier request
					   	$kernel->yield("send_reject_invite" => $command);
					}
				};
				if ($@) {
					print STDERR "$@\n";
				}
				#$kernel->post($heap->{parent} => notify => file_request =>
				#	{ command => $command, session_id => $session->ID, fields => { %fields } });
			} else {
			    $kernel->yield("send_reject_invite" => $command);
			}
			return;
    	} else {
			# unknown catch
			require Data::Dumper;
			print STDERR "Unknown message type: ".Data::Dumper->Dump([$command]);
	    }
	} else {
		print STDERR "Invalid message?\n";
	}
}

sub sb_send_reject_invite {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
	
    my %fields;
    foreach (@{$command->{'message'}->{'mail_inet_body'}}) {
	my ($k,$v) = split(/:\s/);
	$fields{$k} = $v;
    }
    my $msg = qq(MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\nInvitation-Command: CANCEL\r\nInvitation-Cookie: $fields{'Invitation-Cookie'}\r\nCancel-Code: REJECT_NOT_INSTALLED\r\n\r\n);
    my $cmd = POE::Component::Client::MSN::Command->new(
	MSG => "N ".length($msg)."\r\n$msg" => $msg, 1
    );
    $cmd->{transaction}++;
    $heap->{sock}->put($cmd);
}

sub sb_send_cancel_invite {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
	
    my %fields;
    foreach (@{$command->{'message'}->{'mail_inet_body'}}) {
	my ($k,$v) = split(/:\s/);
	$fields{$k} = $v;
    }
	# TODO add FAIL, FTTIMEOUT, OUTBANDCANCEL, TIMEOUT
    my $msg = qq(MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\nInvitation-Command: CANCEL\r\nInvitation-Cookie: $fields{'Invitation-Cookie'}\r\nCancel-Code: REJECT\r\n\r\n);
    my $cmd = POE::Component::Client::MSN::Command->new(
	MSG => "N ".length($msg)."\r\n$msg" => $msg, 1
    );
    $cmd->{transaction}++;
    $heap->{sock}->put($cmd);
}

sub sb_send_message {
    my($kernel, $heap, $args, $seconds) = @_[KERNEL, HEAP, ARG0, ARG1];
    #	MSG 4 N ###\r\n
    #	MIME-Version: 1.0\r\n
    #	Content-Type: text/plain; charset=UTF-8\r\n
    #	X-MMS-IM-Format: FN=Arial; EF=I; CO=0; CS=0; PF=22\r\n
    #	\r\n
    #	Hello! How are you?
    #	
    #	Try this too:
    #	<dngnand> if (alarm_is_outstanding()) { $buffer .= $new_message; } else { send($new_message); $kernel->delay(waiting => 2); $alarms++ }
    #	<dngnand> sub alarm_is_outstanding { return !!$alarms }
    #	<dngnand> sub alarm_handler { $alarms--; if (length $buffer) { send($buffer); $kernel->delay(waiting => 2); $alarms++ } }
    #	<dngnand> Oh, and $buffer = ""; after sending it from alarm_handler()
    eval {
	my $head = qq(MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\nX-MMS-IM-Format: FN=Verdana; EF=; CO=0; CS=0; PF=22\r\n\r\n);
	if ($seconds) {
	    $kernel->delay_set('send_message' => $seconds => $args );
	    return;
	} else {
#	    # there's GOT to be a better way to do this
#	    my @removed_alarms = $kernel->alarm_remove_all();
#	    foreach my $alarm (reverse @removed_alarms) {
#			#			print STDERR "-----\n";
#			#			print STDERR "Removed alarm event name: $alarm->[0]\n";
#			#			print STDERR "Removed alarm time      : $alarm->[1]\n";
#			#print STDERR "Removed alarm parameters: @{$alarm->[2]}\n";
#			if ($alarm->[0] eq 'send_message' && length("$head$args\r\n$alarm->[2]") < 1664) {
#			    #				print STDERR "Combining message $alarm->[2]\n";
#			    $args .= "\r\n$alarm->[2]";
#			} else {
#			    #				print STDERR "Putting alarm back: $alarm->[0]\n";
#			    if (ref($alarm->[2]) eq 'ARRAY') {
#					$kernel->alarm_add($alarm->[0],$alarm->[1],@{$alarm->[2]});
#				} else {
#					$kernel->alarm_add($alarm->[0],$alarm->[1],$alarm->[2]);
#			    }
#			}
#	    }

	    # here's where i can check if there are any other messsages on the delay stack
	    # and combine the messages into 1 send
	    my $msg = "$head$args";
	    my $cmd = POE::Component::Client::MSN::Command->new(
			MSG => "N ".length($msg)."\r\n$msg" => $msg, 1
	    );
	    $cmd->{transaction}++;
	    $heap->{sock}->put($cmd);
	}
    };
    print STDERR "$@\n" if ($@);
}

sub sb_send_typing_user {
    my($kernel, $heap, $username, $seconds) = @_[KERNEL, HEAP, ARG0, ARG1];
    $username = ($username) ? $username : $heap->{username};
    #	MSG 5 U ###\r\n
    #	MIME-Version: 1.0\r\n
    #	Content-Type: text/x-msmsgscontrol\r\n
    #	TypingUser: example@passport.com\r\n
    #	\r\n
    #	\r\n
    if (($heap->{typing_time} && (time() - $heap->{typing_time} > 10)) || !exists($heap->{typing_time})) {
	my $msg = qq(MIME-Version: 1.0\r\nContent-Type: text/x-msmsgscontrol\r\nTypingUser: $username\r\n\r\n);
	my $cmd = POE::Component::Client::MSN::Command->new(
	    MSG => "U ".length($msg)."\r\n$msg" => $msg, 1
	);
	$cmd->{transaction}++;
	$heap->{sock}->put($cmd);
	$heap->{typing_time} = time();
    }
}

sub sb_send_file {
    my($kernel, $heap, $session, $data) = @_[KERNEL, HEAP, SESSION, ARG0];
	
	# sequence:
	# client -> send_file -> request sent to person
	# person accepts -> accept_send
	# sb_file_send_start -> connect to other -> sb_file_sock_up
	# get VER
	# send VER
	# get USR
	# send FIL <size>
	# get TFR
	# msn_file_stream is called after every flush
	# msn_file_stream puts the data directy to the socket handle of the connection
	# the filter does the headers for each packet
	# at eof then the client sends no stream data, and just a eof => 1 in the refhash
	$heap->{inv_cookie} = int rand(2**32); # no zeros

	my $msg = qq(MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\nApplication-Name: File Transfer\r\nApplication-GUID: {5D3E02AB-6190-11d3-BBBB-00C04F795683}\r\nInvitation-Command: INVITE\r\nInvitation-Cookie: $heap->{inv_cookie}\r\nApplication-File: $data->{file_name}\r\nApplication-FileSize: $data->{file_size}\r\nConnectivity: N\r\n\r\n);
	my $cmd = POE::Component::Client::MSN::Command->new(
	    MSG => "N ".length($msg)."\r\n$msg" => $msg, 1
	);
	$cmd->{transaction}++;
	$heap->{sock}->put($cmd);
	# TODO should we store this ourselves or allow the accept_send call to specify it?
	$heap->{file_name} = $data->{file_name};
	$heap->{file_size} = $data->{file_size};
}

sub sb_accept_send {
    my($kernel, $heap, $session, $data) = @_[KERNEL, HEAP, SESSION, ARG0];
		
	#####################
	# FOR SENDING FILE
	#####################

    POE::Session->create(
		inline_states => {
		    _start => \&sb_file_send_start,
		    _sb_file_sock_up => \&sb_file_sock_up,
		    _sb_file_sock_down => \&sb_file_sock_down,
			_sb_file_sock_flushed => sub {
				my ($heap, $session, $command) = @_[HEAP, SESSION, ARG0];
	
				unless ($heap->{canceled}) {
					$kernel->post($heap->{parent} => notify => file_stream => { command => $command, session_id => $session->ID,
						for_session_id => $heap->{chat_parent}, sock => $heap->{sock} });
				}
			},
		    _default => sub {
				my $arg = $_[ARG0];
				print STDERR "MSNFTP-send\:\:$arg\n";
				return undef;
			},
		    handle_event => \&sb_file_handle_event,
			VER => sub {
				my $heap = $_[HEAP];
				
				# TODO 3rd party FTP protocol support, if any
				$heap->{sock}->put(
				    POE::Component::Client::MSN::Command->new(VER => "MSNFTP"),
				);
			},
		    _VER_NOT_USED => sub {
				my $heap = $_[HEAP];
			
				$heap->{sock}->put(
				    POE::Component::Client::MSN::Command->new(USR => "$heap->{username} $heap->{cookie}"),
				);
		    },
		    USR => sub {
				my $heap = $_[HEAP];
		
				$heap->{sock}->put(
					POE::Component::Client::MSN::Command->new(FIL => "$heap->{file_size}"),
				);
		    },
			TFR => sub {
				my ($heap, $kernel, $session, $command) = @_[HEAP, KERNEL, SESSION, ARG0];
				
				delete $heap->{canceled};
				$heap->{sock}->event(FlushedEvent => '_sb_file_sock_flushed');
				$kernel->yield("_sb_file_sock_flushed",splice(@_,ARG0));
				#$kernel->post($heap->{parent} => notify => file_stream => { command => $command, session_id => $session->ID,
				#	for_session_id => $heap->{chat_parent}, sock => $heap->{sock} });
			},
			CCL => sub {
				my ($heap, $session, $command) = @_[HEAP, SESSION, ARG0];
				
				$heap->{canceled} = 1;
	
				# canceled!
				# TODO maybe this should be file_send_cancel
				$kernel->post($heap->{parent} => notify => file_cancel =>
					{ command => $command, session_id => $session->ID, for_session_id => $heap->{chat_parent}, sock => $heap->{sock} });
				
			},
			BYE => sub {
				my ($heap, $session, $command) = @_[HEAP, SESSION, ARG0];
				
				my %codes = (
					2147942405 => 'Failure: receiver is out of disk space',
					2164261682 => 'Failure: receiver canceled the transfer',
					2164261683 => 'Failure: sender has canceled the transfer',
					2164261694 => 'Failure: connection is blocked',
					16777987 => 'Success',
					16777989 => 'Success',
				);
				
				print STDERR "File transfer: ".$codes{$command->args->[0]}."\n";
		
				$kernel->yield("_sb_file_sock_down");
			},
			send_bye => sub {
				my $heap = $_[HEAP];
	
				my $cmd = POE::Component::Client::MSN::Command->new(BYE => "");
				$cmd->{name_only} = 1;
				$heap->{sock}->put($cmd);
			},
		},
		args => [ $data, $session->ID, $heap ],
	);
}

sub sb_file_send_start {
    my($kernel, $heap, $data, $parent, $old_heap) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
	
    eval {

# we get this back after acceptance

#'IP-Address: 216.254.16.46',
#'IP-Address-Internal: 10.0.2.3',
#'Port: 6892',
#'PortX: 11181',
#'AuthCookie: 1251249521',
#'Sender-Connect: TRUE',
#'Invitation-Command: ACCEPT',
#'Invitation-Cookie: 25',
#'Launch-Application: FALSE',
#'Request-Data: IP-Address:'
	my $command = $data->{command};
	$heap->{username} = $old_heap->{username};
	# we want the parents parent instead
	$heap->{parent} = $old_heap->{parent};
	$heap->{file_name} = delete $old_heap->{file_name};
	$heap->{file_size} = delete $old_heap->{file_size};
	$heap->{chat_parent} = $parent;
#	$heap->{file_name} = $data->{fields}->{'Application-File'};
	$heap->{session} = $command->transaction;
	$heap->{transaction} = $old_heap->{transaction} + 1;
	my %fields;
	foreach (@{$command->{'message'}->{'mail_inet_body'}}) {
	    my ($k,$v) = split(/:\s/);
	    $fields{$k} = $v;
	}
	$heap->{cookie} = $fields{'AuthCookie'};

	# connect to both ips and ports at the same time
	# first one wins
    $heap->{sock} = POE::Wheel::SocketFactory->new(
		SocketDomain => AF_INET,
		SocketType => SOCK_STREAM,
		SocketProtocol => 'tcp',
		RemoteAddress => $fields{'IP-Address'},
		RemotePort => $fields{'Port'},
		SuccessEvent => '_sb_file_sock_up',
		FailureEvent => '_sb_file_sock_down',
    );
	
    $heap->{sock2} = POE::Wheel::SocketFactory->new(
		SocketDomain => AF_INET,
		SocketType => SOCK_STREAM,
		SocketProtocol => 'tcp',
		RemoteAddress => $fields{'IP-Address-Internal'},
		RemotePort => $fields{'Port'},
		SuccessEvent => '_sb_file_sock_up',
		FailureEvent => '_sb_file_sock_down2',
    );
	
	# setup the listening socket
#	$heap->{sock} = POE::Wheel::SocketFactory->new(
#	    BindAddress    => INADDR_ANY, # Sets the bind() address
#	    BindPort       => 6891, # Sets the bind() port
#	    SuccessEvent   => '_sb_file_got_connection', # Event to emit upon accept()
#	    FailureEvent   => '_sb_file_sock_down', # Event to emit upon error
#	    SocketDomain   => AF_INET, # Sets the socket() domain
#	    SocketType     => SOCK_STREAM, # Sets the socket() type
#	    SocketProtocol => 'tcp', # Sets the socket() protocol
#	    # maybe set this to 1? therefore only allowing 1 connection i think
#	    #			ListenQueue    => SOMAXCONN,           # The listen() queue length
#	    Reuse          => 'on', # Lets the port be reused
#	);
	
    };
    print STDERR "$@\n" if ($@);
}

sub sb_file_sock_up {
    my($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
    # new ReadWrite wheel for the socket
	
    $heap->{sock} = POE::Wheel::ReadWrite->new(
		Handle => $socket,
		Driver => POE::Driver::SysRW->new,
		Filter => POE::Filter::MSN->new(ftp => 1, file_size => $heap->{file_size}),
		ErrorEvent => '_sb_file_sock_down',
		InputEvent => 'handle_event',
	);
	delete $heap->{sock2};	
}

sub sb_accept_file {
    my($kernel, $heap, $session, $data) = @_[KERNEL, HEAP, SESSION, ARG0];

	#####################
	# FOR RECEIVING FILE
	#####################
	
    POE::Session->create(
		inline_states => {
		    _start => \&sb_file_start,
		    _sb_file_got_connection => \&sb_file_got_connection,
		    _sb_file_sock_down => \&sb_file_sock_down,
		    handle_event => \&sb_file_handle_event,
		    _default => sub {
				my $arg = $_[ARG0];
				print STDERR "MSNFTP-get\:\:$arg\n";
				return undef;
		    },
		    VER => sub {
				my $heap = $_[HEAP];
				
				$heap->{sock}->put(
				    POE::Component::Client::MSN::Command->new(USR => "$heap->{username} $heap->{cookie}"),
				);
		    },
		    FIL => sub {
				my $heap = $_[HEAP];
		
				eval {
				    my $cmd = POE::Component::Client::MSN::Command->new(TFR => "");
				    $cmd->{name_only} = 1;
				    $heap->{sock}->put($cmd);	 
				};
				if ($@) {
				    print STDERR "TFR error:$@\n";
				}
		    },
		    BYE => \&sb_file_sock_down,
		},
		args => [ $data, $session->ID, $heap ],
    );
}

sub sb_file_start {
    my($kernel, $heap, $data, $parent, $old_heap) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
	
    eval {
	my $command = $data->{command};
	$heap->{old_heap} = $old_heap;
	$heap->{username} = $old_heap->{username};
	# we want the parents parent instead
	$heap->{parent} = $old_heap->{parent};
	#		$heap->{parent} = $parent;
	$heap->{file_name} = $data->{fields}->{'Application-File'};
	$heap->{session} = $command->transaction;
	$heap->{transaction} = $old_heap->{transaction} + 1;
	$heap->{auth_cookie} = int rand(2**32); # no zeros
	my %fields;
	foreach (@{$command->{'message'}->{'mail_inet_body'}}) {
	    my ($k,$v) = split(/:\s/);
	    $fields{$k} = $v;
	}

	# setup the listening sockets
	$heap->{sock} = POE::Wheel::SocketFactory->new(
	    BindAddress    => INADDR_ANY, # Sets the bind() address
	    BindPort       => 6891, # Sets the bind() port
	    SuccessEvent   => '_sb_file_got_connection', # Event to emit upon accept()
	    FailureEvent   => '_sb_file_sock_down', # Event to emit upon error
	    SocketDomain   => AF_INET, # Sets the socket() domain
	    SocketType     => SOCK_STREAM, # Sets the socket() type
	    SocketProtocol => 'tcp', # Sets the socket() protocol
	    # maybe set this to 1? therefore only allowing 1 connection i think
	    #			ListenQueue    => SOMAXCONN,           # The listen() queue length
	    Reuse          => 'on', # Lets the port be reused
	);

	# TODO: use getsockname to get the address that we bound to put in the msg
	#PortX: 11178\r\n
	#$heap->{cookie} = $fields{'Invitation-Cookie'};
	$heap->{cookie} = $heap->{auth_cookie};

	# TODO get real ip addresses in here!
	my $msg = qq(MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\nIP-Address: 216.254.16.46\r\nIP-Address-Internal: 10.0.2.11\r\nPort: 6891\r\nAuthCookie: $heap->{auth_cookie}\r\nSender-Connect: TRUE\r\nInvitation-Command: ACCEPT\r\nInvitation-Cookie: $fields{'Invitation-Cookie'}\r\nLaunch-Application: FALSE\r\nRequest-Data: IP-Address:\r\n\r\n);
	my $cmd = POE::Component::Client::MSN::Command->new(
	    MSG => "N ".length($msg)."\r\n$msg" => $msg, 1
	);
	$cmd->{transaction}++;
	$heap->{old_heap}->{sock}->put($cmd);
    };
    print STDERR "$@\n" if ($@);
}

sub sb_file_got_connection {
    my($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
    #	eval {
    $heap->{sock} = POE::Wheel::ReadWrite->new(
		Handle => $socket,
		Driver => POE::Driver::SysRW->new,
		Filter => POE::Filter::MSN->new(ftp => 1),
		ErrorEvent => '_sb_file_sock_down',
		InputEvent => 'handle_event',
    );
    $heap->{sock}->put(
		POE::Component::Client::MSN::Command->new(VER => "MSNFTP"),
    );
}

sub sb_file_sock_down {
    print STDERR "sb_file_sock_down\n";
    delete $_[HEAP]->{sock};
}

sub sb_file_sock_down2 {
	# for our dual connect sending
    print STDERR "sb_file_sock_down2\n";
    delete $_[HEAP]->{sock2};
}

sub sb_file_handle_event {
    my($kernel, $heap, $session, $command) = @_[KERNEL, HEAP, SESSION, ARG0];
    eval {
	if (exists($command->{stream})) {
	    $command->{session_id} = $session->ID;
	    $command->{file_name} = $heap->{file_name};
	    if (exists($command->{eof})) {
		$kernel->post($heap->{parent} => notify => file_complete => $command);
				# send BYE
		$heap->{sock}->put(
		    POE::Component::Client::MSN::Command->new(BYE => "16777989"),
		);
	    } elsif (exists($command->{error_num})) {
				# TODO add error_num to the filter
		$kernel->post($heap->{parent} => notify => file_error => $command);
		$heap->{sock}->put(
		    POE::Component::Client::MSN::Command->new(BYE => $command->{error_num}),
		);
	    } else {
		$kernel->post($heap->{parent} => notify => file_data_stream => $command);
	    }
	} else {
	    $kernel->yield($command->name, $command);
	}
    };
    print STDERR "$@" if ($@);
}

sub sb_file_got_version {
    my($kernel, $heap, $command) = @_[KERNEL, HEAP, ARG0];
    #	print STDERR "sb_file_sock_down";
    #	$kernel->post($heap->{parent} => notify => got_version => { command => $command, session_id => $_[SESSION]->ID });
}


1;
__END__

=head1 NAME

POE::Component::Client::MSN - POE Component for MSN Messenger

=head1 SYNOPSIS

  use POE qw(Component::Client::MSN);

  # spawn MSN session
  POE::Component::Client::MSN->spawn(Alias => 'msn');

  # register your session as MSN observer
  $kernel->post(msn => 'register');
  # tell MSN how to connect servers
  $kernel->post(msn => connect => {
	  username => 'yourname',
	  password => 'xxxxxxxx',
  });

  sub msn_goes_online {
	  my $event = $_[ARG0];
	  print $event->username, " goes online.\n";
  }

  $poe_kernel->run;

=head1 DESCRIPTION

POE::Component::Client::MSN is a POE component to connect MSN Messenger server.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

David Davis E<lt>xantus@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE>, L<POE::Component::YahooMessenger>

http://www.hypothetic.org/docs/msn/research/msnp9.php

http://www.chat.solidhouse.com/

=cut

__DATA__

