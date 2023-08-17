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
    is $c->req->headers->to_hash->{Authorization}, $auth, 'Is auth header correct?';
    return $c->rendered(201);
};

post '/database' => sub {
    my $c    = shift;
    my $json = $c->req->json;

    $json->{_id} = 'foobar';

    return $c->render(json => $json);
};

post '/database/_bulk_docs' => sub {
    my $c = shift;
    ok 1, 'Is bulk doc call working?';
    my $json = $c->req->json;
    is len(@$json), 2, 'Did data come over correctly for bulk docs?';
    return $json;
};

my $c      = Mojo::CouchDB->new("http://127.0.0.1/database", 'foo', 'bar');
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
ok $couch->create_db;
Mojo::IOLoop->start;

dies_ok { $couch->find_p } 'Does find_p die with no input?';
dies_ok { $couch->find_p('foo') } 'Does find_p die with non-hash input?';
dies_ok { $couch->index_p } 'Does index_p die with no input?';
dies_ok { $couch->index_p(123) } 'Does index_p die with bad input?';
dies_ok { $couch->save_many_p } 'Does save_many_p die with no input?';
dies_ok { $couch->save_many_p('foo') } 'Does save_may_p die with bad input?';
dies_ok { $couch->save_p } 'Does save_p die with no input?';
dies_ok { $couch->save_p(123) } 'Does save_p die with bad input?';
dies_ok { $couch->all_docs_p } 'Does all_docs_p die with no input?';
dies_ok { $couch->all_docs_p(123) } 'Does all_docs_p die with bad input?';

done_testing;
