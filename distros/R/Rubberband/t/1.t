package Foo;
use lib 't';
$INC{"Foo.pm"}++;
use Maypole::CLI qw();
unshift @Foo::ISA, qw(Maypole::CLI);
BEGIN { unlink("t/foo.db"); }
use Rubberband (
    search_path => [ "Foo::Test" ],
    dsn => "dbi:SQLite:t/foo.db",
    translate_sql_from => "MySQL",
);

Foo->config->{uri_base} = "http://localhost/";
use Test::More "no_plan";

ok(Foo::Test::One->can("table"), "Loaded, is a DBI class");
Foo->create_database_tables();
ok(1, "Translated mysql data, created tables");
Foo->call_plugins("insert_data");
my @data = Foo::Test::One->retrieve_all;
is(@data,1, "Data was inserted");
{ local @ARGV = "http://localhost/foobar/baz";
use Maypole::Constants;
is(Foo->handler(), OK, "Maypole handler OK");
is($Maypole::CLI::buffer, "Maypole okay", "Maypole okay");
}
