use strict;
use warnings;

use Test::More;
use Test::Exception;
use Plack::Test;

use Plack::App::FakeApache1;

use FindBin::libs;

my $faked_apache1 = Plack::App::FakeApache1->new(
    handler    => "Plack::App::FakeApache1::Handler",
    dir_config => {
        psgi_app        => $FindBin::Bin . '/testapp.psgi',
        locations_from  => $FindBin::Bin . '/testapp.conf',
    },
);
isa_ok($faked_apache1, 'Plack::App::FakeApache1');

my $faked_app = $faked_apache1->to_app;
isa_ok($faked_app, 'CODE');

=for later

test_psgi
    app => $faked_app,

    client => sub {
        my $cb  = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/hello");
        my $res = $cb->($req);
        like $res->content, qr/Hello World/;
    };

=cut


done_testing;
