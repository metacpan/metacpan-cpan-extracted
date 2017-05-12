package Net::Async::ControlChannel;
# ABSTRACT: IO::Async implementation for simple key/value protocol
use strict;
use warnings;

our $VERSION = '0.005';

=head1 NAME

Net::Async::ControlChannel - L<IO::Async> support for ControlChannel protocol

=head1 VERSION

Version 0.005

=head1 DESCRIPTION

Provides an L<IO::Async> implementation.

See documentation in:

=over 4

=item * L<Net::Async::ControlChannel::Server>

=item * L<Net::Async::ControlChannel::Client>

=item * L<Protocol::ControlChannel>

=back

=cut

use Net::Async::ControlChannel::Server;
use Net::Async::ControlChannel::Client;

1;

__END__

=head1 EXAMPLES

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use IO::Async::Loop;
 use Net::Async::ControlChannel::Server;
 use Net::Async::ControlChannel::Client;
 use IO::Async::Timer::Periodic;
 
 my $loop = IO::Async::Loop->new;
 my $server = Net::Async::ControlChannel::Server->new(
 	loop => $loop,
 );
 $server->subscribe_to_event(
 	message => sub {
 		my $ev = shift;
 		my ($k, $v, $from) = @_;
 		warn "Server: Had $k => $v from $from\n";
 	},
 	connect => sub {
 		my $ev = shift;
 		my ($remote) = @_;
 		warn "Server: Client connects from $remote\n"
 	},
 	disconnect => sub {
 		my $ev = shift;
 		my ($remote) = @_;
 		warn "Server: Client disconnect from $remote\n"
 	}
 );
 {
 	$loop->add(my $timer = IO::Async::Timer::Periodic->new(
 		interval => 1,
 		on_tick => sub {
 			$server->dispatch('timer.tick' => time)
 		}
 	));
 	$timer->start;
 }
 my $f = $server->start->then(sub {
 	my $server = shift;
 	my $port = $server->port;
 	my $client = Net::Async::ControlChannel::Client->new(
 		loop => $loop,
 		host => $server->host,
 		port => $server->port,
 	);
 	$client->subscribe_to_event(
 		message => sub {
 			my $ev = shift;
 			my ($k, $v, $from) = @_;
 			warn "Client: Had $k => $v\n";
 			$client->dispatch('client.reply' => "$k:$v");
 		}
 	);
 	$client->start->on_done(sub {
 		my $client = shift;
 		$client->dispatch('client.ready' => time);
 	});
 });
 $loop->run;
 warn "finished\n";

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
