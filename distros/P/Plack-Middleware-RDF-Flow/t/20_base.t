use strict;
use warnings;

use lib 't';
use TestPlackApp;

use Test::More;
use Plack::Test;
use Plack::Builder;
use RDF::Flow qw(rdflow_uri);

use RDF::Flow::Dummy;

use Data::Dumper;

#use Log::Contextual::SimpleLogger;
#use Log::Contextual qw( :log ),
#     -logger => Log::Contextual::SimpleLogger->new({ levels => [qw(trace)]});

my $not_found = sub { [404,['Content-Type'=>'text/plain'],['Not found']] };

my $uri_not_found = sub {
    [ 404, ['Content-Type'=>'text/plain'], [ rdflow_uri(shift) ] ];
};

my $app = builder {
    enable 'RDF::Flow', source => RDF::Flow::Dummy->new;
    $uri_not_found;
};

test_app
    app => $app,
    tests => [{
        request => [ GET => '/example' ],
        content => qr{/example$},
        code    => 404,
    },{
        request => [ GET => '/example/foo?bar=doz' ],
        content => qr{/example/foo$},
        code    => 404,
    },{
        request => [ GET => '/example?format=ttl' ],
        content => qr{^<[^>]+/example>},
        code    => 200,
    }];


for my $base ( ('http://example.org/', '', 'my:') ) {
    $app = builder {
        enable 'RDF::Flow',
            source => RDF::Flow::Dummy->new,
            base => $base;
        $uri_not_found;
    };

    test_app
        app => $app,
        name => "Rewrite request URIs with base '$base'",
        tests => [{
            request => [ GET => '/example' ],
            content => $base."example",
            code    => 404,
        },{
            request => [ GET => '/example/foo?bar=doz' ],
            content => $base."example/foo",
            code    => 404,
        },{
            request => [ GET => '/example?format=ttl' ],
            content => qr{^<${base}example>},
            code    => 200,
        }];
}

$app = builder {
    enable 'RDF::Flow',
        source => RDF::Flow::Dummy->new,
        base => 'http://example.com/',
        rewrite => sub { s/com/org/; return $_ !~ 'foo'; };
    $uri_not_found;
};

test_app
    app => $app,
    tests => [{
        request => [ GET => '/' ],
        content => "http://example.org/",
        code    => 404,
    },{
        request => [ GET => '/foo' ],
        content => "http://example.com/foo",
        code    => 404,
    }];

done_testing;

__END__
use HTTP::Request::Common;

test_psgi $app, sub {
    my $app = shift;
    my $res = $app->(GET '/example');
    is_deeply $res, [404,['Content-Type' => 'text/plain']['Not found'];
}

