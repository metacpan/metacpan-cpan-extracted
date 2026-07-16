use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use File::Temp ();
use File::Spec ();
use PAGI::Test::Client;
use PAGI::Nano;

# Lifecycle (startup/shutdown sharing app-lifetime state via $c->state), static
# file serving, a custom 404, and mounting a sub-app.

# A static directory to serve.
my $dir = File::Temp->newdir;
{
    open my $fh, '>', File::Spec->catfile("$dir", 'hello.txt') or die $!;
    print $fh 'static body';
    close $fh;
}

my @shutdown_log;

my $inner = app {
    get '/where' => sub { my ($c) = @_; { mounted => 1 } };
};

my $app = app {
    startup  async sub { my ($state) = @_; $state->{boot} = 'up'; $state->{hits} = 0 };
    shutdown async sub { my ($state) = @_; push @shutdown_log, "down after $state->{boot}" };

    static '/assets' => "$dir";

    get '/state' => sub { my ($c) = @_;
        $c->state->{hits}++;
        { boot => $c->state->{boot}, hits => $c->state->{hits} };
    };

    mount '/sub' => $inner;

    not_found sub { my ($c) = @_; $c->json({ error => 'no such route' }, status => 404) };
};

# lifespan => 1 enables the lifespan protocol; ->start fires startup, ->stop
# fires shutdown.
my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
$client->start;

subtest 'startup populated shared state, visible via $c->state' => sub {
    my $res = $client->get('/state');
    is $res->json, { boot => 'up', hits => 1 }, 'startup ran and state is shared';
};

subtest 'shared state persists across requests' => sub {
    my $res = $client->get('/state');
    is $res->json->{hits}, 2, 'state mutations persist for the app lifetime';
};

subtest 'static serves files from the mounted directory' => sub {
    my $res = $client->get('/assets/hello.txt');
    is $res->status, 200, '200';
    is $res->content, 'static body', 'file body served';
};

subtest 'mount nests a sub-app under a prefix' => sub {
    my $res = $client->get('/sub/where');
    is $res->json, { mounted => 1 }, 'mounted app reachable under prefix';
};

subtest 'custom not_found handles unmatched routes' => sub {
    my $res = $client->get('/definitely-not-here');
    is $res->status, 404, '404';
    is $res->json, { error => 'no such route' }, 'custom 404 body';
};

subtest 'shutdown runs at stop with the shared state' => sub {
    $client->stop;
    is \@shutdown_log, ['down after up'], 'shutdown saw the startup state';
};

done_testing;
