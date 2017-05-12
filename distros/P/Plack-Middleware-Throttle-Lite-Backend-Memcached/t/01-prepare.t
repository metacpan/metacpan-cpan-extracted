use strict;
use warnings;
use Test::More;
use Test::Exception;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Throttle::Lite::Backend::Memcached;

can_ok 'Plack::Middleware::Throttle::Lite::Backend::Memcached', qw(
    mc
    reqs_done
    increment
);

# simple application
my $app = sub { [ 200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ] ] };

my $appx = sub {
    my ($args) = @_;
    builder {
        enable 'Throttle::Lite', backend => [ 'Memcached' => $args ];
        $app
    }
};

my @failed = (
    'bogus-servers' => { servers => [ 'bogus.alpha:0', 'bogus.bravo:0', 'bogus.charlie:0' ] },
    'undef-servers' => { },
);

while (my ($set, $args) = splice(@failed, 0, 2)) {
    throws_ok { $appx->($args) } qr/Cannot get memcached handle/, 'Caught exception on args-set [' . $set . ']';
}

done_testing();
