use strict;
use warnings;

use lib 't/lib';
use Test::More;

use Plack::Request;
use Try::Tiny;
use TestDataHandler;
use OAuth::Lite2::Server::GrantHandler::ServerState;
use OAuth::Lite2::Util qw(build_content);

my $dh = TestDataHandler->new;

my $action = OAuth::Lite2::Server::GrantHandler::ServerState->new;

sub test_success {
    my $params = shift;
    my $expected = shift;
    my $request = Plack::Request->new({
        REQUEST_URI    => q{http://example.org/token},
        REQUEST_METHOD => q{GET},
        QUERY_STRING   => build_content($params),
    });
    my $dh = TestDataHandler->new(request => $request);
    my $res; try {
        $res = $action->handle_request($dh);
    } catch {
        my $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };

    is($res->{server_state}, $expected->{server_state});
    is($res->{expires_in}, $expected->{expires_in});
}

&test_success({
    client_id     => q{foo},
}, {
    server_state => q{server_state_0},
    expires_in   => q{3600},
});

done_testing;
