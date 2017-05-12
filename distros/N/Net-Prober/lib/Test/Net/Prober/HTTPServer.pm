package Test::Net::Prober::HTTPServer;
$Test::Net::Prober::HTTPServer::VERSION = '0.16';
use strict;
use IO::Socket::INET;
use IO::Select;

$| = 1;

our $socket;
our @messages;
our $select;
our $data;

sub start {
    $socket = IO::Socket::INET->new(
        LocalPort => 8999,
        Proto     => 'tcp',
    ) or die "unable to create socket: $!\n";
    $select = IO::Select->new($socket);
    reset_messages();
}

sub run {
    my $timeout = shift || 3;
    while (1) {
        my @ready = $select->can_read($timeout);
        last unless @ready;
        $socket->recv($data, 1024);
        last if $data =~ m{quit};
        $data =~ s/^\s+//;
        $data =~ s/\s+$//;
        push @messages, $data;

        # Pretend to be a HTTP server
        if ($data =~ m{^GET}) {
            $socket->send("HTTP/1.1 200 OK\r\n\r\n");
        }
    }
}

sub get_messages {
    process();
    my @to_return = @messages;
    return \@to_return;
};

sub get_and_reset_messages {
    my $ret = get_messages();
    reset_messages();
    return $ret
}

sub reset_messages { @messages = () }

sub stop {
    my $s_send = IO::Socket::INET->new(
        PeerAddr  => '127.0.0.1:8999',
        Proto     => 'tcp',
    ) or die "failed to create client socket: $!\n";
    $s_send->send("quit");
    $s_send->close();
}

sub process {
    stop();
    run();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Net::Prober::HTTPServer

=head1 VERSION

version 0.16

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Cosimo Streppone.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
