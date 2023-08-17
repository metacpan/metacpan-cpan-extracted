use Test::More;
use Test::Exception;

use Mojolicious::Lite -signatures;
use Mojo::CouchDB;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojo::IOLoop::Subprocess;
use Mojo::Server::Daemon;
use MIME::Base64;

chomp(my $auth = 'Basic ' . encode_base64("foo:bar"));

put '/database' => sub {
    my $c = shift;
    ok 1, 'Is database created call working?';
    is $c->req->headers->to_hash->{Authorization}, $auth, 'Is auth header correct?';
    return $c->rendered(201);
};

post '/database' => sub {
    my $c = shift;
    ok 1, 'Is database create doc call working?';
    my $json = $c->req->json;

    $json->{_id} = 'foobar';

    return $c->render(json => $json);
};

post '/database/_bulk_docs' => sub {
    my $c = shift;
    ok 1, 'Is bulk doc call working?';
    my $json = $c->req->json;
    is len(@$json), 2, 'Did data come over correctly for bulk docs?';
    return $c->render(json => $json);
};

get '/database/foo' => sub {
    my $c = shift;
    ok 1, 'Did hit get?';
    return $c->render(json => {_id => 'foo', name => 'bar'});
};

my $c      = Mojo::CouchDB->new("http://127.0.0.1", 'foo', 'bar');
my $ioloop = Mojo::IOLoop->new;
my $daemon = Mojo::Server::Daemon->new(
    app                => app,
    listen             => ["http://127.0.0.1"],
    ioloop             => $ioloop,
    silent             => 1,
    keep_alive_timeout => 0.5
);
my $port = $daemon->start->ports->[0];
$c->{url} = Mojo::URL->new("http://127.0.0.1:$port/database");
my $couch = $c->db('database');
$couch->ua->{ioloop} = $ioloop;

ok $couch->create_db, 'Did create succeed?';

is $couch->save({name => 'foo'})->{name}, 'foo',    'Did save succeed?';
is $couch->save({name => 'foo'})->{_id},  'foobar', 'Did save get id?';

is $couch->get(\'foo')->{_id},  'foo', 'Did get succeed?';
is $couch->get(\'foo')->{name}, 'bar', 'Did get succeed 2?';
dies_ok { $couch->get('flub') } 'Does get die with 404?';

dies_ok { $couch->save } 'Did save die on no args?';
dies_ok { $couch->save(['foo']) } 'Did save die on bad args?';
dies_ok { $couch->save_many } 'Did save many die on no args?';
dies_ok { $couch->save_many({name => 'foo'}) } 'Did save many die on bad args?';
dies_ok { $couch->index } 'Did index die on no args?';
dies_ok { $couch->index(['foo']) } 'Did index die on bad args?';
dies_ok { $couch->find } 'Did find die on no args?';
dies_ok { $couch->find('foo') } 'Did find die on bad args?';
dies_ok { $couch->all_docs } 'Did all_docs die on no args?';
dies_ok { $couch->all_docs(123) } 'Did all_docs die on bad args?';
dies_ok { $couch->get } 'Did get die on no args?';
dies_ok { $couch->get({foo => 'bar'}) } 'Did get die on bad args?';

done_testing;
