use strict;
use warnings;
use Test::More tests => 5;

use HTTP::Date;
use HTTP::Request::Common;
use JavaScript::Ectype;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::JavaScript::Ectype;

my $handler = builder {
    enable "Plack::Middleware::JavaScript::Ectype",
        root => './t/static/js/',prefix => '/ectype/',minify => 1;
    sub {
        [200,['Content-Type'=> 'text/plain','Content-Length'=> 2],['ok']]
    }
};

test_psgi 
    app => $handler,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new( GET => "http://localhost/" );
            my $res = $cb->($req);
            ok($res->code == 200 );
        }
        {
            my $req = HTTP::Request->new( GET => "http://localhost/ectype/org.cpan.no_such_file" );
            my $res = $cb->($req);
            ok($res->code == 404 );
        }
        {
            my $req = HTTP::Request->new( GET => "http://localhost/ectype/org.cpan" );
            my $res = $cb->($req);
            ok($res->code == 200 );
            is(
                $res->content,
                JavaScript::Ectype->convert(
                    path   => './t/static/js/',
                    target => 'org.cpan',
                    minify => 1
                )
            );
        }
        {
            my $req = HTTP::Request->new( GET => "http://localhost/ectype/org.cpan" );
            $req->header( q|If-Modified-Since| => HTTP::Date::time2str( time() ));
            my $res = $cb->($req);
            ok($res->code == 304 );
        }
    };
