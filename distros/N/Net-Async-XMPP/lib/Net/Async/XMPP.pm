package Net::Async::XMPP;
# ABSTRACT: Asynchronous support for the Extensible Message Passing Protocol
use strict;
use warnings;

our $VERSION = '0.003';

1;

__END__

=head1 NAME

Net::Async::XMPP - asynchronous XMPP client based on L<Protocol::XMPP> and L<IO::Async::Protocol::Stream>.

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::XMPP;
 my $loop = IO::Async::Loop->new;
 my $client = Net::Async::XMPP::Client->new(
	on_message		=> sub {
		my ($client, $msg) = @_;
		warn "Message from " . $msg->from . " subject " . $msg->subject . " body " . $msg->body;
		$msg->reply(
			body => 'Message received: ' . $msg->body
		);
	},
	on_contact_request	=> sub {
		my ($client, $contact) = @_;
		warn "Contact request from " . $contact->jid;
	},
	on_presence		=> sub {
		my ($client, $contact) = @_;
		warn "Had a presence update from " . $contact->jid;
	},
 );
 $loop->add($client);
 $client->login(
	jid	=> 'user@example.com',
	password => $ENV{NET_ASYNC_XMPP_PASSWORD},
 );
 $loop->run;

=head1 DESCRIPTION

See the L<Net::Async::XMPP::Client> or L<Net::Async::XMPP::Server> subclasses for more details.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 CONTRIBUTORS

With thanks to the following for contribution:

=over 4

=item * Arthur Axel "fREW" Schmidt for testing, documentation, pointing out some of my mistakes,
that sort of thing

=item * Paul "LeoNerd" Evans for adding L<Future>s to L<IO::Async> (and writing both in the first place)

=item * Matt Trout for testing early versions

=back

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
