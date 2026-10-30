package Bookshop;
use strict;
use warnings;
use Punk;
use Punk::Plugin::MCP;
use Bookshop::Controller::Books;

cache mcp => { backend => 'file', dir => $ENV{BOOKSHOP_SESSIONS} // '/tmp/bookshop-mcp' };

my $admin = sub {
    my ($c) = @_;
    return undef if ($c->req->header('X-Admin-Key') // '') eq ($ENV{BOOKSHOP_ADMIN_KEY} // 'change-me');
    return [403, ['Content-Type' => 'text/plain'], ['admins only']];
};
get '/books'     => 'Books#search';
get '/books/:id' => 'Books#show';
my $admin_scope = under '/admin' => $admin;
$admin_scope->post('/books' => 'Books#add');

plugin 'MCP' => {
    name         => 'bookshop',
    title        => 'The Bookshop',
    instructions => 'Search the catalogue before recommending. Book ids are numbers.',
    session      => 'mcp',
    logging      => 1,
};

mcp tool => search_books => {
    title       => 'Search books',
    description => 'Find books whose title or author contains the words given.',
    input       => { type => 'object', required => ['q'],
                     properties => { q => { type => 'string', description => 'words to look for' } } },
    output      => { type => 'object', required => ['books'],
                     properties => { books => { type => 'array' } } },
    annotations => { readOnlyHint => 1, openWorldHint => 0 },
} => 'Books#search';

mcp tool => add_book => {
    description => 'Add a book to the catalogue.',
    input       => { type => 'object', required => ['title', 'author'],
                     properties => { title  => { type => 'string' },
                                     author => { type => 'string' },
                                     year   => { type => 'integer' } } },
    annotations => { destructiveHint => 0, idempotentHint => 0 },
    guard       => $admin,
} => 'Books#add';

mcp resource => 'books://catalog' => { name => 'catalog', mime => 'application/json',
                                       description => 'Every book, one line each.' } => 'Books#catalog';
mcp resource => 'books://{id}' => { name => 'book', description => 'One book by id.' } => 'Books#show';

mcp prompt => recommend => {
    description => 'Ask for one recommendation from the catalogue.',
    arguments   => [{ name => 'mood', description => 'what the reader is in the mood for', required => 1 }],
} => 'Books#recommend';

1;
