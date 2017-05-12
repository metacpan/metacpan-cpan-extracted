#!/usr/bin/env perl 
use strict;
use warnings;
use Tickit::DSL qw(:async);
use Tickit::Style;
use Email::Simple;
use Try::Tiny;
use Future::Utils;
use Date::Parse qw(str2time);
use POSIX qw(strftime);
use Encode::MIME::EncWords;
use Net::Async::IMAP::Client;

Tickit::Style->load_style(<<'EOF');
GridBox.message_header {
 col_spacing: 2;
 row_spacing: 0;
}
EOF

my %widget;
my $imap;
vbox {
#	menubar {
#		submenu File => sub {
#			menuitem 'Open mbox file...'  => sub { warn 'open' };
#			menuspacer;
#			menuitem Exit  => sub { tickit->stop };
#		};
#		submenu Account => sub {
#			menuitem 'Open mbox file...'  => sub { warn 'open' };
#			menuspacer;
#		};
#		menuspacer;
#		submenu Help => sub {
#			menuitem About => sub { warn 'about' };
#		};
#	};
	relative {
		pane {
#			scrollbox {
				my $tree = tree {
				};
				{
					my $folders = $tree->root->new_daughter({ name => 'first@example.com' });
					$folders->new_daughter({ name => 'Inbox' });
					my $sent = $folders->new_daughter({ name => 'Sent' });
					$sent->new_daughter({ name => '2011' });
					$sent->new_daughter({ name => '2012' });
					$sent->new_daughter({ name => '2013' });
					$sent->new_daughter({ name => '2014' });
					$folders->new_daughter({ name => 'Deleted' });
					$folders->new_daughter({ name => 'Junk' });
				}
				{
					my $folders = $tree->root->new_daughter({ name => 'second@example.com' });
					$folders->new_daughter({ name => 'Inbox' });
					my $sent = $folders->new_daughter({ name => 'Sent' });
					$sent->new_daughter({ name => '2011' });
					$sent->new_daughter({ name => '2012' });
					$sent->new_daughter({ name => '2013' });
					$sent->new_daughter({ name => '2014' });
					$folders->new_daughter({ name => 'Deleted' });
					$folders->new_daughter({ name => 'Junk' });
				}
				$tree
#			} horizontal => 1, vertical => 1;
		} title => 'Folders',
		  id    => 'folders',
		  width => '33%';
		pane {
			customwidget {
				my $w = Tickit::Widget::Table::Paged->new;
				$w->{on_activate} = sub {
					my ($row, $data) = @_;
					my $idx = $data->[0];
					$imap->fetch(
						message => $idx,
						type => '(ENVELOPE BODY[])',
						on_fetch => sub {
							my $msg = shift;
							$msg->data('envelope')->on_done(sub {
								my $env = shift;
								$widget{subject}->set_text(Encode::decode('MIME-EncWords' => $env->subject));
							});
						}
					);
				};
				$widget{messages} = $w;
				$w->add_column(
					label => 'Message',
					align => 'left',
					width => 4,
				);
				$w->add_column(
					label => 'Subject',
					align => 'left'
				);
				$w->add_column(
					label => 'From',
					align => 'left'
				);
				$w->add_column(
					label => 'Size',
					align => 'right',
					width => 9
				);
				$w->add_column(
					label => 'Date',
					align => 'right',
					width => 19
				);
#				$w->add_row(
#					'Test message',
#					'Some user',
#					123102,
#					'2013-01-01 14:53:08'
#				);
				$w
			};
		} title    => 'Messages',
		  id       => 'messages',
		  right_of => 'folders',
		  height   => '33%';
		pane {
			vbox {
				gridbox {
					gridrow {
						static 'From:', align => 'right';
						$widget{from} = static 'Some user';
					};
					gridrow {
						static 'Subject:', align => 'right';
						$widget{subject} = static 'Re: Some email test message';
					};
					gridrow {
						static 'To:', align => 'right';
						$widget{to} = static 'Me';
					};
					gridrow {
						static 'Cc:', align => 'right';
						$widget{cc} = static '';
					};
				} class => 'message_header';
				scroller {
					scroller_text 'Some message content would typically be found here'
				};
			} spacing => 1;
		} title    => 'Message viewer',
		  id       => 'messageview',
		  right_of => 'folders',
		  below    => 'messages';
	} 'parent:expand' => 1;
	$widget{status} = statusbar { };
};

$imap = Net::Async::IMAP::Client->new;
loop->add($imap);
use Getopt::Long;
GetOptions(
	'user=s' => \my $user,
	'pass=s' => \my $pass,
	'host=s' => \my $host,
);
$imap->connect(
	user     => $user,
	pass     => $pass,
	host     => $host,
	service  => 'imap2',
	socktype => 'stream',
)->on_done(sub {
	my $imap = shift;
	$widget{status}->update_status("Connection established");
})->on_fail(sub {
	$widget{status}->update_status("Failed to connect: @_");
});
my $idx = 1;
my $f = $imap->authenticated->then(sub {
	$widget{status}->update_status("Auth finished");
	$imap->status
})->then(sub {
	$widget{status}->update_status("Status ready");
	my $status = shift;
	$imap->list(
	)
})->then(sub {
#	use Data::Dumper; warn Dumper($status);
	$imap->select(
		mailbox => 'INBOX'
	);
})->then(sub {
	$widget{status}->update_status("Select complete");
	my $status = shift;
#	use Data::Dumper; warn Dumper($status);
#	Future::Utils::repeat {
	my $total = 0;
	my $max = $status->{messages} // 27;
		$imap->fetch(
			message => $idx . ":" . $max,
#			message => "1,2,3,4",
			# type => 'RFC822.HEADER',
			# type => 'BODY',
			# type => 'BODY[]',
			type => 'ALL',
#			type => '(FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODY[])',
			on_fetch => sub {
				my $msg = shift;

				try {
					my $size = $msg->data('size')->get;
					$msg->data('envelope')->on_done(sub {
						my $envelope = shift;
						my $date;
						if(my $ts = str2time($envelope->date)) {
							$date = strftime '%Y-%m-%d %H:%M:%S', localtime $ts;
						} else {
							$date = '??';
						}
						$widget{messages}->add_row(
							$idx,
							Encode::decode('MIME-EncWords' => $envelope->subject),
							join(', ', map Encode::decode('MIME-EncWords' => $_), $envelope->from),
							$size, 
							$date,
						);
						$widget{messages}->redraw;
	#					say "Message ID: " . $envelope->message_id;
	#					say "Subject:    " . $envelope->subject;
	#					say "Date:       " . $envelope->date;
	#					say "From:       " . join ',', $envelope->from;
	#					say "To:         " . join ',', $envelope->to;
	#					say "CC:         " . join ',', $envelope->cc;
	#					say "BCC:        " . join ',', $envelope->bcc;
					});
					$total += $size;
				} catch { warn "failed: $_" };
				++$idx;
			}
		)->on_fail(sub { warn "failed fetch - @_" })->on_done(sub {
			printf "Total size: %d\n", $total;
		});
#	} while => sub { ++$idx < $status->{messages} };
#	my $es = Email::Simple->new($msg);
#	my $hdr = $es->header_obj;
#	printf("[%03d] %s\n", $idx, $es->header('Subject'));
#	printf(" - %s\n", join(',', $hdr->header_names));
})->on_fail(sub { die "Failed - @_" });#->on_done(sub { $loop->stop });
tickit->run;

