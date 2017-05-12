package Net::Signalet;
use strict;
use warnings;
our $VERSION = 0.02;

use Carp ();
use IO::Socket::INET;
use Net::IP::Minimal qw(ip_is_ipv4);


sub _init {
    my ($class, %args) = @_;

    for (qw(saddr daddr)) {
        if (exists $args{$_}) {
            ip_is_ipv4 $args{$_}
                or Carp::croak "$_ is not ipv4: $args{$_}";
        }
    }
}

sub recv {
    my ($self) = @_;
    unless ($self->{sock}) {
        Carp::croak "recv: Not connect";
    }
    my $message = $self->{sock}->getline;
    chomp $message;
    return $message;
}

sub send {
    my ($self, $message) = @_;
    unless ($self->{sock}) {
        Carp::croak "send: Not connect";
    }
    $self->{sock}->print($message."\n");
}

sub run {
    my ($self, %params) = @_;

    if (!exists $params{command} && !exists $params{code}) {
        Carp::croak "Required command or code";
    }
    my $pid = fork;
    unless ($pid) {
        # child process
        if (my $command = $params{command}) {
            if (ref($params{command}) eq 'ARRAY') {
                exec @{$params{command}};
            }
            else {
                exec $command;
            }
        }
        elsif ($params{code}) {
            $params{code}->();
        }
    }
    $self->{worker_pid} = $pid if $pid > 0;
}

sub term_worker {
    my ($self) = @_;
    my $pgrp = getpgrp $self->{worker_pid};
    kill(-15, $pgrp); # send TERM signal to child processes
}

sub close {
    my ($self) = @_;
    close $self->{sock};
}

1;
__END__

=head1 NAME

Net::Signalet - Supervisor for server's launch-and-term synchronization with client's one

=head1 SYNOPSIS

  # command
  server$ signalet -s -b 127.0.0.1 "iperf -s"
  client$ signalet -c 127.0.0.1 -b 127.0.0.1 "iperf -c 127.0.0.1"

  #########################################
  # server
  use Net::Signalet::Server;

  my $server = Net::Signalet::Server->new(
    saddr => '10.0.0.1',
    port  => 12000,
    reuse => 1,
  );

  my $signal = $server->recv; #=> 'START'

  $server->run("iperf -s -B 10.0.0.1");

  $server->send('START_COMP');

  $signal = $server->recv;
  if ($signal eq "FINISH") {
    $server->term_worker;
  }
  $server->close;

  #########################################
  # client
  use Net::Signalet::Client;

  my $client = Net::Signalet::Client->new(
    saddr => '10.0.0.1',
    port  => 12000,
    reuse => 1,
  );

  $client->send("START");

  $client->recv; # "START_COMP"

  $client->run("iperf -c 10.0.0.1 -B 10.0.0.2");

  $client->send("FINISH");

  $client->close;

=head1 DESCRIPTION

Net::Signalet is a supervisor for server's launch-and-term synchronization with client's one.
Net::Signalet helps you proflile server-client model application such as TCP server-client, Web application.

=head1 AUTHOR

Yuuki Tsubouchi E<lt>yuuki@cpan.orgE<gt>

=head1 SEE ALSO

L<Proclet>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
