#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

# the inline app packages `use Punk` at compile time, so this guard
# must run during compilation too - a runtime skip_all would be too late
BEGIN {
    unless (eval { require Punk; 1 }) {
        require Test::More;
        Test::More::plan(skip_all => 'Punk required');
    }
}
plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

my $file = queue_file();
my $DSN = "dbi:SQLite:dbname=$file";

# The one-line integration: plugin, helpers, enqueue from a handler.
{
    package PlugApp;
    use Punk;
    plugin 'Queue' => { dsn => $DSN };

    post '/send' => sub {
        my ($c) = @_;
        my $id = $c->enqueue('mail.send' => ['a@b.c']);
        return $c->json({ id => $id });
    };
    get '/peek/:id' => sub {
        my ($c) = @_;
        return $c->json($c->job($c->param('id')));
    };
    get '/q' => sub {
        my ($c) = @_;
        return $c->json({ ref => ref $c->queue });
    };
}

my $app = PlugApp->to_app;
ok($app, 'the app compiled');

require File::Raw::JSON;
sub jdec { File::Raw::JSON::file_json_decode($_[0][2][0]) }
sub hit_app {
    my ($app_, %o) = @_;
    my $body = $o{body} // '';
    open my $in, '<', \$body or die $!;
    return $app_->({
        REQUEST_METHOD => $o{method} // 'GET',
        PATH_INFO      => $o{path}   // '/',
        QUERY_STRING   => $o{query}  // '',
        CONTENT_TYPE   => $o{type} // ($body ne '' ? 'application/json' : ''),
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} // {} },
    });
}

# helpers are real methods on the context subclass
ok(PlugApp::_Context->can('queue'),   'queue helper is a real method');
ok(PlugApp::_Context->can('enqueue'), 'enqueue helper is a real method');
ok(PlugApp::_Context->can('job'),     'job helper is a real method');

my $res = hit_app($app, method => 'POST', path => '/send');
is($res->[0], 200, 'enqueue from a handler works');
my $id = jdec($res)->{id};
ok($id, 'and returned an id');

$res = hit_app($app, path => "/peek/$id");
is(jdec($res)->{task}, 'mail.send', '$c->job round-trips');
is(jdec($res)->{state}, 'inactive', 'the job is queued');

$res = hit_app($app, path => '/q');
is(jdec($res)->{ref}, 'Punk::Queue', '$c->queue returns the queue');

# the class-level accessor: queue() with no arguments
{
    package PlugApp;
    ::isa_ok(queue(), 'Punk::Queue', 'queue() with no args');
}

# a helper collision croaks at registration, naming both owners
{
    package CollideApp;
    use Punk;
    helper queue => sub { 'mine' };
    my $died = !eval { plugin 'Queue' => { dsn => $DSN }; 1 };
    ::ok($died, 'a queue-helper collision croaks');
    ::like($@, qr/queue/, 'naming the helper');
}

# no dsn anywhere croaks with directions
{
    package NoDsnApp;
    use Punk;
    my $died = !eval { plugin 'Queue' => {}; 1 };
    ::ok($died, 'no dsn croaks');
    ::like($@, qr/dsn/, 'and says what to pass');
}

# the database keyword is the fallback dsn source
{
    my $file2 = PQTest::queue_file();
    package DbApp;
    use Punk;
    database dsn => "dbi:SQLite:dbname=$file2";
    plugin 'Queue' => {};
    ::ok(1, 'the database keyword feeds the plugin');
    ::isa_ok(queue(), 'Punk::Queue', 'and the queue exists');
}

done_testing();
