#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/test/MyApp/lib";
use Test::More;
use PunkTest;
use File::Raw::JSON qw(file_json_decode);
use File::Temp ();

# t/test/MyApp end-to-end: web pages, the spec-first API, and the Book
# model over Punk::Model::DBI - all three trees sharing one SQLite
# database this test builds and points MyApp at through the environment.

my ($tmpdir, $dbfile);
BEGIN {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'DBI + DBD::SQLite required for the MyApp fixture';
    $tmpdir = File::Temp->newdir;
    $dbfile = "$tmpdir/myapp.db";
    $ENV{PUNK_MYAPP_DSN} = "dbi:SQLite:dbname=$dbfile";
    my $dbh = DBI->connect($ENV{PUNK_MYAPP_DSN}, undef, undef,
        { RaiseError => 1, AutoCommit => 1, PrintError => 0 });
    $dbh->do(q{
        CREATE TABLE books (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            title   TEXT NOT NULL,
            author  TEXT,
            created TEXT DEFAULT CURRENT_TIMESTAMP
        )
    });
    $dbh->do("INSERT INTO books (title, author) VALUES (?, ?)", undef, @$_)
        for [ 'Neuromancer', 'Gibson' ], [ 'Snow Crash', 'Stephenson' ];
    $dbh->disconnect;
}

use MyApp;

my $app = MyApp->to_app;

like(hit($app, path => '/')->[2][0], qr/MyApp/, 'home serves html');
{
    my $r = hit($app, path => '/books');
    my %h = @{ $r->[1] };
    is($h{'Content-Type'}, 'text/html; charset=utf-8',
        'list is a rendered page');
    like($r->[2][0], qr{<title>Books</title>}, 'wrapper layout applied');
    like($r->[2][0], qr{<a href="/books/1">Neuromancer</a>},
        'Stencil rendered the rows from the model');
}
{
    my $r = hit($app, path => '/books/1');
    like($r->[2][0], qr{<h1>Neuromancer</h1>}, 'view page renders by capture');
}
is(hit($app, path => '/books/99')->[0], 404, 'missing book 404s');
{
    my $r = hit($app, method => 'POST', path => '/books',
        body => '{"title":"Accelerando","author":"Stross"}');
    is($r->[0], 201, 'create sets its status');
    my $d = file_json_decode($r->[2][0]);
    is($d->{title}, 'Accelerando', 'created book returned as JSON');
    ok($d->{id}, 'with the model-assigned id');
    like(hit($app, path => "/books/$d->{id}")->[2][0],
        qr{<h1>Accelerando</h1>}, 'and its page renders');
}
is(hit($app, path => '/admin/books')->[0], 401, 'admin guard blocks');
{
    my $r = hit($app, path => '/admin/books',
        env => { HTTP_AUTHORIZATION => 'let-me-in' });
    is($r->[0], 200, 'admin guard passes with the header');
    ok(file_json_decode($r->[2][0])->{admin}, 'admin payload');
}
is(hit($app, method => 'DELETE', path => '/books')->[0], 405,
    'undeclared method answers 405');

# ---- the API side: spec-first under /api, same model ------------------------
{
    my $d = file_json_decode(hit($app, path => '/api/books')->[2][0]);
    ok(@{ $d->{books} } >= 2, 'allBooks serves the shared database');
    ok(exists $d->{has_more_data}, 'with the pagination shape');
}
{
    my $d = file_json_decode(hit($app, path => '/api/books/1')->[2][0]);
    is($d->{title}, 'Neuromancer', 'getBook by typed path param');
}
is(hit($app, path => '/api/books/999')->[0], 404,
    'missing book: handler not_found');
is(hit($app, path => '/api/books/notanint')->[0], 400,
    'bad path param type: validation 400');
{
    my $r = hit($app, method => 'POST', path => '/api/books',
        body => '{"title":"Distress","author":"Egan"}');
    is($r->[0], 201, 'addBook creates');
    my $d = file_json_decode($r->[2][0]);
    like(hit($app, path => "/books/$d->{id}")->[2][0],
        qr{<h1>Distress</h1>},
        'and the web page sees it (one database behind both trees)');
}
is(hit($app, method => 'POST', path => '/api/books', body => '{}')->[0],
    400, 'body validation enforces the NewBook schema');

# ---- keyset pagination through the API --------------------------------------
# The database now holds 4 books (2 seeded, 2 created above): ids 1-4.
{
    my $p1 = file_json_decode(
        hit($app, path => '/api/books', query => 'limit=2')->[2][0]);
    is(scalar @{ $p1->{books} }, 2, 'a limited page returns two books');
    ok($p1->{has_more_data}, 'has_more_data flags a further page');
    ok($p1->{next}, 'and offers an opaque next token');

    my $p2 = file_json_decode(
        hit($app, path => '/api/books',
            query => "limit=2&next=$p1->{next}")->[2][0]);
    is($p2->{books}[0]{id}, 3, 'the next page seeks past the first');
    my %ids = map { $_->{id} => 1 } @{ $p1->{books} }, @{ $p2->{books} };
    is(scalar keys %ids, 4, 'the two pages cover four distinct books');
}

SKIP: {
    skip 'Open::API::UI not available', 2
        unless eval { require Open::API::UI; 1 };
    my $r = hit($app, path => '/docs');
    is($r->[0], 200, 'the docs UI serves at /docs');
    like($r->[2][0], qr/id="op-allBooks"/, 'listing the API operations');
}

done_testing();
