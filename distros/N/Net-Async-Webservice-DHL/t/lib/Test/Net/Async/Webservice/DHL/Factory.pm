package Test::Net::Async::Webservice::DHL::Factory;
use strict;
use warnings;
use File::Spec;
use Test::More;
use Net::Async::Webservice::DHL;
use Test::Net::Async::Webservice::DHL::NoNetwork;
use Test::Net::Async::Webservice::DHL::Tracing;
use Test::Net::Async::Webservice::DHL;

sub from_config {
    eval { require IO::Async::Loop; require Net::Async::HTTP }
        or do {
            plan(skip_all=>'this test only runs with IO::Async and Net::Async::HTTP');
            exit(0);
        };

    my $loop = IO::Async::Loop->new;

    my $dhl = Net::Async::Webservice::DHL->new({
        config_file => Test::Net::Async::Webservice::DHL->conf_file,
        loop => $loop,
    });
    return ($dhl,$loop);
}

sub from_config_sync {
    eval { require LWP::UserAgent }
        or do {
            plan(skip_all=>'this test only runs with LWP::UserAgent');
            exit(0);
        };

    my $ua = LWP::UserAgent->new;

    my $dhl = Net::Async::Webservice::DHL->new({
        config_file => Test::Net::Async::Webservice::DHL->conf_file,
        user_agent => $ua,
    });
    return ($dhl,$ua);
}

sub from_config_tracing {
    eval { require IO::Async::Loop; require Net::Async::HTTP }
        or do {
            plan(skip_all=>'this test only runs with IO::Async and Net::Async::HTTP');
            exit(0);
        };

    my $loop = IO::Async::Loop->new;
    my $ua = Test::Net::Async::Webservice::DHL::Tracing->new({loop=>$loop});
    my $dhl = Net::Async::Webservice::DHL->new({
        config_file => Test::Net::Async::Webservice::DHL->conf_file,
        user_agent => $ua,
    });
    return ($dhl,$ua);
}

sub without_network {
    my ($args) = @_;
    my $ua = Test::Net::Async::Webservice::DHL::NoNetwork->new();
    my $ret = Net::Async::Webservice::DHL->new({
        username => 'testid',
        password => 'testpass',
        user_agent => $ua,
        %{$args//{}},
    });
    return ($ret,$ua);
}

1;
