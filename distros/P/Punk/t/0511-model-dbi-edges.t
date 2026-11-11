#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Punk::Model;

# The DBI backend's edges: all(), a create naming no known column, an update
# without the key and one with nothing to change, and the internal XSUBs the
# model tier reaches through the backend: the RETURNING detection, the
# prepared statement cache and identifier quoting.

BEGIN {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'DBI + DBD::SQLite required for these tests';
}

{
    package DBE::Model::Book;
    use Punk::Model;
    table 'books';
    field id    => { type => 'integer', primary => 1 };
    field title => { type => 'string', required => 1 };
    package DBE::Model::Loose;
    use Punk::Model;
    table 'books';
    validate 0;
    field id    => { type => 'integer', primary => 1 };
    field title => { type => 'string' };
    package main;
}
my $dir = File::Temp->newdir;
my $dsn = "dbi:SQLite:dbname=$dir/b.db";
{
    my $dbh = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
    $dbh->do('CREATE TABLE books (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL)');
    $dbh->do("INSERT INTO books (title) VALUES ('one'), ('two')");
    $dbh->disconnect;
}
my $m  = DBE::Model::Book->_instantiate({ dsn => $dsn });
my $be = $m->backend;
sub refuses {
    my ($re, $name, $code) = @_;
    my $e = '';
    eval { $code->(); 1 } or $e = $@;
    like($e, $re, $name);
}

my $all = $m->all;
is(scalar @{ $all->{rows} }, 2, 'all returns every row as a page');
refuses(qr/Punk::Model::DBI: create with no known columns/, 'a create naming no known column',
    sub { DBE::Model::Loose->_instantiate({ dsn => $dsn })->create({ colour => 'red' }) });
refuses(qr/Punk::Model::DBI: update needs the primary key in the data/, 'an update without the key', sub { $m->update({ title => 'x' }) });
refuses(qr/Punk::Model::DBI: update with no columns to change/, 'an update with nothing to change', sub { $m->update({ id => 1 }) });
my $row = $m->update({ id => 1, title => 'uno' });
is($row->{title}, 'uno', 'an update returns the stored row');
is($m->create({ title => 'three' })->{title}, 'three', 'a create returns the stored row');

ok(defined $be->_returning, 'the backend knows whether its driver has RETURNING');
is($be->_detect_returning($be->dbh), $be->_returning, 'and detects it again from the handle');
my $sth = $be->_sth('SELECT COUNT(*) FROM books');
ok($sth && $sth->can('execute'), 'a statement handle comes back prepared');
is($be->_sth('SELECT COUNT(*) FROM books'), $sth, 'and the same SQL gives the same cached handle');
is($be->_qi('title'), '"title"', 'identifiers are quoted the way the driver quotes');
refuses(qr/Punk::Model::DBI: not a backend object/, 'a backend method on something else',
    sub { Punk::Model::DBI::_qi(bless(\(my $x = 1), 'Not::It'), 'x') });

done_testing;
