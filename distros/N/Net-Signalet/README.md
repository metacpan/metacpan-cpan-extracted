# NAME

Net::Signalet - Supervisor for server's launch-and-term synchronization with client's one

# SYNOPSIS

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

# DESCRIPTION

Net::Signalet is a supervisor for server's launch-and-term synchronization with client's one.
Net::Signalet helps you proflile server-client model application such as TCP server-client, Web application.

# AUTHOR

Yuuki Tsubouchi <yuuki@cpan.org>

# SEE ALSO

[Proclet](http://search.cpan.org/perldoc?Proclet)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
