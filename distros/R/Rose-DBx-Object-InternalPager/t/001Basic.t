######################################################################
# Test suite for RoseX::Manager::Pager
# by Mike Schilli <m@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More;
use Rose::DBx::Object::InternalPager;
use File::Temp qw(tempdir);
use DBI;
use Log::Log4perl qw(:easy);

#Log::Log4perl->easy_init($DEBUG);

eval { 
    require DBD::SQLite;
};

if($@) {
    plan skip_all => "DBD::SQLite not installed, skipping all tests";
    exit 0;
}

plan tests => 6;

our $dir = tempdir(CLEANUP => 1);
our $filename = "$dir/foo.db";

DEBUG "Connecting to DB in file $filename";
my $dbh = DBI->connect("dbi:SQLite:dbname=$filename", "", "",
  { RaiseError => 1});
ok($dbh, "Connected to database");
ok($dbh->{sqlite_version}, "SQLite returned version");

DEBUG "tmpfile=$filename";

$dbh->do(q{
    CREATE TABLE foobar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        string VARCHAR(32)
    );
});

DEBUG "Inserting 100 records";
for(1..100) {
    $dbh->do(qq{
        INSERT INTO foobar (string) VALUES ('foo$_');
    });
};

package My::DB;
use Rose::DB;
use base qw(Rose::DB);
__PACKAGE__->use_private_registry;
__PACKAGE__->register_db(
  domain   => "default",
  type     => "default",
  driver   => 'sqlite',
  database => "$main::filename",
);

package Product;
use base qw(Rose::DB::Object);
__PACKAGE__->meta->setup(
  table      => 'foobar',
  columns    => [ qw(id string) ],
  pk_columns => 'id',
);
sub init_db { My::DB->new() }

package Product::Manager;
use Rose::DB::Object::Manager;
use base qw(Rose::DB::Object::Manager);
sub object_class { 'Product' };
__PACKAGE__->make_manager_methods(base_name => 'products');

package main;

my $db = My::DB->new();
my $prods = Product::Manager->get_products();
is(scalar @$prods, 100, "Found 100 products");

my $pager = Rose::DBx::Object::InternalPager->new(
    class_name     => "Product",
    manager_method => "get_products",
    manager_options => { 
      query => [ id => { gt => 10 } ],
      sort_by       => 'id',
    },
);

my $count;
while(my $product = $pager->next()) {
    $count++;
    DEBUG "Found: ", $product->id(), " ", $product->string(), "\n";
}

is($count, 90, "Found 90 records total");

$pager = Rose::DBx::Object::InternalPager->new(
    class_name     => "Product",
    manager_method => "get_products",
    manager_options => { 
      query => [ id => { gt => 10 } ],
      sort_by       => 'id',
    },
    pager_options => {
        start_page => 1,
        per_page   => 100,
    },
);

my $product = $pager->next();

is($product->id(), 11, "Found product ID 11");

$pager = Rose::DBx::Object::InternalPager->new(
    class_name     => "Product",
    manager_method => "get_products",
    manager_options => { 
      query => [ id => { gt => 10 } ],
      sort_by       => 'id',
    },
    pager_options => {
        start_page => 2,
#        per_page   => 50,
    },
);

$product = $pager->next();

is($product->id(), 61, "Found product ID 61");

