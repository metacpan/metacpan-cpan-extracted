#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use MIME::Base64 ();
use Punk::Model;

# The query builder's remaining refusals, each by message: an ordered
# comparison or a like given undef or a reference, starts_with given undef
# or a reference, an operator that is not one, a bare list as a value, an
# order_by that is a mapping, a page asked of a model with no primary key
# and no order_by, and continuation tokens that decode but have the wrong
# shape.

BEGIN {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'DBI + DBD::SQLite required for these tests';
}

{
    package QE::Model::Book;
    use Punk::Model;
    table 'books';
    field id    => { type => 'integer', primary => 1 };
    field title => { type => 'string', required => 1 };
    field price => { type => 'integer' };
    package QE::Model::Note;
    use Punk::Model;
    table 'notes';
    field body => { type => 'string' };
    package main;
}
my $dir = File::Temp->newdir;
my $dsn = "dbi:SQLite:dbname=$dir/q.db";
{
    my $dbh = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
    $dbh->do('CREATE TABLE books (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, price INTEGER)');
    $dbh->do('CREATE TABLE notes (body TEXT)');
    $dbh->do("INSERT INTO books (title, price) VALUES ('a', 1), ('b', 2)");
    $dbh->do("INSERT INTO notes (body) VALUES ('n')");
    $dbh->disconnect;
}
my $m = QE::Model::Book->_instantiate({ dsn => $dsn });
my $n = QE::Model::Note->_instantiate({ dsn => $dsn });

sub refuses {
    my ($re, $name, $code) = @_;
    my $e = '';
    eval { $code->(); 1 } or $e = $@;
    like($e, $re, $name);
}

refuses(qr/'>' on price needs a value, not undef/, 'an ordered comparison with undef', sub { $m->search({ price => { '>' => undef } }) });
refuses(qr/'<=' on price takes a plain value, not a ARRAY/, 'an ordered comparison with a reference', sub { $m->search({ price => { '<=' => [ 1 ] } }) });
refuses(qr/'like' on title needs a value, not undef/, 'like with undef', sub { $m->search({ title => { like => undef } }) });
refuses(qr/'like' on title takes a plain value, not a HASH/, 'like with a reference', sub { $m->search({ title => { like => {} } }) });
refuses(qr/'starts_with' on title needs a value, not undef/, 'starts_with with undef', sub { $m->search({ title => { starts_with => undef } }) });
refuses(qr/'starts_with' on title takes a plain value, not a CODE/, 'starts_with with a reference', sub { $m->search({ title => { starts_with => sub { } } }) });
refuses(qr/unknown operator/, 'an operator that is not one', sub { $m->search({ price => { between => [ 1, 2 ] } }) });
refuses(qr/the filter on id is a plain arrayref - a list is spelled/, 'a bare list as a value', sub { $m->search({ id => [ 1, 2 ] }) });
refuses(qr/order_by takes a column name or \[ column => 'asc'\|'desc', \.\.\. \], not a HASH/, 'an order_by that is a mapping',
    sub { $m->search({}, { order_by => { price => 'asc' } }) });
refuses(qr/pagination needs a primary key or an order_by/, 'a page of a model with no primary key and no order_by', sub { $n->search({}, { after => 'x' }) });
is(scalar @{ $n->search({}, { order_by => 'body' })->{rows} }, 1, 'with an order_by the keyless model pages');

for my $shape ([ '{"x":1}', 'a mapping' ], [ '[1,2,3]', 'a list of the wrong length' ], [ '"str"', 'a string' ]) {
    my ($json, $what) = @$shape;
    my $tok = MIME::Base64::encode_base64url($json);
    refuses(qr/invalid pagination token/, "a token that decodes to $what is refused", sub { $m->search({}, { after => $tok }) });
}
{
    my $page = $m->search({}, { limit => 1 });
    ok($page->{has_more_data}, 'a page with more behind it');
    my $next = $m->search({}, { limit => 1, after => $page->{next} });
    is($next->{rows}[0]{id}, 2, 'continues from the token');
}

done_testing;
