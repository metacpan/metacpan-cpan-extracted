#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use FindBin;
use JSON::PP ();
use lib "$FindBin::Bin/../example/lib";
use Punk::Test;

$ENV{BOOKSHOP_SESSIONS} = File::Temp::tempdir(CLEANUP => 1);
$ENV{BOOKSHOP_ADMIN_KEY} = 'k';
require Bookshop;

my $t = Punk::Test->new('Bookshop');
my $J = JSON::PP->new->canonical;
my %H = (Accept => 'application/json, text/event-stream', 'MCP-Protocol-Version' => '2025-11-25');

sub rpc {
    my ($id, $method, $params, %h) = @_;
    $t->post_ok('/mcp', body => $J->encode({ jsonrpc => '2.0', id => $id, method => $method,
                                             ($params ? (params => $params) : ()) }),
                type => 'application/json', headers => { %H, %h });
    return JSON::PP->new->utf8->decode($t->body);
}

$t->get_ok('/books?q=dune');
like($t->body, qr/Dune/, 'the web route answers');

my $r = rpc(1, 'initialize', { protocolVersion => '2025-11-25', capabilities => {},
                               clientInfo => { name => 't93', version => '1' } });
is($r->{result}{serverInfo}{name}, 'bookshop', 'initialize');
my $sid = $t->header('Mcp-Session-Id');
ok($sid, 'with a session');
$H{'Mcp-Session-Id'} = $sid;

$r = rpc(2, 'tools/list');
is_deeply([ map { $_->{name} } @{ $r->{result}{tools} } ], ['search_books'],
          'without the admin key, add_book is not listed');
$r = rpc(2, 'tools/list', undef, 'X-Admin-Key' => 'k');
is_deeply([ sort map { $_->{name} } @{ $r->{result}{tools} } ], ['add_book', 'search_books'],
          'with it, both are');

$r = rpc(3, 'tools/call', { name => 'search_books', arguments => { q => 'le guin' } });
is($r->{result}{structuredContent}{books}[0]{title}, 'The Dispossessed', 'search_books');

$r = rpc(4, 'tools/call', { name => 'add_book', arguments => { title => 'Solaris', author => 'Lem' } });
ok($r->{result}{isError}, 'add_book without the admin key is refused');
$r = rpc(5, 'tools/call', { name => 'add_book', arguments => { title => 'Solaris', author => 'Lem' } },
         'X-Admin-Key' => 'k');
is($r->{result}{structuredContent}{title}, 'Solaris', 'and with it, added');

$r = rpc(6, 'resources/read', { uri => 'books://catalog' });
like($r->{result}{contents}[0]{text}, qr/Solaris/, 'the catalog resource has it');
$r = rpc(7, 'resources/read', { uri => 'books://3' });
like($r->{result}{contents}[0]{text}, qr/Hyperion/, 'a book by id');
$r = rpc(8, 'resources/read', { uri => 'books://99' });
is($r->{error}{code}, -32002, 'and one that is not there');

$r = rpc(9, 'prompts/get', { name => 'recommend', arguments => { mood => 'deserts' } });
like($r->{result}{messages}[0]{content}{text}, qr/wants deserts/, 'the prompt');

done_testing;
