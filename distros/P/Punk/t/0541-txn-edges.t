#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest qw(hit);

# $c->txn refused, by message: without code, on an application with no
# database, naming a database that is not configured, on a backend class
# that will not load, on one without transactions, with a model that lives
# on another database or has no backend; and Punk::Txn methods on something
# that is not a transaction.

use File::Temp ();
use File::Path ();
my $lib = File::Temp::tempdir(CLEANUP => 1);
File::Path::make_path("$lib/T/Backend");
{
    open my $fh, '>', "$lib/T/Backend/NoTxn.pm" or die;
    print $fh "package T::Backend::NoTxn;\nsub new { my (\$class, %a) = \@_; bless { rows => {} }, \$class }\nsub get { undef } sub search { { rows => [], has_more_data => 0, next => undef } }\nsub all { \$_[0]->search } sub create { \$_[1] } sub update { \$_[1] } sub delete { 0 }\n1;\n";
    close $fh;
}
unshift @INC, $lib;
{
    package TX::Model::Thing;
    use Punk::Model;
    table 'things';
    field id => { type => 'integer', primary => 1 };
    package main;
}
sub app_err {
    my ($pkg, $body, $path) = @_;
    my $app = eval "package $pkg; use Punk; $body; $pkg->to_app" or die $@;
    my $r = hit($app, path => $path // '/');
    return join '', @{ $r->[2] };
}
{
    package TXNone;
    use Punk;
    get '/nocode' => sub { my ($c) = @_; eval { $c->txn('not code') }; $c->text($@) };
    get '/nodb'   => sub { my ($c) = @_; eval { $c->txn(sub { 1 }) }; $c->text($@) };
    get '/named'  => sub { my ($c) = @_; eval { $c->txn(other => sub { 1 }) }; $c->text($@) };
    package main;
    my $app = TXNone->to_app;
    like(hit($app, path => '/nocode')->[2][0], qr/Punk::Txn: txn takes a coderef/, 'txn without code');
    like(hit($app, path => '/nodb')->[2][0], qr/Punk::Txn: no database configured - add a database keyword/, 'txn on an application with no database');
    like(hit($app, path => '/named')->[2][0], qr/Punk::Txn: no database 'other' configured/, 'txn naming a database that is not configured');
}
{
    package TXLoad;
    use Punk;
    database backend => 'Nope::Backend::Missing';
    get '/' => sub { my ($c) = @_; eval { $c->txn(sub { 1 }) }; $c->text($@) };
    package main;
    like(hit(TXLoad->to_app, path => '/')->[2][0], qr/Punk::Txn: backend 'Nope::Backend::Missing' failed to load/, 'a backend class that will not load');
}
{
    package TXNoTxn;
    use Punk;
    database backend => 'T::Backend::NoTxn';
    get '/' => sub { my ($c) = @_; eval { $c->txn(sub { 1 }) }; $c->text($@) };
    package main;
    like(hit(TXNoTxn->to_app, path => '/')->[2][0], qr/Punk::Txn: backend 'T::Backend::NoTxn' does not implement _txn - it has no transactions/,
        'a backend without transactions');
}
SKIP: {
    skip 'DBI + DBD::SQLite required', 3 unless eval { require DBI; require DBD::SQLite; 1 };
    require File::Temp;
    my $dir = File::Temp->newdir;
    my $dsn = "dbi:SQLite:dbname=$dir/t.db";
    my $dbh = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
    $dbh->do('CREATE TABLE things (id INTEGER PRIMARY KEY AUTOINCREMENT)');
    $dbh->disconnect;
    {
        package TXDb;
        use Punk;
        database dsn => $dsn;
        database other => { dsn => $dsn };
        model 'TX::Model::Thing';
        get '/other' => sub { my ($c) = @_; eval { $c->txn(other => sub { $_[0]->model('TX::Model::Thing') }) }; $c->text($@) };
        get '/notx'  => sub { my ($c) = @_; my $e = ''; eval { Punk::Txn::model('not a txn', 'x'); 1 } or $e = $@; $c->text($e) };
        get '/plain' => sub { my ($c) = @_; my $v = $c->txn(sub { 'ran' }); $c->text($v) };
        package main;
    }
    my $app = TXDb->to_app;
    like(hit($app, path => '/other')->[2][0], qr/Punk::Txn: model 'TX::Model::Thing' lives on database 'default', and this transaction is on 'other'/,
        'a model on another database than the transaction');
    like(hit($app, path => '/notx')->[2][0], qr/Punk::Txn: not a transaction object/, 'a Punk::Txn method on something else');
    is(hit($app, path => '/plain')->[2][0], 'ran', 'and an ordinary transaction block runs');
}

done_testing;
