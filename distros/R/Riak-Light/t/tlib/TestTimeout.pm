#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TestTimeout;

use Test::More;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Test::TCP;
use POSIX qw(ETIMEDOUT ECONNRESET strerror);
use Exporter 'import';
use feature ':5.12';

require bytes;

@EXPORT_OK = qw(test_timeout test_normal_wait);

sub create_server_with_timeout {
    my $in_timeout = shift;

    Test::TCP->new(
        code => sub {
            my $port   = shift;
            my $socket = IO::Socket::INET->new(
                Listen    => 5,
                Timeout   => 1,
                Reuse     => 1,
                Blocking  => 1,
                LocalPort => $port
            ) or die "ops $!";

            my $message = pack( 'c', 2 );

            my $buffer;
            while (1) {
                my $client = $socket->accept();

                sleep($in_timeout) if $in_timeout;
                if ( $client->sysread( $buffer, 5 ) ) {
                    my $response =
                      pack( 'N a*', bytes::length($message), $message );

                    $client->syswrite($response);
                    sleep(1);
                }

                $client->close();
            }
        },
    );
}

sub test_timeout {
    my $provider = shift;
    my $provider_name = $provider // "undef";

    subtest
      "Test timeout provider $provider, when the server wait 2 seconds to send the response"
      => sub {
        plan tests => 2;

        my $server = create_server_with_timeout(2);

        my $client = Riak::Light->new(
            host             => '127.0.0.1',
            port             => $server->port,
            out_timeout      => 0.1,
            timeout_provider => $provider
        );

        my $etimeout = strerror(ETIMEDOUT);
        my $ereset   = strerror(ECONNRESET);
        throws_ok { $client->ping() } qr/Error in 'ping' : $etimeout/,
          "using provider $provider_name, should die in case of timeout";
        throws_ok { $client->ping() }
        qr/Error in 'ping' : $ereset/,
          "using provider $provider_name, should close the connection";
      };
}

sub test_normal_wait {
    my $provider = shift;
    my $timeout  = shift;

    $timeout //= 0;
    my $provider_name = $provider // "undef";

    subtest
      "Test timeout provider $provider_name when the server wait $timeout (timeout 2 seconds, should not die)"
      => sub {
        plan tests => 1;

        my $server = create_server_with_timeout($timeout);

        my $client = Riak::Light->new(
            host             => '127.0.0.1',
            port             => $server->port,
            timeout          => 2,
            timeout_provider => $provider
        );

        $provider //= "none";

        lives_ok { $client->ping() } "using provider $provider, should wait";
      };
}

1;
