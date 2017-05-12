use strict;
use warnings;
use Test::More;

use Digest::SHA;

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $content = [qw/hello world/];
my $sha     = Digest::SHA->new->add(@$content)->hexdigest;

my $app = sub {
    [   '200',
        [   'Content-Type'  => 'text/html',
            'Last-Modified' => 'Wed, 07 Apr 2010 15:07:04 GMT'
        ],
        $content
    ];
};

my $handler = builder {
    enable "Plack::Middleware::ETag";
    $app;
};

my $handler_with_last_mod = builder {
    enable "Plack::Middleware::ETag", check_last_modified_header => 1;
    $app;
};

# Don't break backwards compat
test_psgi
    app    => $handler,
    client => sub {
    my $cb = shift;
    {
        my $req = GET "http://localhost/";
        my $res = $cb->($req);
        ok $res->header('ETag');
        ok $res->header('Last-Modified');
        is $res->header('ETag'), $sha;
    }
    };

# With check_last_modified_header there should be no etag set
test_psgi
    app    => $handler_with_last_mod,
    client => sub {
    my $cb = shift;
    {
        my $req = GET "http://localhost/";
        my $res = $cb->($req);
        ok !$res->header('ETag');
        ok $res->header('Last-Modified');
    }
    };

done_testing;
