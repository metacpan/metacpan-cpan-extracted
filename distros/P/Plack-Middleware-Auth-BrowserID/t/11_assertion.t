#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Net::Ping;


my $builder = sub {
    use Plack::Builder;

    builder {
        enable 'Session', store => 'File';

        mount '/auth' => builder {
            enable 'Auth::BrowserID', audience => 'http://localhost/';
        };

        mount '/' => builder {
            sub {
                return [
                    200, [ 'Content-Type' => 'text/plain' ],
                    ["Hello"]
                ];
              }
        };
    };
};

my $p = Net::Ping->new( "tcp", 2 );
$p->port_number( scalar( getservbyname( "https", "tcp" ) ) );
my $may_make_connections = $p->ping( 'verifier.login.persona.org', 2 );

SKIP: {
    skip "https://verifier.login.persona.org connection isn't available", 4
      unless $may_make_connections;

    my $app = $builder->();
    ok $app;

    test_psgi app => $app, client => sub {
        my $cb = shift;

        my $res = $cb->( GET "http://localhost/" );
        is $res->code,    200;
        is $res->content, "Hello";

        my $req = POST "http://localhost/auth/signin",
          "assertion" => "invalid assertion";
        $res = $cb->($req);
        is $res->code,    500;
        is $res->content, "nok";
    };
}

done_testing;

__END__
