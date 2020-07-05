use strict;
use warnings;
use Test::Arrow;

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

test_psgi
    app    => builder {
        enable 'Acme::AAHTTPHeader';
        sub { [ 200, [ 'Content-Type' => 'text/plain' ], ['OK'] ] };
    },
    client => sub {
        my $cb = shift;
        {
            my $req = GET '/';
            my $res = $cb->($req);
            t->is($res->content, 'OK');
            t->got($res->header('x-happy001'))
                ->expect('                                       .')->is;
            t->got($res->header('x-happy018'))
                ->expect(q!--------------------------------------------------------------------------!)->is;
        }
    };

my $app = builder {
    enable 'Acme::AAHTTPHeader',
        key => 'be-easy',
        aa => <<'_AA_';
                  ,,__
        ..  ..   / o._)                   .---.
       /--'/--\  \-'||        .----.    .'     '.
      /        \_/ / |      .'      '..'         '-.
    .'\  \__\  __.'.'     .'          i-._
      )\ |  )\ |      _.'
     // \\ // \\
    ||_  \\|_  \\_
mrf '--' '--'' '--'
_AA_
    sub { [ 200, [ 'Content-Type' => 'text/plain' ], ['OK'] ] };
};

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;
        {
            my $req = GET '/';
            my $res = $cb->($req);
            t->is($res->content, 'OK');
            t->got($res->header('x-be-easy001'))
                ->expect('                  ,,__')->is;
            t->got($res->header('x-be-easy009'))
                ->expect(q!mrf '--' '--'' '--'!)->is;
        }
    };

done;
