use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = builder {
    enable 'Static::Combine', 
        path => qr{^/foo$},
        root => 't',
        files => [ '00_compile.t', '10_combine.t' ];
    sub { [ 500, [], [] ] };
};

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET 'http://localhost/foo');
    is $res->code, 200;
    my @c = ($res->content =~ /^(use Test::More)/mg);
    is scalar @c, 2, 'two files combined';
};

my @tests = (
    { 
       # passed through
        code  => 204 
    },{ 
        files => [ 'foo.js', 'baz.js' ],
        code  => 404
    },{ 
        files => [ 'foo.js', 'bar.js' ],
        code  => 200
    },{ 
        files => [ 'foo.js', 'doz.txt' ],
        code  => 500
    },
);

foreach my $test (@tests) {
    $app = builder {
        enable 'Static::Combine', 
            path => qr{^/$},
            root => 't/files/',
            files => $test->{files};
        sub { [ 204, [], [] ] };
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET 'http://localhost/');
        is $res->code, $test->{code};
    };
}

done_testing;
