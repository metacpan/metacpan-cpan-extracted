#!/usr/bin/env perl 
use strict;
use warnings;
use 5.010;
package main;
use Net::Async::IMAP::Client;
use IO::Async::Loop;
use Email::Simple;
use Try::Tiny;
use Future::Utils;
use Date::Parse qw(str2time);
use POSIX qw(strftime);
use Encode::MIME::EncWords;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use Getopt::Long;
GetOptions(
	'user=s' => \my $user,
	'pass=s' => \my $pass,
	'host=s' => \my $host,
);
my $loop = IO::Async::Loop->new;
my $imap = Net::Async::IMAP::Client->new;
$loop->add($imap);
$imap->connect(
	user     => $user,
	pass     => $pass,
	host     => $host,
	service  => 'imap2',
	socktype => 'stream',
)->on_done(sub {
	my $imap = shift;
	warn "Connection established\n";
#	$loop->SSL_upgrade(
#		handle => $imap->read_handle,
#	)->on_done(sub { warn "upgraded!" })->on_fail(sub { warn "failed: @_" });
})->on_fail(sub {
	warn "Failed to connect: @_\n"
});
my $idx = 1;
my $f = $imap->authenticated->then(sub {
	warn "Authentication seems to have finished";
	$imap->status
})->then(sub {
	warn "Status ready:\n";
	my $status = shift;
	$imap->list(
	)
})->then(sub {
#	use Data::Dumper; warn Dumper($status);
	$imap->select(
		mailbox => 'INBOX'
	);
})->then(sub {
	warn "Select complete: @_";
	my $status = shift;
	use Data::Dumper; warn Dumper($status);
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
						my $date = strftime '%Y-%m-%d %H:%M:%S', localtime str2time($envelope->date);
						printf "%4d %-20.20s %8d %-64.64s\n", $idx, $date, $size, Encode::decode('MIME-EncWords' => $envelope->subject);
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
})->on_fail(sub { die "Failed - @_" })->on_done(sub { $loop->stop });
$loop->later(sub { DB::enable_profile() }) if $INC{'Devel/NYTProf.pm'};
$loop->run;
DB::disable_profile() if $INC{'Devel/NYTProf.pm'};

