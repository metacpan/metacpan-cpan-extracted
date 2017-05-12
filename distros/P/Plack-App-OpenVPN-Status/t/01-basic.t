use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Builder;

use Plack::App::OpenVPN::Status;

can_ok 'Plack::App::OpenVPN::Status', qw/default_view renderer status_from prepare_app call openvpn_status/;

my $app = builder {
    mount '/foo' => Plack::App::OpenVPN::Status->new; # undefined status source
    mount '/bar' => Plack::App::OpenVPN::Status->new(status_from => 't/nonexistent.log');
    mount '/baz' => Plack::App::OpenVPN::Status->new(status_from => 't/status-empty.log');
};

my @tests = (
    (GET '/foo') => sub {
        is   $_->code,    200,                                     'No status: response code';
        like $_->content, qr|status file is not set|,              'No status: message';
    },
    (GET '/bar') => sub {
        is   $_->code,    200,                                     'Nonexistent status: Response code';
        like $_->content, qr|does not exist or unreadable|,        'Nonexistent status: message';
    },
    (GET '/baz') => sub {
        is   $_->code,    200,                                     'Correct status (with no users): response code';
        like $_->content, qr|There is no connected OpenVPN users|, 'Correct status (with no users): content';
        like $_->content, qr|Tue Dec  4 02:31:18 2012|,            'Correct status (with no users): status date, time';
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
