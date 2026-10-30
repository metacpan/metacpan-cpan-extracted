package StdioApp::Controller::T;
use strict;
use warnings;
sub echo   { my ($c) = @_; { said => $c->param('say'), user => $c->mcp_user } }
sub slow   { my ($c) = @_; $c->mcp_progress(1, 2, 'half'); $c->mcp_log('warning', 'careful'); 'slow done' }
sub stray  { print "this must not reach the protocol\n"; 'still fine' }
sub touch  { my ($c) = @_; $c->mcp_resource_updated('books://1'); $c->mcp_resource_updated('books://2'); 'touched' }
sub later  { Punk::Future->done_future('from a future') }
sub book   { 'a book' }

package StdioApp;
use strict;
use warnings;
use Punk;
use Punk::Plugin::MCP;
plugin 'MCP' => {
    session     => 0,
    logging     => 1,
    stdio_trust => ($ENV{PMCP_TEST_TRUST} ? 1 : 0),
    auth        => sub { ($_[0]->req->header('Authorization') // '') eq 'Bearer sekret'
                         ? undef : [401, [], ['no token']] },
    principal   => sub { 'stdio-user' },
};
mcp tool => echo  => 'T#echo';
mcp tool => slow  => 'T#slow';
mcp tool => stray => 'T#stray';
mcp tool => touch => 'T#touch';
mcp tool => later => 'T#later';
mcp resource => 'books://{id}' => 'T#book';
1;
