use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Builder;

use Plack::App::OpenVPN::Status;

my $app = builder {
    mount '/v1' => Plack::App::OpenVPN::Status->new(status_from => 't/status-v1.log');
    mount '/v2' => Plack::App::OpenVPN::Status->new(status_from => 't/status-v2.log');
    mount '/v3' => Plack::App::OpenVPN::Status->new(status_from => 't/status-v3.log');
};

my @tests = (
    (GET '/v1') => sub {
        is   $_->code,    200,                          'Status V1: response code';
        like $_->content, qr|cadvecisvo|,               'Status V1: common name';
        like $_->content, qr|00:ff:de:ad:be:ef|,        'Status V1: virtual address';
        like $_->content, qr|Tue Dec  4 11:05:56 2012|, 'Status V1: status date, time';
    },
    (GET '/v2') => sub {
        is   $_->code,    200,                          'Status V2: response code';
        like $_->content, qr|cadvecisvo|,               'Status V2: common name';
        like $_->content, qr|00:ff:de:ad:be:ef|,        'Status V2: virtual address';
        like $_->content, qr|Wed Dec  5 21:15:35 2012|, 'Status V2: status date, time';
    },
    (GET '/v3') => sub {
        is   $_->code,    200,                          'Status V3: response code';
        like $_->content, qr|cadvecisvo|,               'Status V3: common name';
        like $_->content, qr|00:ff:de:ad:be:ef|,        'Status V3: virtual address';
        like $_->content, qr|Wed Dec  5 21:25:58 2012|, 'Status V3: status date, time';
    },
);

while (my ($req, $test) = splice(@tests, 0, 2) ) {
    test_psgi
        app    => $app,
        client => sub {
            my ($cb) = @_;
            my $res = $cb->($req);
            local $_ = $res;
            $test->();
        };
}

done_testing;
