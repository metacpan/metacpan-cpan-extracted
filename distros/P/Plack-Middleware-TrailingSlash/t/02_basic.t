use strict;
use warnings;

use lib 'lib';
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Test::More;
use Plack::Middleware::TrailingSlash;
use Data::Dumper;

my $main = sub {
    my ( $env ) = @_;

    return [ 200, [], [ 'Hello world!' ] ];
};

my $app = builder {
    mount "/noredir"  => builder {
        $main;
    };

    mount "/redir" => builder {
        enable 'TrailingSlash';
        $main;
    };

    mount "/redir_with_ignore_string" => builder {
        enable 'TrailingSlash', ignore => 'path';
        $main;
    };

    mount "/redir_with_ignore_arrayref" => builder {
        enable 'TrailingSlash', ignore => [ 'path', 'foobar' ];
        $main;
    };
};

my @tests = (
    {
        url => '/noredir/some/path',
        method => 'GET',
        expected => 'Hello',
        expected_status => 200,
        message => 'No redir',
    },
    {
        url => '/redir/some/path',
        method => 'GET',
        expected => 'Moved Permanently.+/redir/some/path\/',
        expected_status => 301,
        message => 'Redir',
    },
    {
        url => '/redir_with_ignore_string/some/path',
        method => 'GET',
        expected => 'Hello',
        expected_status => 200,
        message => 'No redir',
    },
    {
        url => '/redir_with_ignore_arrayref/some/path',
        method => 'GET',
        expected => 'Hello',
        expected_status => 200,
        message => 'No redir',
    },
);

my $test = Plack::Test->create($app);

foreach ( @tests ) {
    my $foo = $test->request( HTTP::Request->new( $_->{method} => $_->{url} ) );
    like($foo->content, qr|$_->{expected}|, $_->{message});
    is($foo->code, $_->{expected_status}, 'Status code is OK');
}

done_testing;
