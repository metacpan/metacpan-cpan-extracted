#!/usr/bin/perl
# A Curses::UI::POE and POE::Component::Server::FTP Client

use strict;
#use warnings FATAL => "all";

use lib qw(/projects/lib);
use POE qw( Filter::Reference Component::Client::TCP );
use Curses::UI::POE;
use Curses;
use POSIX qw( strftime cuserid );
use YAML qw( Dump );

open STDERR, ">logfile.txt";

my %w;
my $curses;
my %conn;
my $curwin = 1;

$curses = Curses::UI::POE->new(
	inline_states => {
	    _start => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
	
			$kernel->alias_set("cui");
	
			POE::Component::Client::TCP->new(
				Alias => "client",
				RemoteAddress => "127.0.0.1",
				RemotePort    => 2021,
				Filter        => "POE::Filter::Reference",
				ConnectError   => sub {
					my $kernel = $_[KERNEL];
					
					$kernel->delay_set(reconnect => 5);
				},
			
				# reconnect after disconnection
				Disconnected => sub {
					my $kernel = $_[KERNEL];
			
					$kernel->delay_set(reconnect => 5);
			
					print "Disconnected! Reconnecting...";
				},
				# Build a request and send it.
			
				Connected => sub {
					my ($kernel,$heap) = @_[KERNEL, HEAP];
			
					# clear the listbox
					my $listbox = $w{1}->getobj('connections');	
					$listbox->values([]);
					$listbox->labels({});
					#$listbox->draw;
					my $label = $w{1}->getobj('info');
					$label->text("Pick a connection for more info");
					# clear the log windows
					my $viewer1 = $w{1}->getobj('viewer1');
					$viewer1->text(' ');
					#$viewer1->draw();
					my $viewer2 = $w{2}->getobj('viewer2');
					$viewer2->text(' ');
					#$viewer2->draw();
					$w{$curwin}->focus();
					$w{$curwin}->draw();
					print "Connected!";
				},
			
				# Receive a response, display it
				ServerInput => sub {
					my ( $heap, $kernel, $data ) = @_[ HEAP, KERNEL, ARG0 ];
			
					if (ref($data) eq 'HASH') {
			
						if (exists($data->{log}) && ref($data->{log}) eq 'ARRAY') {
							my @tmp;
							foreach (@{$data->{log}}) {
								push(@tmp,"[$_->{datetime}][$_->{type}$_->{sender}] $_->{data}->{msg}");
							}
							my $viewer1 = $w{1}->getobj('viewer1');	
							my $viewer2 = $w{2}->getobj('viewer2');	
							$viewer1->text(join("\n",@tmp));
							$viewer1->cursor_to_end();
							$viewer2->text(join("\n",@tmp));
							$viewer2->cursor_to_end();
							#$viewer1->draw();
							return;
						}
						if (exists($data->{conn}) && ref($data->{conn}) eq 'HASH') {
							# add the ip:port to the connection list
							my $listbox = $w{1}->getobj('connections');
							$listbox->labels({});
							my $v;
							undef %conn;
							foreach my $sid (keys %{$data->{conn}}) {
								my $o = $data->{conn}->{$sid};
								if (exists($o->{username})) {
									$listbox->add_labels({ $sid => "[".$sid."] ".$o->{peer_addr}.":".$o->{peer_port}." (".$o->{username}.")" });
								} else {
									$listbox->add_labels({ $sid => "[".$sid."] ".$o->{peer_addr}.":".$o->{peer_port} });
								}
								push(@{$v},$sid);
								$conn{$o->{session}} = $o;
							}
							$listbox->values($v);
							$listbox->draw;
							return;
						}

						if (exists($data->{event})) {
							$kernel->post(cui => $data->{event} => $data);
						} else {
							print "Client received response from server without event";
						}
					} else {
						print "Client received an unknown response type: ", ref($data);
					}
				},
				InlineStates => {
					send => sub {
						my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

						if ($heap->{server}) {
							$heap->{server}->put($data);
						}
					},
				},
			);
	    },
		_default => sub {
			my ($kernel, $heap, $event, $arg) = @_[KERNEL, HEAP, ARG0, ARG1];
			return 0 if ($event =~ m/^_/);
			if (ref($arg->[0]) eq 'HASH') {
				print "unhandled event $event";
				#require Data::Dumper;
				#delete $arg->[0]->{con_session};
				#print Data::Dumper->Dump([$arg]);
			} else {
				print "unhandled event $event";
			}
			return 0;
		},
		ftpd_connected => sub {
			my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
			my $sid = $data->{session};
			
			# add the ip:port to the connection list
			my $listbox = $w{1}->getobj('connections');
			$listbox->add_labels({ $sid => "[".$sid."] ".$data->{peer_addr}.":".$data->{peer_port} });
			my $v = $listbox->values;
			push(@{$v},$sid);
			$listbox->values($v);
			$listbox->draw;
			
			$conn{$sid} = $data;
		},
		ftpd_login => sub {
			my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
			my $sid = $data->{session};
			my $listbox = $w{1}->getobj('connections');	
			my $l = $listbox->labels();
			$conn{$sid}->{username} = $data->{username};
#			$conn{$sid}->{password} = $data->{password};
			$l->{$sid} .= " (".$data->{username}.")";
			$listbox->labels($l);
			$listbox->draw;
		},
		ftpd_disconnected => sub {
			my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
			my $sid = $data->{session};
			my $listbox = $w{1}->getobj('connections');	
			my $v = $listbox->values;
			my @newv;
			foreach (@{$v}) {
				push(@newv, $_) unless ($_ == $sid);
			}
			if (@newv) {
				$listbox->values(\@newv);
			} else {
				$listbox->values([]);
			}
			my $l = $listbox->labels();
			delete $l->{$sid};
			$listbox->labels($l);
			$listbox->draw;
			print "disconnect called for session [$sid]";
			delete $conn{$sid};
		},
		connections => sub {
			my ($kernel, $heap, $listbox) = @_[KERNEL, HEAP, ARG0];

			my $label = $listbox->parent->getobj('info');
			my @sel = $listbox->get;
			unless (@sel) {
				$label->text("Pick a connection for more info");
				$label->draw;
				return;
			}
			
			$label->text(Dump($conn{$sel[0]}));
			$label->draw;
#			my $pb = $w{1}->getobj('progress');
#			if (exists($conn{$sel[0]}->{xfr})) {
#				$pb->{-min} = 0;
#				$pb->{-max} = $conn{$sel[0]}->{xfr}->{file_size};
#				$pb->{-pos} = $conn{$sel[0]}->{xfr}->{total_bytes};
#			} else {
#				$pb->{-min} = 0;
#				$pb->{-max} = 100;
#				$pb->{-pos} = 0;
#			}
#			$pb->draw();
		},
		ftpd_dcon_create => sub {
			my ($kernel, $heap, $o) = @_[KERNEL, HEAP, ARG0];
			
			#print Dump($o);
		},
		ftpd_dcon_destroy => sub {
			my ($kernel, $heap, $o) = @_[KERNEL, HEAP, ARG0];
			#print Dump($o);
			my $listbox = $w{1}->getobj('connections');
			my $l = $listbox->labels();
			my $sid = $o->{con_session};
			# TODO a delay so 100% stays on screen longer?
			$l->{$sid} = "[".$sid."] ".$conn{$sid}->{peer_addr}.":".$conn{$sid}->{peer_port}." (".$conn{$sid}->{username}.")";
			$listbox->labels($l);
			$listbox->draw();
			delete $conn{$o->{con_session}}->{xfr};
		},
		chat_msg => sub {
			my ($kernel, $heap, $o) = @_[KERNEL, HEAP, ARG0];
			
			print CHAT "$o->{nick}> $o->{msg}";
		},
		ftpd_write_log => sub {
			my ($kernel, $heap, $o) = @_[KERNEL, HEAP, ARG0];
		
			print "[$o->{datetime}][$o->{type}$o->{sender}] $o->{data}->{msg}";
		},
		ftpd_bps_stats => sub {
			my ($kernel, $heap, $o) = @_[KERNEL, HEAP, ARG0];
			my $sid = $o->{con_session};
			$conn{$sid}->{xfr} = $o;
			my $listbox = $w{1}->getobj('connections');
			my $l = $listbox->labels();
			if ($o->{type} eq 'dl') {
				my $min = 0;
				# (pos - min) / (max - min) * 100
				my $perc = eval { ($o->{total_bytes}-$min) / ($o->{file_size}-$min)*100 };
				# 20 is the number of total stars at 100%
				my $numstars = 40;
				my $stars = int($perc * $numstars / 100);
				if ($stars == 0 and $o->{total_bytes} != $min) { $stars++; }
				if ($stars == $numstars and $o->{total_bytes} != $o->{file_size}) { $stars--; }
				my $spaces = $numstars - $stars;
				$perc = int($perc)."%";
				my $pbar = ("*" x $stars).(" " x $spaces);
				my $pos = ($numstars / 2) - (length($perc)/2);
				# 18[100%]18
				my $npbar = substr($pbar,0,$pos).$perc.substr($pbar,$pos+length($perc));
				$l->{$sid} = "[".$sid."] ".$conn{$sid}->{peer_addr}.":".$conn{$sid}->{peer_port}." (".$conn{$sid}->{username}.")".
					" Sending ".$o->{total_bytes}."/".$o->{file_size}." [$npbar] ".int($o->{bps}/1024)." Kb/s $o->{file_path}";
				$listbox->labels($l);
				$listbox->draw();
#				my @sel = $listbox->get;
#				if (@sel && $sel[0] == $sid) {
#					my $pb = $w{1}->getobj('progress');
#					$pb->{-min} = 0;
#					$pb->{-max} = $o->{file_size};
#					$pb->{-pos} = $o->{total_bytes};
#					$pb->draw();
#				}
				if ($o->{session_done} == 1) {
					delete $conn{$sid}->{xfr};
				}
			} else {
				$l->{$sid} = "[".$sid."] ".$conn{$sid}->{peer_addr}.":".$conn{$sid}->{peer_port}." (".$conn{$sid}->{username}.")".
					" Receiving ".$o->{total_bytes}."/? ".int($o->{bps}/1024)." Kb/s $o->{file_path}";
				$listbox->labels($l);
				$listbox->draw();
			}
		},
	},
	-color_support => 1
);

my $chatobj = tie *CHAT, "FTP::Output::Chat", $curses;

my $obj = tie *CURWIN, "FTP::Output", $curses;
select CURWIN;

# Bind <Ctrl-Q> to exit
$curses->set_binding( sub{ exit }, "\cQ" );

# Bind <Ctrl+X> to menubar.
$curses->set_binding( sub{ shift()->root->focus('menu') }, "\cX" );

$curses->set_binding( sub{ $curwin = 1; $w{1}->focus; }, "\cW" );
$curses->set_binding( sub{ $curwin = 2; $w{2}->focus; }, "\cE" );
$curses->set_binding( sub{ $curwin = 3; $w{3}->getobj('cmd')->focus; }, "\cR" );

# Main Menu
my $menu = $curses->add(
	'menu','Menubar', 
	-fg   => "white",
	-bg   => "blue",
	-menu => [
		{	-label => 'File', 
			-submenu => [
				{
					-label => 'Exit      ^Q',
					-value => sub { exit },
				}
			]
		},
		{	-label => 'Window', 
			-submenu => [
				{
					-label => 'Connections',
					-value => sub { $curwin = 1; $w{1}->focus; },
				},
				{
					-label => 'Full Log',
					-value => sub { $curwin = 2; $w{2}->focus; },
				},
				{
					-label => 'Console Chat',
					-value => sub { $curwin = 3; $w{3}->getobj('cmd')->focus; },
				}
			]
		}, 
		{	-label => 'Help', 
			-submenu => [
				{
					-label => 'About',
					-value => sub {
						shift->root->dialog(
							-title    => "About",
							-message  => qq|
Program : Console for POE::Component::Server::FTP server_daemon
Author  : David Davis
Email   : xantus\@cpan.org

This console connects to a running Server::FTP server_daemon
at 127.0.0.1:2021 and allows an admin to monitor and control
the users on the server.

Thanks to poing on efnet for showing some interest
in POE:Component:Server::FTP
|);		
					},
				}
			]
		}, 
	]
);

# Create the screen for the admin console
my $screen1 = $w{1} = $curses->add(
	'screen1', 'Window',
	-padtop				=> 1, # leave space for the menu
	-border				=> 0,
	-ipad				=> 0,
);

#$w{1}->add(
#	'progress', 'Progressbar',
#	-y					=> 0,
#	-width				=> -1,
#	-padright			=> 1,
#);

# connections list box   
$w{1}->add(
	'connections', 'Listbox',
	-y					=> 3,
	-width				=> -1,
	-height				=> 15,
	-padright			=> 1,
	-border				=> 1,
	-title				=> 'Connections',
	-vscrollbar			=> 1,
	-onchange			=> \&listbox_callback,
);

# ops list box
#$w{1}->add(
#	'ops', 'Listbox',
#	-y					=> 18,
#	-width				=> 35,
#	-height				=> 15,
#	-border				=> 1,
#	-title				=> 'Operations',
#	-vscrollbar			=> 1,
#	-onchange			=> \&ops_callback,
#);

# info box
$w{1}->add('info', 'TextViewer',
	-title				=> 'Info',
	-y					=> 18,
	-width				=> -1,
	-height				=> 15,
	-padright			=> 1,
	-paddingspaces		=> 1,
	-border				=> 1,
	-vscrollbar			=> 1,
	-text				=> 'Pick a connection for more info',
);

# We add the editor widget to this screen.
my $viewer1 = $w{1}->add(
	'viewer1', 'TextViewer',
	-title				=> 'Server Log',
	-border				=> 1,
	-y					=> 33,
	-pos				=> -1,
	-sfg				=> "blue",
	-sbg				=> "white",
	-padbottom			=> 2,
	-padright			=> 1,
	-showlines			=> 0,
	-sbborder			=> 0,
	-vscrollbar			=> 1,
	-hscrollbar			=> 0,
	-showhardreturns	=> 0,
	-wrapping			=> 1,
);

# Create the screen for the log console.
my $screen2 = $w{2} = $curses->add(
	'screen2', 'Window',
	-padtop				=> 1, # leave space for the menu
	-border				=> 0,
	-ipad				=> 0,
);

# We add the editor widget to this screen.
my $viewer2 = $w{2}->add(
	'viewer2', 'TextViewer',
	-border				=> 0,
	-pos				=> -1,
	-sfg				=> "blue",
	-sbg				=> "white",
	-padtop				=> 0,	
	-padbottom			=> 1,
	-showlines			=> 0,
	-sbborder			=> 0,
	-vscrollbar			=> 1,
	-hscrollbar			=> 0,
	-showhardreturns	=> 0,
	-wrapping			=> 1,
);

# Create the screen for the log console.
my $screen3 = $w{3} = $curses->add(
	'screen3', 'Window',
	-padtop				=> 1, # leave space for the menu
	-border				=> 0,
	-ipad				=> 0,
);

# We add the editor widget to this screen.
my $chat = $w{3}->add(
	'chat', 'TextViewer',
	-border				=> 0,
	-pos				=> -1,
	-sfg				=> "blue",
	-sbg				=> "white",
	-padtop				=> 0,	
	-padbottom			=> 2,
	-showlines			=> 0,
	-sbborder			=> 0,
	-vscrollbar			=> 1,
	-hscrollbar			=> 0,
	-showhardreturns	=> 0,
	-wrapping			=> 1,
	-text				=> 'Set your nickname with /nick <your-nick>',
);


$w{3}->add(
	'help', 'Label',
	-y					=> -2,
	-width				=> -1,
	-reverse			=> 1,
	-paddingspaces		=> 1,
	-fg					=> "blue",
	-bg					=> "white",
	-text				=> strftime("[%h:%m]", localtime),
);

my $editor = $w{3}->add(
	'cmd', 'TextEditor',
	-y					=> -1,
	-x					=> 0,
	-width				=> -1,
	-height				=> 1,
	-singleline			=> 1,
);

# There is no need for the editor widget to loose focus, so
# the "loose-focus" binding is disabled here. This also enables the
# use of the "TAB" key in the editor, which is nice to have.
#$editor->clear_binding('loose-focus');

my ($Current, @History, $CurCon);
my $nick = '';
set_binding $editor sub {
	my $input = shift;
	my $line = $input->get;

	push @History, $line;
	$Current = @History;

	$input->text("");

	if (my ($cmd) = ($line =~ m/^\/(\w+)/)) {
		$cmd = lc $cmd;
		if ($cmd eq 'nick') {
			$line =~ m/^\/\w+ (\S+)/;
			$nick = $1;
			print CHAT "Nickname set to '$nick'";
		}
		#if (defined $execute->{$cmd}) {
		#    $execute->{$cmd}->($line =~ m[(\S+)]g);
		#} else {
		#    print "--- $cmd not registered";
		#}
		#POE::Kernel->post(cui => $cmd => ($line =~ m[(\S+)]g));
	} else {
		#if ($CurrentChannel) {
		POE::Kernel->post(client => send => { event => 'chat_msg', nick => $nick, msg => $line });
		print CHAT "$nick> $line";
		#} else {
		#    print "No Current Channel ---";
		#}
	}
}, KEY_ENTER;

set_binding $editor sub { shift->text($History[--$Current]) }, KEY_UP;
set_binding $editor sub { 
	$Current++;
	if ($Current > @History) {
		shift->text("");
	} else {
		shift->text($History[$Current]);
	}
}, KEY_DOWN;

#set_binding $screen1 sub {
#	$w{2}->focus;
#}, KEY_LEFT;
#
#set_binding $screen2 sub {
#	$w{1}->focus;
#}, KEY_LEFT;

$obj->{-viewer1} = $viewer1;
$obj->{-viewer2} = $viewer2;
$obj->{-screen} = $w{2};
$obj->{-editor} = $editor;
$obj->{-menu} = $menu;
$chatobj->{-chat} = $chat;

$w{1}->focus();
$curses->draw();

print "Ready.";

$poe_kernel->run();

sub listbox_callback() {
    my $listbox = shift;
	
	POE::Kernel->post(cui => connections => $listbox);
}

sub ops_callback() {
    my $listbox = shift;
	
	POE::Kernel->post(cui => ops => $listbox);
}

package FTP::Output;

use strict;
#use warnings FATAL => "all";

use POSIX qw( strftime cuserid );
use Curses;

sub PRINT { 
    our @Text;

    my $object = shift;
    my ($viewer1, $viewer2, $curses) = @$object{qw( -viewer1 -viewer2 -curses )};

    shift @Text if @Text > 40;
    push @Text, shift;

    $viewer1->text(join "\n", @Text);
	$viewer1->cursor_to_end();
    $viewer2->text(join "\n", @Text);
	$viewer2->cursor_to_end();
    $curses->draw;
}

sub TIEHANDLE { 
    my $curses = pop;

	bless {
		-curses => $curses,
	}, shift;
}

1;

package FTP::Output::Chat;

use strict;
#use warnings FATAL => "all";

use POSIX qw( strftime cuserid );
use Curses;

sub PRINT { 
    our @Text;

    my $object = shift;
    my ($chat, $curses) = @$object{qw( -chat -curses )};

#    shift @Text if @Text > 40;
    push @Text, shift;

    $chat->text(join "\n", @Text);
	$chat->cursor_to_end();
    $curses->draw;
}

sub TIEHANDLE { 
    my $curses = pop;

	bless {
		-curses => $curses,
	}, shift;
}

1;
