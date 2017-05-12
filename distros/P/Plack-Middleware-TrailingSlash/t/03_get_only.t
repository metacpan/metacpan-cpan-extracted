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
    '/noredir/some/path',
    '/redir/some/path',
    '/redir_with_ignore_string/some/path',
    '/redir_with_ignore_arrayref/some/path',
    '/noredir/some/path?foo=bar',
    '/redir/some/path?foo=bar',
    '/redir_with_ignore_string/some/path?foo=bar',
    '/redir_with_ignore_arrayref/some/path?foo=bar',
);

my $test = Plack::Test->create($app);

foreach ( @tests ) {
    foreach my $method ( qw/HEAD POST PUT DELETE TRACE CONNECT/ ) {
        my $foo = $test->request( HTTP::Request->new( $method => $_ ) );
        like($foo->content, qr|Hello world|, 'No redirect');
        is($foo->code, 200, 'No redirect status 200');
    }
}

done_testing;

