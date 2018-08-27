use strict;
use warnings;
use Test::More;
use Net::Facebook::Oauth2;

eval "use Test::Requires qw/Plack::Loader Test::TCP Plack::Request/";
plan skip_all => 'Test::Requires required for testing with Test::TCP' if $@;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $access_token = $req->param('access_token');
    my $message = $req->param('message');
    if ($message =~ m/without access token/) {
        is $access_token, 'AccessToken', $message;
    } elsif ($message =~ m/with access token/) {
        is $access_token, 'OtherToken', $message;
    } elsif ($message =~ m/with already set query/) {
        my $query = $env->{QUERY_STRING};
        ok($query !~ /limit=1000\?/);
        ok($query =~ /^limit=1000&access_token/);
    } elsif ($message =~ m/without already set query/) {
        my $query = $env->{QUERY_STRING};
        ok($query =~ /^access_token/);
    } elsif ($message =~ m/Get request with token and query/) {
        my $query = $env->{QUERY_STRING};
        ok($query =~ /^limit=1000&access_token=OtherToken&message/);
    }

    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ];
};

test_tcp(
    client => sub {
        my $port = shift;
        my $fb = Net::Facebook::Oauth2->new(
            application_id => 'your_application_id',
            application_secret => 'your_application_secret',
            callback => 'http://your-domain.com/callback',
            access_token => 'AccessToken',
        );
        my $url = "http://127.0.0.1:$port";
        $fb->post($url, { message => 'Post request without access token' });
        $fb->post("$url?access_token=OtherToken", { message => 'Post request with access token' });
        $fb->get($url, { message => 'Get request without access token' });
        $fb->get("$url?access_token=OtherToken", { message => 'Get request with access token' });

        ##new bug tests -- adding query to another query ?limit=100?access_token
        $fb->get("$url?limit=1000", { message => 'Get request with already set query' });
        $fb->get("$url", { message => 'Get request without already set query' });
        $fb->get("$url?limit=1000&access_token=OtherToken", { message => 'Get request with token and query' });

    },
    server => sub {
        my $port = shift;
        my $server = Plack::Loader->auto(
            port => $port,
            host => '127.0.0.1',
        );
        $server->run($app);
    },
);

done_testing(8);

__END__
