use v5.36;

use lib 'lib';
use Future::AsyncAwait;
use Types::Standard qw(Str);
use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);
use DBIx::Class::Async::Schema;
use IO::Async::Loop;
use File::Temp qw(tempfile);

my $loop = IO::Async::Loop->new;
my (undef, $dbfile) = tempfile(SUFFIX => '.db', UNLINK => 1);
my $schema;  # populated in on_startup, torn down in on_shutdown
my $app = PAGI::FastAPI->new(title => 'DBIC-Async Integration Demo');

$app->on_startup(async sub {
    $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$dbfile", undef, undef, {},
        {
            workers      => 1,
            schema_class => 'MyApp::Schema',
            loop         => $loop,
        }
    );
    await $schema->deploy;
    warn "DB pool ready at $dbfile\n";
});

$app->on_shutdown(async sub {
    DBIx::Class::Async->disconnect($schema) if $schema;
    warn "DB pool disconnected\n";
});

# Dependency: hand the schema to any route that asks for it.
my $get_schema = async sub ($c) { return $schema };

$app->post('/users',
    body => { name => Str, email => Str },
    dependencies => { schema => $get_schema },
    handler => async sub ($c) {
        my $s = $c->stash->{schema};
        my $user = await $s->resultset('User')->create({
            name  => $c->body('name'),
            email => $c->body('email'),
        });
        $c->status(201);
        return {
            id    => $user->id,
            name  => $user->name,
            email => $user->email
        };
    }
);

$app->get('/users/{id}',
    dependencies => { schema => $get_schema },
    handler => async sub ($c) {
        my $s    = $c->stash->{schema};
        my $user = await $s->resultset('User')->find($c->path_param('id'));
        unless ($user) {
            $c->status(404);
            return { detail => 'User not found' };
        }
        return {
            id    => $user->id,
            name  => $user->name,
            email => $user->email
        };
    }
);

$app->get('/users',
    dependencies => { schema => $get_schema },
    handler => async sub ($c) {
        my $s     = $c->stash->{schema};
        my $count = await $s->resultset('User')->count;
        return { total => $count };
    }
);

my $pagi_app = $app->to_app;

sub mk_send {
    my @e;
    my $send = async sub ($ev) { push @e, $ev };
    return ($send, \@e);
}

my $default_receive = async sub {
    return { type => 'http.request', body => '', more_body => 0 }
};

my $shutdown_signal  = $loop->new_future;
my $lifespan_started = 0;

my $lifespan_recv = async sub {
    unless ($lifespan_started) {
        $lifespan_started = 1;
        return { type => 'lifespan.startup' };
    }
    return await $shutdown_signal;
};

my ($lifespan_send, $lifespan_events) = mk_send();

# Start the long-lived lifespan scope concurrently.
my $lifespan_future = $pagi_app->({ type => 'lifespan' }, $lifespan_recv, $lifespan_send);
$lifespan_future->retain;

(async sub {
    while (!grep { $_->{type} eq 'lifespan.startup.complete' } @$lifespan_events) {
        await $loop->delay_future(after => 0.01);
    }
    say "startup events: " . join(',', map { $_->{type} } @$lifespan_events);

    # Create a user
    my $body = '{"name":"Ada Lovelace","email":"ada@example.com"}';
    my $brecv = async sub { return { type=>'http.request', body=>$body, more_body=>0 } };
    my ($send1, $ev1) = mk_send();
    await $pagi_app->({ type=>'http', method=>'POST', path=>'/users', query_string=>'', headers=>[] }, $brecv, $send1);
    my ($s1) = map { $_->{status} } grep { $_->{type} eq 'http.response.start' } @$ev1;
    my ($b1) = map { $_->{body} }   grep { $_->{type} eq 'http.response.body' } @$ev1;
    say "POST /users -> status=$s1 body=$b1";

    # Fetch it back
    my ($send2, $ev2) = mk_send();
    await $pagi_app->({ type=>'http', method=>'GET', path=>'/users/1', query_string=>'', headers=>[] }, $default_receive, $send2);
    my ($s2) = map { $_->{status} } grep { $_->{type} eq 'http.response.start' } @$ev2;
    my ($b2) = map { $_->{body} }   grep { $_->{type} eq 'http.response.body' } @$ev2;
    say "GET /users/1 -> status=$s2 body=$b2";

    # Count via async resultset
    my ($send3, $ev3) = mk_send();
    await $pagi_app->({ type=>'http', method=>'GET', path=>'/users', query_string=>'', headers=>[] }, $default_receive, $send3);
    my ($s3) = map { $_->{status} } grep { $_->{type} eq 'http.response.start' } @$ev3;
    my ($b3) = map { $_->{body} }   grep { $_->{type} eq 'http.response.body' } @$ev3;
    say "GET /users -> status=$s3 body=$b3";

    # 404 path
    my ($send4, $ev4) = mk_send();
    await $pagi_app->({ type=>'http', method=>'GET', path=>'/users/999', query_string=>'', headers=>[] }, $default_receive, $send4);
    my ($s4) = map { $_->{status} } grep { $_->{type} eq 'http.response.start' } @$ev4;
    say "GET /users/999 -> status=$s4";

    # Signal shutdown: this resolves the pending Future the lifespan
    # scope's receive() has been awaiting since startup.
    $shutdown_signal->done({ type => 'lifespan.shutdown' });
    await $lifespan_future;
    say "shutdown events: " . join(',', map { $_->{type} } @$lifespan_events);

    $loop->stop;
})->()->retain;

$loop->run;
