package MojoX::Ping;

use strict;
use warnings;

our $VERSION = 0.512;
use base 'Mojo::Base';

use Mojo::IOLoop;
use Socket qw/SOCK_RAW/;
use Time::HiRes 'time';
use IO::Socket::INET qw/sockaddr_in inet_aton/;
use List::Util ();
require Carp;

__PACKAGE__->attr(ioloop => sub { Mojo::IOLoop->singleton });
__PACKAGE__->attr(interval => 0.2);
__PACKAGE__->attr(timeout  => 5);
__PACKAGE__->attr('error');

my $ICMP_PING = 'ccnnnA*';

my $ICMP_ECHOREPLY     = 0;     # Echo Reply
my $ICMP_DEST_UNREACH  = 3;     # Destination Unreachable
my $ICMP_SOURCE_QUENCH = 4;     # Source Quench
my $ICMP_REDIRECT      = 5;     # Redirect (change route)
my $ICMP_ECHO          = 8;     # Echo Request
my $ICMP_TIME_EXCEEDED = 11;    # Time Exceeded

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    # Create RAW socket
    my $socket = IO::Socket::INET->new(
        Proto    => 'icmp',
        Type     => SOCK_RAW,
        Blocking => 0
    ) or Carp::croak "Unable to create icmp socket : $!";

    $self->{_socket} = $socket;

    # Create Poll object
    $self->ioloop->iowatcher->watch(
        $socket,
        sub { $self->_on_read },
        sub { $self->_send_requests }
    );

    $self->ioloop->iowatcher->change($socket, 1, 1);

    # Ping tasks
    $self->{_tasks}     = [];
    $self->{_tasks_out} = [];

    return $self;
}

sub ping {
    my ($self, $host, $times, $cb) = @_;

    my $socket = $self->{_socket};

    my $ip = inet_aton($host);

    my $request = {
        host        => $host,
        times       => $times,
        results     => [],
        cb          => $cb,
        identifier  => int(rand 0x10000),
        destination => scalar sockaddr_in(0, $ip),
    };

    push @{$self->{_tasks}}, $request;

    push @{$self->{_tasks_out}}, $request;

    $self->ioloop->iowatcher->change($socket, 1, 1);

    return $self;
}

sub start {
    my ($self) = @_;
    $self->ioloop->start;

    return $self;
}

sub _send_requests {
    my $self = shift;

    foreach my $request (@{$self->{_tasks_out}}) {
        $self->_send_request($request);
    }

    $self->{_tasks_out} = [];
    $self->ioloop->iowatcher->change($self->{_socket}, 1, 0);
}

sub _on_read {
    my $self = shift;

    my $socket = $self->{_socket};
    $socket->sysread(my $chunk, 4194304, 0);

    my $icmp_msg = substr $chunk, 20;

    my ($type, $identifier, $sequence, $data);

    $type = unpack 'c', $icmp_msg;

    if ($type == $ICMP_ECHOREPLY) {
        ($type, $identifier, $sequence, $data) =
          (unpack $ICMP_PING, $icmp_msg)[0, 3, 4, 5];
    }
    elsif ($type == $ICMP_DEST_UNREACH || $type == $ICMP_TIME_EXCEEDED) {
        ($identifier, $sequence) = unpack('nn', substr($chunk, 52));
    }
    else {

        # Don't mind
        return;
    }

    # Find our task
    my $request =
      List::Util::first { $identifier == $_->{identifier} }
    @{$self->{_tasks}};

    return unless $request;

    # Is it response to our latest message?
    return unless $sequence == @{$request->{results}} + 1;

    if ($type == $ICMP_ECHOREPLY) {

        # Check data
        if ($data eq $request->{data}) {
            $self->_store_result($request, 'OK');
        }
        else {
            $self->_store_result($request, 'MALFORMED');
        }
    }
    elsif ($type == $ICMP_DEST_UNREACH) {
        $self->_store_result($request, 'DEST_UNREACH');
    }
    elsif ($type == $ICMP_TIME_EXCEEDED) {
        $self->_store_result($request, 'TIMEOUT');
    }
}

sub _store_result {
    my ($self, $request, $result) = @_;

    my $results = $request->{results};

    # Clear request specific data
    $self->ioloop->drop(delete $request->{timer}) if exists $request->{timer};

    push @$results, [$result, time - $request->{start}];

    if (@$results == $request->{times} || $result eq 'ERROR') {

        # Cleanup
        my $tasks = $self->{_tasks};
        for my $i (0 .. scalar @$tasks) {
            if ($tasks->[$i] == $request) {
                splice @$tasks, $i, 1;
                last;
            }
        }

        # Testing done
        $request->{cb}->($self, $results);

        undef $request;
    }

    # Perform another check
    else {

        # Setup interval timer before next request
        $self->ioloop->timer(
            $self->interval => sub {
                push @{$self->{_tasks_out}}, $request;
                $self->ioloop->iowatcher->change($self->{_socket}, 1, 1);
            }
        );
    }
}

sub _send_request {
    my ($self, $request) = @_;

    my $checksum   = 0x0000;
    my $identifier = $request->{identifier};
    my $sequence   = @{$request->{results}} + 1;
    my $data       = 'abcdef';

    my $msg = pack $ICMP_PING,
      $ICMP_ECHO, 0x00, $checksum,
      $identifier, $sequence, $data;

    $checksum = $self->_icmp_checksum($msg);

    $msg = pack $ICMP_PING,
      0x08, 0x00, $checksum,
      $identifier, $sequence, $data;

    $request->{data} = $data;

    $request->{start} = time;

    $request->{timer} = $self->ioloop->timer(
        $self->timeout => sub {
            my ($loop) = @_;
            $self->_store_result($request, 'TIMEOUT');
        }
    );

    my $socket = $self->{_socket};

    $socket->send($msg, 0, $request->{destination}) or die "$!";
}

sub _icmp_checksum {
    my ($self, $msg) = @_;

    my $res = 0;
    foreach my $int (unpack "n*", $msg) {
        $res += $int;
    }

    # Add possible odd byte
    $res += unpack('C', substr($msg, -1, 1)) << 8
      if length($msg) % 2;

    # Fold high into low
    $res = ($res >> 16) + ($res & 0xffff);

    # Two times
    $res = ($res >> 16) + ($res & 0xffff);

    return ~$res;
}

1;
__END__

=head1 NAME

MojoX::Ping - asynchronous ping with L<Mojolicious> (DEPRECATED).

=head1 SYNOPSIS

    # Run this code as root
    use MojoX::Ping;

    my $ping = MojoX::Ping->new;

    $ping->ping('google.com', 1, sub {
        my ($ping, $result) = @_;
        print "Result: ", $result->[0][0],
          " in ", $result->[0][1], " seconds\n";
        $ping->ioloop->stop;
    })->start;

=head1 DESCRIPTION

L<MojoX::Ping> is an asynchronous ping for Mojo (DEPRECATED).
Use L<AnyEvent::Ping> instead.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::IOLoop>

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/und3f/mojox-ping

=head1 AUTHOR

Sergey Zasenko, C<undef@cpan.org>.

=head1 CREDITS

=over 2

=item Neil Bowers (NEILB)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Sergey Zasenko

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
