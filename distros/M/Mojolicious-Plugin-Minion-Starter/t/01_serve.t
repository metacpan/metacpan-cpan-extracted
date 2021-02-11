use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Test::Deep;

plugin Minion => { SQLite => 'sqlite:queue.db' };
plugin 'Minion::Starter' => { debug => 1, spawn => 2 };

sleep 1;

my $called;

app->minion->add_task(sleep => sub {
			  sleep 1;
		      });

get '/' => sub {
    my $c = shift;
    $c->render('text' => 'ok');
};

get '/enqueue' => sub {
    my $c = shift;

    my $j = $c->minion->enqueue('sleep');

    $c->render('json' => { job => $j });
};

get '/state/:id' => sub {
    my $c = shift;
    my $job = $c->minion->job($c->stash('id'));

    $c->render('json' => { job => $c->stash('id'), info => $job->info });
};

unlink 'queue.db', 'queue.db-wal', 'queue.db-shm';

sleep 1;

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200);

my $ok = $t->tx->res->body;

cmp_ok $ok, 'eq', 'ok', 'got response';


# -----------------------
# enqueue
# -----------------------

$t->get_ok('/enqueue')->status_is(200);

my $j = $t->tx->res->json->{job};

cmp_ok $j, '==', 1, 'enqueued job';

unlink 'queue.db', 'queue.db-wal', 'queue.db-shm';

done_testing;

__DATA__

# -----------------------
# get status active
# -----------------------

sleep 2;

$t->get_ok('/state/' . $j)->status_is(200);

cmp_ok $t->tx->res->json->{info}->{state}, '=~', 'active';


# -----------------------
# get status done
# -----------------------

sleep 5;

$t->get_ok('/state/' . $j)->status_is(200);

cmp_ok $t->tx->res->json->{info}->{state}, 'eq', 'finished';

# -----------------------
# cleanup
# -----------------------


