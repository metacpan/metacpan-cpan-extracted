package Net::Async::Pusher;
# ABSTRACT: use pusher.com with IO::Async
use strict;
use warnings;

our $VERSION = '0.005';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::Pusher - support for pusher.com streaming event API

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use feature qw(say);
 # For more details, enable this
 # use Log::Any::Adapter qw(Stdout);
 use IO::Async::Loop;
 use Net::Async::Pusher;
 my $loop = IO::Async::Loop->new;
 $loop->add(
 	my $pusher = Net::Async::Pusher->new
 );
 say "Connecting to pusher.com via websocket...";
 my $sub = $pusher->connect(
 	key => 'de504dc5763aeef9ff52'
 )->then(sub {
 	my ($conn) = @_;
 	say "Connection established. Opening channel.";
 	$conn->open_channel('live_trades')
 })->then(sub {
 	my ($ch) = @_;
 	say "Have channel, setting up event handler for 'trade' event.";
 	$ch->subscribe(trade => sub {
 		my ($ev, $data) = @_;
 		say "New trade - price " . $data->{price} . ", amount " . $data->{amount};
 	});
 })->get;
 say "Subscribed and waiting for events...";
 $loop->run;
 $sub->()->get;

=head1 DESCRIPTION

Provides basic integration with the L<https://pusher.com|Pusher> API.

=cut

use Net::Async::Pusher::Connection;

=head2 connect

Connects to a server using a key.

 my $conn = $pusher->connect(
  key => 'abc123'
 )->get;

Resolves to a L<Net::Async::Pusher::Connection>.

=cut

sub connect {
    my ($self, %args) = @_;
    $self->add_child(
        my $conn = Net::Async::Pusher::Connection->new(
            key => $args{key} // die "need a key"
        )
    );
    $conn->connect
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2021. Licensed under the same terms as Perl itself.
