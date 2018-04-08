use lib 't'; use share; guard my $guard;
use DBI;
use Test::Database;
use Narada::Config qw( set_config );

require (wd().'/blib/script/narada-setup-mysql');


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';
$::dbh = $h->dbh->clone({RaiseError=>1});
my $db = $h->name.'_setup';
my $db_quoted = $::dbh->quote_identifier($db);
$::dbh->do("DROP DATABASE IF EXISTS $db_quoted");

# - main()
#   * too many params
#   * wrong params
#   * no config/mysql/db: do nothing
#   * bad pass
#   * --clean: make sure database dropped, if exists
#   * throw on non-empty database
#   * without SCHEME: make sure database created, if not exists
#   * with SCHEME: make sure SCHEME imported
#   * with SCHEME and several .sql: make sure all imported
#   * manage var/use/mysql

throws_ok { main('param-1', 'param-2') }    qr/Usage:/,
    'main: too many params';

throws_ok { main('not_existing_param') }    qr/Usage:/,
    'main: wrong param';

main();
is db_exists(), 0,
    'main: do nothing without config/mysql/db';

set_config('mysql/db', $db);
set_config('mysql/login', $h->username);
set_config('mysql/pass', 'wrong pass');
throws_ok { main() }    qr/Access denied/i,
    'main: bad pass';
set_config('mysql/pass', $h->password);

main('--clean');
is db_exists(), 0,
    'main: --clean without database';
$::dbh->do('CREATE DATABASE '.$db);
is db_exists(), 1,
    'main: db created';
main('--clean');
is db_exists(), 0,
    'main: --clean dropped database';

$::dbh->do('CREATE DATABASE '.$db);
$::dbh->do('USE '.$db);
$::dbh->do('CREATE TABLE a (i int)');
throws_ok { main() }    qr/database does not empty/,
    'main: database does not empty';
$::dbh->do('DROP DATABASE '.$db);

is db_exists(), 0,
    'main: db not exists';
main();
is db_exists(), 1,
    'main: database created (not exists)';
main();
is db_exists(), 1,
    'main: database created (exists)';

Echo('var/mysql/db.scheme.sql',"CREATE TABLE a (i int);\nCREATE TABLE b (j int);\n");
is_deeply list_tables(), {},
    'main: no tables';
output_from { main() };
is_deeply list_tables(), {a => 0, b => 0},
    'main: scheme loaded';
main('--clean');

Echo('var/mysql/a.sql',"INSERT INTO a VALUES (10), (20);\n");
Echo('var/mysql/b.sql',"INSERT INTO b VALUES (10), (20), (30);\n");
is_deeply list_tables(), {},
    'main: no tables';
output_from { main() };
is_deeply list_tables(), {a => 2, b => 3},
    'main: scheme and table dumps loaded';
main('--clean');

ok !path('var/use/mysql')->exists, 'no var/use/mysql';
output_from { main() };
ok path('var/use/mysql')->is_file, 'created var/use/mysql';
main('--clean');
ok !path('var/use/mysql')->exists, 'removed var/use/mysql';

# - import_sql()
#   * throw if file unreadable
#   * throw if file contain wrong SQL

$::dbh->do('CREATE DATABASE IF NOT EXISTS '.$db);

chmod 0, 'var/mysql/a.sql' or die "chmod: $!";
throws_ok { output_from { import_sql('var/mysql/a.sql') } }   qr/failed to import/i,
    'import_sql: file unreadable';
chmod 0644, 'var/mysql/a.sql' or die "chmod: $!";

Echo('var/mysql/c.sql', 'some junk here');
throws_ok { output_from { import_sql('var/mysql/c.sql') } }   qr/failed to import/i,
    'import_sql: file contain wrong SQL';


$::dbh->do('DROP DATABASE IF EXISTS '.$db);
done_testing();


sub Echo {
    my ($filename, $content) = @_;
    open my $fh, '>', $filename                         or die "open: $!";
    print {$fh} $content;
    close $fh                                           or die "close: $!";
    return;
}

sub db_exists {
    return 0+$::dbh->prepare('SHOW DATABASES LIKE ?')->execute($db);
}

sub list_tables {
    return {} if !db_exists();
    my %tables;
    for my $t (@{ $::dbh->selectcol_arrayref('SHOW TABLES') }) {
        $tables{$t} = $::dbh->selectcol_arrayref('SELECT COUNT(*) FROM '.$t)->[0];
    }
    return \%tables;
}
