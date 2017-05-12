package testlib::Util;
use strict;
use warnings;
use AnyEvent;
use Exporter qw(import);
use Test::More;
use Net::EmptyPort qw(empty_port);  ## should it be in Test::Requires?

our @EXPORT_OK = qw(set_timeout run_server);

my $TIMEOUT_DEFAULT_SEC = 10;

sub set_timeout {
    my ($timeout) = @_;
    $timeout ||= $TIMEOUT_DEFAULT_SEC;
    my $w; $w = AnyEvent->timer(after => $timeout, cb => sub {
        undef $w;
        fail("Timeout");
        exit 2;
    });
}

sub run_server {
    my ($server_runner, $app) = @_;
    my $port = empty_port();
    return ($port, $server_runner->($port, $app));
}

1;
