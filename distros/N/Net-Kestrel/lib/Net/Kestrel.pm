package Net::Kestrel;
{
  $Net::Kestrel::VERSION = '0.08';
}
use Moose;

use IO::Socket;

# ABSTRACT: Kestrel Client for Perl


has 'debug' => (
    is => 'rw',
    isa => 'Bool',
    predicate => 'is_debug'
);


has 'host' => (
    is => 'ro',
    isa => 'Str',
    default => '127.0.0.1'
);


has 'port' => (
    is => 'ro',
    isa => 'Int',
    default => 2222
);


has 'timeout' => (
    is => 'ro',
    isa => 'Int',
    default => 3
);

has _connection => (
    is => 'rw',
    isa => 'IO::Socket::INET',
    lazy_build => 1
);

sub _build__connection {
    my ($self) = @_;

    $SIG{PIPE} = sub { die 'Connection to '.$self->host.' port '.$self->port.' went away! Server down?' };

    my $sock = IO::Socket::INET->new(
        PeerAddr => $self->host,
        PeerPort => $self->port,
        Proto => 'tcp',
        Timeout => $self->timeout
    );

    if(!defined($sock)) {
        die('Failed to connect to '.$self->host.' port '.$self->port);
    }

    return $sock;
}


sub confirm {
    my ($self, $queue, $count) = @_;

    my $cmd = "confirm $queue $count";
    return $self->_write_and_read($cmd);
}


sub delete {
    my ($self, $queue) = @_;

    my $cmd = "delete $queue";
    return $self->_write_and_read($cmd);
}


sub flush {
    my ($self, $queue) = @_;

    my $cmd = "flush $queue";
    $self->_write_and_read($cmd);
}


sub get {
    my ($self, $queue, $timeout) = @_;

    my $cmd = "get $queue";
    if(defined($timeout)) {
        $cmd .= " $timeout";
    }
    return $self->_write_and_read($cmd);
}


sub peek {
    my ($self, $queue, $timeout) = @_;

    my $cmd = "peek $queue";
    if(defined($timeout)) {
        $cmd .= " $timeout";
    }

    return $self->_write_and_read($cmd);
}


sub put {
    my ($self, $queue, $thing) = @_;

    my $cmd = "put $queue:\n$thing\n";
    $self->_write_and_read($cmd);
}


sub stats {
    my ($self) = @_;

    my $cmd = "stats";
    $self->_write_and_read($cmd);
}

sub _write_and_read {
    my ($self, $cmd) = @_;

    my $sock = $self->_connection;

    print STDERR "SENDING: $cmd\n" if $self->is_debug;
    $sock->send($cmd."\n");

    my $resp = undef;
    while(my $line = <$sock>) {
        $resp .= $line;
        # There isn't ONE way to know that kestrel is done talking to us. So
        # we'll use the same logic we use below to detect the type of information
        # we got back.  Not optimal, but I don't purport to be very good at
        # socket programming.
        last if $line =~ /^\+(\d+)\n$/;
        last if $line =~ /END\n$/;
        last if $line =~ /^-(.*)\n$/;
        last if $line =~ /^\*\n$/;
        last if $line =~ /^:.*\n$/;
    }
    print STDERR "RESPONSE: $resp\n" if $self->is_debug;

    if($resp =~ /^:(.*)\n$/) {
        # Strip out "item" delimiters
        $resp = $1;
    } elsif($resp =~ /^\+(\d+)\n$/) {
        # Success with a count
        $resp = $1;
    } elsif($resp =~ /^-(.*)\n$/) {
        # Crap, an error.  throw it
        die $1;
    } elsif($resp =~ /^\*\n$/) {
        $resp = undef;
    }

    return $resp;
}

1;



=pod

=head1 NAME

Net::Kestrel - Kestrel Client for Perl

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Net::Kestrel;

    my $queuename = 'myqueue';

    my $kes = Net::Kestrel->new; # defaults to host => 127.0.0.1, port => 2222
    $kes->put($queuename, 'foobar');
    # ... later

    # take a peek, doesn't remove the item
    my $item = $kes->peek($queuename);

    # get the item out, beginning a transaction
    my $real_item = $kes->get($queuename);
    # ... do something with it

    # then confirm we finished it so kestrel can discard it
    $kes->confirm($queuename, 1); # since we got one item

=head1 DESCRIPTION

Net::Kestrel is a B<text protocol> client for L<https://github.com/robey/kestrel>.

=head1 ATTRIBUTES

=head2 debug

=head2 host

The ip address of the Kestrel host you want to connect to.

=head2 port

The port to connect to.  Defaults to 2222.

=head2 timeout

The timeout value for operations.  Defaults to 3 seconds.

=head1 METHODS

=head2 confirm ($queuename, $count)

Confirms $count items from the queue.

=head2 delete ($queuename)

Delete the specified queue.

=head2 flush ($queuename)

Flush (empty) the specified queue.

=head2 get ($queuename, $timeout_in_millis)

Gets an item from the queue.  Note that this implicitly begins a transaction
and the item must be C<confirm>ed or kestrel will give the item to another
client when you disconnect.  Optionally you may provide a timeout (in
milliseconds).  Net::Kestrel will block for that long waiting for a value in
the queue.

=head2 peek ($queuename, $timeout_in_millis)

Peeks into the specified queue and "peeks" at the next item.  Optionally you
may provide a timeout (in milliseconds).  Net::Kestrel will block for that
long waiting for a value in the queue.

=head2 put ($queuename, $string)

Puts the provided payload into the specified queue.

=head2 stats

Returns stats from the kestrel instance

=head1 NOTES

=head2 Incomplete

B<This module is brand new and is likely missing features.>

=head2 Protocol

Net::Kestrel speaks Kestrel's text protocol only at present.

=head2 Error Handling

Kestrel returns errors in the form of:

  -Error string

When any command returns a string like this, Net::Kestrel will die with that
message.  Therefore you should C<eval> any methods you care to deal with
errors for.

=head1 CONTRIBUTORS

Me

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


