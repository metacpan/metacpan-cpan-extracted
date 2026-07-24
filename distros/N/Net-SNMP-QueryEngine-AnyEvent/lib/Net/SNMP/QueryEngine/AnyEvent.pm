package Net::SNMP::QueryEngine::AnyEvent;

use 5.006;
use strict;
use warnings;

our $VERSION = 'v1.1.0';

use AnyEvent;
use AnyEvent::Handle;
use Carp ();
use Data::MessagePack;
use Data::MessagePack::Stream;
use Scalar::Util qw(weaken);

use constant RT_SETOPT    => 1;
use constant RT_GETOPT    => 2;
use constant RT_INFO      => 3;
use constant RT_GET       => 4;
use constant RT_GETTABLE  => 5;
use constant RT_DEST_INFO => 6;
use constant RT_REPLY    => 0x10;
use constant RT_ERROR    => 0x20;

sub new
{
	my ($class, %args) = @_;
	my %known = map { $_ => 1 } qw(connect reconnect on_connect on_disconnect);
	for my $k (keys %args) {
		Carp::croak("unknown constructor argument \"$k\"")
			unless $known{$k};
	}
	my $self = bless {
		connect       => $args{connect} || ["127.0.0.1", 7667],
		reconnect     => defined $args{reconnect} ? $args{reconnect} : 1,
		on_connect    => $args{on_connect},
		on_disconnect => $args{on_disconnect},
		condvar   => AnyEvent->condvar,
		pending   => 0,
		mp        => Data::MessagePack->new->prefer_integer,
		cid       => int rand 1000000,
		cb        => {},
		inflight  => {},
		queue     => [],
		connected => 0,
		down      => 0,
		dead      => 0,
	}, $class;
	$self->_connect;
	return $self;
}

sub _connect
{
	my $self = shift;
	$self->{reconnect_timer} = undef;
	weaken(my $weak = $self);
	$self->{up} = Data::MessagePack::Stream->new;
	$self->{handle} = AnyEvent::Handle->new(
		connect          => $self->{connect},
		on_connect       => sub {
			my $s = $weak or return;
			$s->{connected} = 1;
			$s->{down} = 0;
			$s->{on_connect}->($s) if $s->{on_connect};
			$s->_flush_queue;
		},
		on_connect_error => sub { $weak->_disconnected($_[0], $_[1]) if $weak },
		on_error         => sub { $weak->_disconnected($_[0], $_[2]) if $weak },
		on_eof           => sub { $weak->_disconnected($_[0], "connection closed") if $weak },
		on_read          => sub { $weak->read_handler($_[0]) if $weak },
	);
}

sub _disconnected
{
	my ($self, $h, $reason) = @_;
	return unless $self->{handle} && $h == $self->{handle};
	$self->{handle}->destroy;
	$self->{handle} = undef;
	$self->{connected} = 0;

	if (!$self->{down}) {
		$self->{down} = 1;
		$self->{on_disconnect}->($self, $reason) if $self->{on_disconnect};
	}

	$self->_deliver($_, 0, "connection lost: $reason")
		for sort { $a <=> $b } keys %{$self->{inflight}};

	if ($self->{reconnect} > 0) {
		weaken(my $weak = $self);
		$self->{reconnect_timer} = AnyEvent->timer(
			after => $self->{reconnect},
			cb    => sub { $weak->_connect if $weak },
		);
	} else {
		$self->{dead} = 1;
		my $queue = $self->{queue};
		$self->{queue} = [];
		$self->_deliver($_->[0], 0, "not connected") for @$queue;
	}
}

sub _flush_queue
{
	my $self = shift;
	while ($self->{connected} && @{$self->{queue}}) {
		my $q = shift @{$self->{queue}};
		$self->{inflight}{$q->[0]} = 1;
		$self->{handle}->push_write($q->[1]);
	}
}

sub when_done
{
	my ($self, $host, $port, $cb) = @_;
	my $hp = "$host:$port";
	$self->{hpcb}{$hp} = $cb;
}

sub wait
{
	my $self = shift;
	return unless $self->{pending};
	$self->{condvar}->recv;
}

sub cmd
{
	my ($self, $cb, @cmd) = @_;
	my $cid = $cmd[1];
	$self->{cb}{$cid} = $cb;
	$self->{pending}++;
	if ($self->{pending} == 1 && $self->{condvar}->ready) {
		# XXX "reset" a condvar so "wait" can be correctly called again
		$self->{condvar} = AnyEvent->condvar;
	}
	if ($self->{dead}) {
		weaken(my $weak = $self);
		$self->{failfast}{$cid} = AnyEvent->timer(after => 0, cb => sub {
			my $s = $weak or return;
			delete $s->{failfast}{$cid};
			$s->_deliver($cid, 0, "not connected");
		});
	} elsif ($self->{connected}) {
		$self->{inflight}{$cid} = 1;
		$self->{handle}->push_write($self->{mp}->pack(\@cmd));
	} else {
		push @{$self->{queue}}, [$cid, $self->{mp}->pack(\@cmd)];
	}
}

sub read_handler
{
	my ($self, $h) = @_;

	$self->{up}->feed($h->{rbuf});
	$h->{rbuf} = "";

	while ($self->{up}->next) {
		my $data = $self->{up}->data;

		if (ref($data) ne "ARRAY" || @$data < 3 || !$self->{cb}{$data->[1]}) {
		} else {
			$self->_deliver($data->[1], $data->[0] & RT_REPLY, $data->[2]);
		}
	}
}

sub _deliver
{
	my ($self, $cid, $ok, $result) = @_;
	my $cb = delete $self->{cb}{$cid} or return;
	delete $self->{inflight}{$cid};
	$cb->($self, $ok, $result);

	my $hp = delete $self->{cid2hp}{$cid};
	if ($hp && $self->{hp}{$hp}) {
		$self->{hp}{$hp}--;
		if ($self->{hp}{$hp} <= 0) {
			$self->{hpcb}{$hp}->($self) if $self->{hpcb}{$hp};
		}
	}

	$self->{pending}--;
	if ($self->{pending} <= 0) {
		$self->{condvar}->send;
	}
}

sub DESTROY
{
	my $self = shift;
	$self->{reconnect_timer} = undef;
	$self->{handle}->destroy if $self->{handle};
}

sub setopt
{
	my ($self, $host, $port, $opts, $cb) = @_;
	$self->cmd($cb, RT_SETOPT, ++$self->{cid}, $host, $port, $opts);
}

sub getopt
{
	my ($self, $host, $port, $cb) = @_;
	$self->cmd($cb, RT_GETOPT, ++$self->{cid}, $host, $port);
}

sub get
{
	my ($self, $host, $port, $oids, $cb) = @_;

	my $cid = ++$self->{cid};
	my $hp = "$host:$port";
	$self->{hp}{$hp}++;
	$self->{cid2hp}{$cid} = $hp;

	$self->cmd($cb, RT_GET, $cid, $host, $port, $oids);
}

sub gettable
{
	my ($self, $host, $port, $oid, $max_rep, $cb) = @_;

	my $cid = ++$self->{cid};
	my $hp = "$host:$port";
	$self->{hp}{$hp}++;
	$self->{cid2hp}{$cid} = $hp;

	if ($cb) {
		$self->cmd($cb, RT_GETTABLE, $cid, $host, $port, $oid, $max_rep);
	} else {
		$self->cmd($max_rep, RT_GETTABLE, $cid, $host, $port, $oid);
	}
}

sub info
{
	my ($self, $cb) = @_;
	$self->cmd($cb, RT_INFO, ++$self->{cid});
}

sub dest_info
{
	my ($self, $cb, $host, $port) = @_;
	$self->cmd($cb, RT_DEST_INFO, ++$self->{cid}, $host, $port);
}

=head1 NAME

Net::SNMP::QueryEngine::AnyEvent - multiplexing SNMP query engine client using AnyEvent

=head1 VERSION

Version v1.1.0

=head1 SYNOPSIS

This is an AnyEvent-flavored Perl client for snmp-query-engine,
a multiplexing SNMP query engine.

    use Net::SNMP::QueryEngine::AnyEvent;

    my $sqe = Net::SNMP::QueryEngine::AnyEvent->new;

    $sqe->setopt("127.0.0.1", 161, { community => "meow" }, sub {});
	$sqe->when_done("127.0.0.1", 161, sub { print "done with localhost\n" });

    $sqe->gettable("127.0.0.1", 161, "1.3.6.1.2.1.1", sub {
      my ($h, $ok, $r) = @_;
      for my $t (@$r) {
        print "$t->[0] => $t->[1]\n";
      }
    });

    $sqe->get("127.0.0.1", 161,
      ["1.3.6.1.2.1.1.5.0", "1.3.6.1.2.1.25.1.1.0"],
      sub {
        my ($h, $ok, $r) = @_;
        print "Hostname: $r->[0][1]\n";
        print "Uptime  : $r->[1][1]\n";
    });

    $sqe->wait;

=head1 METHODS

=head2 new

Constructor.

    Net::SNMP::QueryEngine::AnyEvent->new(
        connect       => ["127.0.0.1", 7667],
        reconnect     => 1,
        on_connect    => sub { my ($sqe) = @_; ... },
        on_disconnect => sub { my ($sqe, $reason) = @_; ... },
    );

All arguments are optional.  By default, connects to
snmp-query-engine listening on localhost, port 7667;
override this by specifying a "connect" argument.

"reconnect" is the number of seconds, possibly fractional,
between reconnection attempts after the connection to the
daemon is lost or cannot be established; it defaults to 1.  Requests issued while the
connection is down are queued and sent, in order, once the
connection is re-established.  Requests that were already sent
but not yet answered when the connection was lost fail: their
callbacks are called with a false $ok and "connection lost: ..."
as the result.

When "reconnect" is 0, the client does not reconnect.  After
the first disconnect every request, queued or new, fails with
a false $ok and "not connected" as the result.

"on_connect" is called with the client object as its only
argument every time a connection to the daemon is established,
including the first one.  Requests issued from this callback
are sent before any queued requests, which makes it the right
place to re-establish per-destination options with setopt().

"on_disconnect" is called with the client object and the
disconnect reason whenever the connection to the daemon is
lost.  It is called before the callbacks of the requests that
fail due to the disconnect.

=head2 when_done

Execute provided callback when there are no unfinished
get or gettable queries towards a specified host:port.

=head2 wait

Enters event loop until there are no unanswered queries.
Can be called multiple times.

=head2 setopt

Performs setopt request.

=head2 getopt

Performs getopt request.

=head2 get

Performs get request for arbitrary number
of OIDs.

=head2 gettable

Performs gettable request.

=head2 info

Performs info request.

=head2 dest_info

Performs dest_info request.

=head1 AUTHOR

Anton Berezin, C<< <tobez at tobez.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-snmp-queryengine-anyevent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SNMP-QueryEngine-AnyEvent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

The snmp-query-engine daemon can be found on github
at L<https://github.com/tobez/snmp-query-engine>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SNMP::QueryEngine::AnyEvent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SNMP-QueryEngine-AnyEvent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SNMP-QueryEngine-AnyEvent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SNMP-QueryEngine-AnyEvent>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SNMP-QueryEngine-AnyEvent/>

=back


=head1 ACKNOWLEDGEMENTS

This work is in part sponsored by Telia Denmark.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2015, Anton Berezin "<tobez@tobez.org>". All rights
reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
