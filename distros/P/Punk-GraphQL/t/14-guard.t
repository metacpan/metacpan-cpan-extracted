#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;

my $body_read = 0;
{
    package GuardApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(), {
        resolvers => PGTest::resolvers(),
        graphiql  => 1,
        guard     => sub {
            my ($c) = @_;
            return if ($c->req->header('X-Token') // '') eq 'sesame';
            return [401,
                    ['Content-Type' => 'application/json',
                     'Content-Length' => 33],
                    ['{"errors":[{"message":"denied"}]}']];
        },
    };
    plugin 'GraphQL';
}
my $app = GuardApp->to_app;
my $good = '{"query":"{ users(first: 1) { id } }"}';

# denied: the guard's response comes back and the body is never touched
{
    # a psgi.input that dies if read proves the guard runs first
    my $r = hit($app, body => $good, env => {
        'psgi.input' => TrapHandle->new,
    });
    is $r->[0], 401, 'guard denies without the token';
    is jdec($r)->{errors}[0]{message}, 'denied', 'with its own envelope';
    is $body_read, 0, 'and the request body was never read';
}

# allowed
{
    my $r = hit($app, body => $good,
                env => { HTTP_X_TOKEN => 'sesame' });
    is $r->[0], 200, 'guard passes with the token';
}

# graphiql shares the guard
{
    my $r = hit($app, method => 'GET', body => '');
    is $r->[0], 401, 'GraphiQL page is behind the same guard';
    $r = hit($app, method => 'GET', body => '',
             env => { HTTP_X_TOKEN => 'sesame' });
    is $r->[0], 200, 'and serves with the token';
    my %h = @{ $r->[1] };
    like $h{'Content-Type'}, qr{text/html}, 'as HTML';
}

done_testing();

package TrapHandle;
sub new  { bless {}, shift }
sub read { $body_read++; die "guard did not run before the body read\n" }
sub seek { 0 }
