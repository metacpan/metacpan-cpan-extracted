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

# TODO check what happens when url is already set
my @tests = (
    {
        url => '/redir/some/path?foo=bar',
        method => 'GET',
        expected => 'Moved Permanently.+/redir/some/path/\?foo=bar',
        expected_status => 301,
        message => 'GET redirect did not lose parameters',
    },
    {
        url => '/redir_with_ignore_string/some/path?foo=bar',
        method => 'GET',
        expected => 'Hello',
        expected_status => 200,
        message => 'No redirect because of ignore string set',
    },
    {
        url => '/redir_with_ignore_arrayref/some/path?foo=bar',
        method => 'GET',
        expected => 'Hello',
        expected_status => 200,
        message => 'No redirect because of ignore arrayref set',
    },
    {
        url => '/redir_with_ignore_arrayref/somewhere/foobar?value=foobar',
        method => 'GET',
        expected => 'Hello',
        expected_status => 200,
        message => 'No redirect because ignore is found in path',
    },
    {
        url => '/redir_with_ignore_arrayref/somewhere/test?value=foobar',
        method => 'GET',
        expected => 'Moved Permanently.+/redir_with_ignore_arrayref/somewhere/test/\?value=foobar',
        expected_status => 301,
        message => 'Redirect because match in GET param should not affect',
    },
    {
        url => '/redir_with_ignore_arrayref/somewhere/test?value=forbar',
        method => 'GET',
        expected => 'Moved Permanently.+/redir_with_ignore_arrayref/somewhere/test/\?value=forbar',
        expected_status => 301,
        message => 'Redirect because match in GET param should not affect',
    },
    {
        url => '/redir/somewhere/test/',
        method => 'GET',
        expected => 'Hello',
        expected_status => 200,
        message => 'No redir because we have a trailing slash already',
    },
    {
        url => '/redir/somewhere/test/?foo=bar',
        method => 'GET',
        expected => 'Hello',
        expected_status => 200,
        message => 'No redir because we have a trailing slash already. GET params are not affected',
    },
    {
        url => '/redir/somewhere/test/?foo=bar/',
        method => 'GET',
        expected => 'Hello',
        expected_status => 200,
        message => 'No redir because we have a trailing slash already. GET params are not affected',
    },
);

my $test = Plack::Test->create($app);

foreach ( @tests ) {
    my $foo = $test->request( HTTP::Request->new( $_->{method} => $_->{url} ) );
    like($foo->content, qr|$_->{expected}|, $_->{message});
    is($foo->code, $_->{expected_status}, 'Status code is OK');
}


done_testing;
