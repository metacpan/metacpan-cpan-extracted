#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Benchmark ();
use JSON::PP ();
use Punk::Test;
use Punk::Plugin::MCP ();

plan skip_all => 'a timing check, for RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

# A tool call against the same action as a plain JSON route, both through
# Punk::Test, so both pay the same request building. The target, fixed before
# measuring: the tool call costs at most 1.5 times the route.
my $TARGET = 1.5;

eval q{
    package XTBench::Controller::Books;
    sub find { my ($c) = @_; return { id => $c->param('id'), title => 'Dune' } }
    package XTBench;
    use Punk;
    use Punk::Plugin::MCP;
    plugin 'MCP' => { session => 0 };
    get '/books/:id' => sub { my ($c) = @_; $c->json(XTBench::Controller::Books::find($c)) };
    post '/find' => sub { my ($c) = @_; $c->json({ id => $c->req->json->{id}, title => 'Dune' }) };
    mcp tool => find_book => { input => { type => 'object', required => ['id'],
                                          properties => { id => { type => 'string' } } } }
        => 'Books#find';
    1;
} or die $@;

my $t = Punk::Test->new('XTBench');
my $body = JSON::PP->new->canonical->encode({ jsonrpc => '2.0', id => 1, method => 'tools/call',
                                              params => { name => 'find_book', arguments => { id => '7' } } });
my %H = (Accept => 'application/json', 'MCP-Protocol-Version' => '2025-11-25');

$t->get_ok('/books/7');
like($t->body, qr/"title":"Dune"/, 'the route answers');
$t->post_ok('/mcp', body => $body, type => 'application/json', headers => \%H);
like($t->body, qr/Dune/, 'the tool answers');

# Punk::Test builds each env and calls the app, as its _ok methods do, without
# a TAP line per request.
my $app = $t->{app};
my $res = Benchmark::timethese(-3, {
    route => sub { $app->($t->_build_env('GET', '/books/7')) },
    post  => sub { $app->($t->_build_env('POST', '/find', body => '{"id":"7"}',
                                          type => 'application/json')) },
    tool  => sub { $app->($t->_build_env('POST', '/mcp', body => $body,
                                          type => 'application/json', headers => \%H)) },
}, 'none');

my %rate = map { $_ => $res->{$_}->iters / ($res->{$_}->cpu_a || 1e-9) } keys %$res;
my $ratio = $rate{route} / $rate{tool};
diag(sprintf 'GET route %.0f/s, POST JSON route %.0f/s, tool %.0f/s: %.2fx the GET, %.2fx the POST',
             $rate{route}, $rate{post}, $rate{tool}, $ratio, $rate{post} / $rate{tool});
TODO: {
    our $TODO = 'measured 2.4x to 2.9x on 24 Oct 2026, about 5us a call, the target awaits the owner';
    cmp_ok($ratio, '<=', $TARGET, "a tool call costs at most ${TARGET}x the route");
}

done_testing;
