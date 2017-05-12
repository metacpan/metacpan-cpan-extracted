use strict;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Test::More;

our %reqs = (
    '/some/path'  => {
        methods => { HEAD => 1, GET  => 1, POST => 1, PUT  => 1, },
    },
);

my $main = sub {
    my ( $env ) = @_;

    my $res;
    if( defined $reqs{ $env->{PATH_INFO} } ){
        if( defined $reqs{ $env->{PATH_INFO} }{methods}{ $env->{REQUEST_METHOD } } ) {
            $res = [ 200, [], [ 'sure!' ] ];
        } else {
            $res = [ 405, [], [ 'method not allowed' ] ];
        }
    } else {
        $res = [ 404, [], [ 'not found' ] ];
    }

    return $res;
};
my $app  = builder {
    mount "/noredir"  => builder {
        enable 'TrailingSlashKiller';
        $main;
    };
    mount "/redir" => builder {
        enable 'TrailingSlashKiller', redirect => 1;
        $main;
    };
};
my $test = Plack::Test->create($app);

my @TESTS = (
    {
        path => '/noredir/some/path',
        methods => [ qw(GET HEAD OPTIONS) ],
        results => [ 200, 200, 405 ]
    },
    {
        path => '/noredir/some/path/',
        methods => [ qw(GET HEAD OPTIONS) ],
        results => [ 200, 200, 405 ]
    },
    {
        path => '/noredir/some/other/path/',
        methods => [ qw(GET HEAD OPTIONS) ],
        results => [ 404, 404, 404 ]
    },
    {
        path => '/redir/some/path',
        methods => [ qw(GET HEAD POST PUT) ],
        results => [ 200, 200, 200, 200 ]
    },
    {
        path => '/redir/some/path/?answer=42',
        methods => [ qw(GET HEAD POST PUT) ],
        results => [ 301, 301, 307, 307 ]
    },
);

for my $t (@TESTS) {

    for my $method ( @{$t->{methods}} ) {
        my $req = HTTP::Request->new($method => $t->{path});
        my $res = $test->request( $req );
        is $res->code, shift @{$t->{results}};
    }
}


done_testing;
