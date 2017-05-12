#
# Copyright 2007, 2008 Paul Driver <frodwith@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package POE::Component::MessageQueue::Test::Stomp;
use strict;
use warnings;
use Net::Stomp;
use YAML;
use Exporter qw(import);
our @EXPORT = qw(
	stomp_connect   stomp_send 
	stomp_subscribe stomp_unsubscribe
	stomp_receive
);

sub stomp_connect {
	my ($port) = @_;
	my $stomp = Net::Stomp->new({
		hostname => 'localhost', 
		port => $port || 8099,
	});

	$stomp->connect({
		login    => 'foo', 
		passcode => 'bar'
	});

	return $stomp;
}

sub make_nonce { 
	my @chars = ('a'..'z', 'A'..'Z');
	return join('', map { $chars[rand @chars] } (1..20));
}

sub receipt_request {
	my ($stomp, %conf) = @_;
	my $nonce = make_nonce();
	my $frame = Net::Stomp::Frame->new(\%conf);

	$frame->headers->{receipt} = $nonce;
	$stomp->send_frame($frame);
	
	my $receipt = $stomp->receive_frame;

	die "Expected reciept\n" . Dump($receipt) 
		unless ($receipt->command eq 'RECEIPT' 
		&& $receipt->headers->{'receipt-id'} eq $nonce);
}

sub stomp_send {
	receipt_request($_[0],
		command => 'SEND',
		headers => {
			destination => '/queue/test',
			persistent  => 'true',
		},
		body        => 'arglebargle',
	);
}

sub stomp_subscribe {
	receipt_request($_[0],
		command => 'SUBSCRIBE',
		headers => {
			destination => '/queue/test',
			ack         => 'client',
		},
	);
}

sub stomp_unsubscribe {
	receipt_request($_[0],
		command => 'UNSUBSCRIBE',
		headers => {
			destination => '/queue/test',
		},
	);
}

sub stomp_receive {
	my $stomp = $_[0];
	my $frame = $stomp->receive_frame();

	receipt_request($stomp, 
		command => 'ACK',
		headers => { 'message-id' => $frame->headers->{'message-id'} },
	);
}

1;
