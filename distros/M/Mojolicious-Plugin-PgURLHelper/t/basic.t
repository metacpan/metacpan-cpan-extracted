# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'PgURLHelper';

ok(!defined(app->pg_url()), 'No args');

ok(!defined(app->pg_url({
                database => 'foo'
            })), 'Missing host');

ok(!defined(app->pg_url({
                host     => 'localhost'
            })), 'Missing database');

ok(!defined(app->pg_url({
            host     => 'localhost',
            database => 'foo',
            user     => 'bar:',
            pwd      => 'baz',
        })), 'User with colon');

ok(app->pg_url({
            host     => 'localhost',
            database => 'foo'
        }) eq 'postgresql://localhost/foo', 'Minimum of arguments');

ok(app->pg_url({
            host     => 'localhost',
            database => 'foo',
            port     => 6432
        }) eq 'postgresql://localhost:6432/foo', 'Port');

ok(app->pg_url({
            host     => 'localhost',
            database => 'foo',
            user     => 'bar'
        }) eq 'postgresql://localhost/foo', 'User only');

ok(app->pg_url({
            host     => 'localhost',
            database => 'foo',
            pwd      => 'baz'
        }) eq 'postgresql://localhost/foo', 'Password only');

ok(app->pg_url({
            host     => 'localhost',
            database => 'foo',
            user     => 'bar',
            pwd      => 'baz'
        }) eq 'postgresql://bar:baz@localhost/foo', 'User and password');

ok(app->pg_url({
            host     => 'localhost',
            database => 'foo',
            user     => 'bar',
            pwd      => 'baz',
            port     => 6432
        }) eq 'postgresql://bar:baz@localhost:6432/foo', 'All arguments');

ok(app->pg_url({
            host     => 'localhost',
            database => 'foo',
            user     => 'bar',
            pwd      => 'b:az',
        }) eq 'postgresql://bar:b:az@localhost/foo', 'Password with colon');

ok(app->pg_url({
            host     => 'localhost',
            database => 'foo',
            user     => 'ba@r',
            pwd      => 'baz',
        }) eq 'postgresql://ba%40r:baz@localhost/foo', 'User @ escaping');

ok(app->pg_url({
            host     => 'localhost',
            database => 'foo',
            user     => 'bar',
            pwd      => 'baz@',
        }) eq 'postgresql://bar:baz%40@localhost/foo', 'Password @ escaping');

done_testing();
