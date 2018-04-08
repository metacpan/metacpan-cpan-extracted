use lib 't'; use share; guard my $guard;
use DBI;
use Test::Database;
use Narada::Config qw( set_config );

require (wd().'/blib/script/narada-mysqldump');


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';
$::dbh = $h->dbh->clone({RaiseError=>1});
my $db = $h->name.'_mysqldump';
my $db_quoted = $::dbh->quote_identifier($db);
$::dbh->do("DROP DATABASE IF EXISTS $db_quoted");
undef $::dbh;


# - init_globals()
#   * return false without mysql/db
#   * throw with wrong mysql/pass
#   * create $::dbh and $::MYSQLDUMP

ok !init_globals(), 'init_globals: return false';

set_config('mysql/db', $db);
set_config('mysql/login', $h->username);
set_config('mysql/pass', $h->password);
system('narada-setup-mysql');

set_config('mysql/pass', 'wrong pass');
throws_ok { init_globals() } qr/Access denied/i,
    'init_globals: throw with wrong mysql/pass';
set_config('mysql/pass', $h->password);

ok !$::dbh,         'init_globals: $::dbh undefined';
ok !$::MYSQLDUMP,   'init_globals: $::MYSQLDUMP undefined';
ok init_globals(),  'init_globals return true';
ok $::dbh,          'init_globals: $::dbh defined';
ok $::MYSQLDUMP,    'init_globals: $::MYSQLDUMP defined';
$::dbh->do('SET default_storage_engine=MYISAM');

# - list_tables()
#   * mysql/dump/incremental: required
#   * mysql/dump/empty: required
#   * mysql/dump/ignore: optional
#   * incremental, empty, ignore: EMPTY, no tables
#   * incremental, empty, ignore: EMPTY, some tables
#   * incremental, empty, ignore: NOT EMPTY, no other tables
#   * incremental, empty, ignore: NOT EMPTY, some other tables

$::dbh->do('CREATE TABLE a (id INT AUTO_INCREMENT PRIMARY KEY, n INT)');
$::dbh->do('CREATE TABLE b (s TEXT)');

set_config('mysql/dump/incremental', "a\nnosuch\nb\n");
throws_ok { list_tables() } qr{Table nosuch listed in mysql/dump/incremental does not exists}i,
    'list_tables: mysql/dump/incremental REQUIRED';
set_config('mysql/dump/incremental', q{});

set_config('mysql/dump/empty', "a\nnosuch\nb\n");
throws_ok { list_tables() } qr{Table nosuch listed in mysql/dump/empty does not exists}i,
    'list_tables: mysql/dump/empty REQUIRED';
set_config('mysql/dump/empty', q{});

set_config('mysql/dump/ignore', "a\nnosuch\nb\n");
lives_ok { list_tables() }
    'list_tables: mysql/dump/ignore OPTIONAL';
set_config('mysql/dump/ignore', q{});

$::dbh->do('DROP TABLE a');
$::dbh->do('DROP TABLE b');

is_deeply [list_tables()], [[],[],[]],
    'list_tables: incremental, empty, ignore: EMPTY, no tables';

$::dbh->do('CREATE TABLE a (id INT AUTO_INCREMENT PRIMARY KEY, n INT)');
$::dbh->do('CREATE TABLE b (s TEXT)');
is_deeply [list_tables()], [['a','b'],[],[]],
    'list_tables: incremental, empty, ignore: EMPTY, some tables';
$::dbh->do('DROP TABLE a');
$::dbh->do('DROP TABLE b');

set_config('mysql/dump/incremental', "a\nb");
set_config('mysql/dump/empty', "c\nd");
set_config('mysql/dump/ignore', "e\nf");
$::dbh->do('CREATE TABLE a (i INT)');
$::dbh->do('CREATE TABLE b (i INT)');
$::dbh->do('CREATE TABLE c (i INT)');
$::dbh->do('CREATE TABLE d (i INT)');
$::dbh->do('CREATE TABLE e (i INT)');
is_deeply [list_tables()], [[],['a','b'],['e']],
    'list_tables: incremental, empty, ignore: NOT EMPTY, no other tables';
$::dbh->do('CREATE TABLE g (i INT)');
$::dbh->do('CREATE TABLE h (i INT)');
set_config('mysql/dump/ignore', "e\n");
is_deeply [list_tables()], [['g','h'],['a','b'],['e']],
    'list_tables: incremental, empty, ignore: NOT EMPTY, some other tables';
$::dbh->do('DROP TABLES a, b, c, d, e, g, h');
set_config('mysql/dump/incremental', q{});
set_config('mysql/dump/empty', q{});
set_config('mysql/dump/ignore', q{});

# - detect_unchanged()
#   * no dumps
#   * some dumps, some unchanged
#   * some dumps, no unchanged

$::dbh->do('CREATE TABLE a (i INT)');
$::dbh->do('CREATE TABLE b (i INT)');
$::dbh->do('CREATE TABLE c (i INT)');

$::dbh->do('INSERT INTO a VALUES (1),(2),(3)');
$::dbh->do('INSERT INTO b VALUES (10)');
my $full = ['a','b','c'];
is_deeply detect_unchanged($full), [],
    'detect_unchanged: no dumps';

SKIP: {
    skip 'user do not have LOCK TABLES privilege', 38
        if `echo "lock table a read;" | narada-mysql 2>&1` =~ /Access denied/i;

dump_full($full, []);
sleep 1;    # emulate delay in main()
$::dbh->do('INSERT INTO b VALUES (20),(30)');
is_deeply detect_unchanged($full), ['a','c'],
    'detect_unchanged: some unchanged';

$::dbh->do('INSERT INTO a VALUE (4)');
$::dbh->do('INSERT INTO c VALUE (100)');
is_deeply detect_unchanged($full), [],
    'detect_unchanged: no unchanged';

$::dbh->do('DROP TABLES a, b, c');
unlink glob 'var/mysql/*.sql';

# - del_dumps_except()
#   * empty $incremental & $unchanged, no dumps - do nothing
#   * empty $incremental & $unchanged, some incremental and full dumps - all deleted
#   * many full and incremental dumps with some in $incremental and $unchanged:
#     some incremental ALTERed - deleted,
#     some incremental TRUNCATED - deleted,
#     some incremental with new rows - not deleted,
#     some incremental not changed - not deleted,
#     some full not changed - not deleted,
#     some full changed - deleted

del_dumps_except([], []);
is_deeply [glob 'var/mysql/*.sql'], [],
    'del_dumps_except: no dumps - do nothing';

$::dbh->do('CREATE TABLE incr_a (i INT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE full_a (i INT)');
$::dbh->do('INSERT INTO incr_a SET s="first"');
$::dbh->do('INSERT INTO full_a SET i=10');
dump_scheme_except([]);
dump_full(['full_a'], []);
dump_incremental(['incr_a']);
$::dbh->do('INSERT INTO incr_a SET s="second"');
dump_incremental(['incr_a']);
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/db.scheme.sql',
    'var/mysql/full_a.sql',
    'var/mysql/incr_a.1-1.sql',
    'var/mysql/incr_a.2-2.sql',
    ],
    'del_dumps_except: dumped some full and incremental';
del_dumps_except([], []);
is_deeply [glob 'var/mysql/*.sql'], [],
    'del_dumps_except: some incremental and full dumps - all deleted';
$::dbh->do('DROP TABLES incr_a, full_a');

$::dbh->do('CREATE TABLE incr_a (i INT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE incr_b (i INT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE incr_c (i INT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE incr_d (i INT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE full_a (i INT)');
$::dbh->do('CREATE TABLE full_b (i INT)');
$::dbh->do('INSERT INTO incr_a SET s="first"');
$::dbh->do('INSERT INTO incr_b SET s="second"');
$::dbh->do('INSERT INTO incr_c SET s="third"');
$::dbh->do('INSERT INTO incr_d SET s="fourth"');
$::dbh->do('INSERT INTO full_a SET i=10');
$::dbh->do('INSERT INTO full_b SET i=100');
dump_scheme_except([]);
dump_full(['full_a','full_b'], []);
dump_incremental(['incr_a','incr_b','incr_c','incr_d']);
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/db.scheme.sql',
    'var/mysql/full_a.sql',
    'var/mysql/full_b.sql',
    'var/mysql/incr_a.1-1.sql',
    'var/mysql/incr_b.1-1.sql',
    'var/mysql/incr_c.1-1.sql',
    'var/mysql/incr_d.1-1.sql',
    ],
    'del_dumps_except: dumped many full and incremental';
sleep 1;
$::dbh->do('ALTER TABLE incr_a ADD COLUMN d DATETIME');
$::dbh->do('TRUNCATE TABLE incr_b');
$::dbh->do('INSERT INTO incr_c SET s="another third"');
$::dbh->do('INSERT INTO full_a SET i=20');
del_dumps_except(['incr_a','incr_b','incr_c','incr_d'], ['full_b']);
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/full_b.sql',
    'var/mysql/incr_c.1-1.sql',
    'var/mysql/incr_d.1-1.sql',
    ],
    'del_dumps_except: complex test';

$::dbh->do('DROP TABLES incr_a, incr_b, incr_c, incr_d, full_a, full_b');
unlink glob 'var/mysql/*.sql';

# - dump_scheme_except()
#   * no tables, no $ignore
#   * some tables, no $ignore
#   * some tables, some $ignore
#   * some tables, all $ignore

sub helper_dump_scheme_except {
    my ($ignore) = @_;
    dump_scheme_except($ignore);
    ok -f 'var/mysql/db.scheme.sql', 'dump_scheme_except: scheme dumped';
    my $scheme = `cat var/mysql/db.scheme.sql`;
    unlink 'var/mysql/db.scheme.sql' or die "unlink: $!";
    my @tables = $scheme =~ /CREATE TABLE `(\w+)`/g;
    return [sort @tables];
}

is_deeply helper_dump_scheme_except([]), [],
    'dump_scheme_except: no tables in dump';

$::dbh->do('CREATE TABLE incr_a (i INT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE full_a (i INT)');
is_deeply helper_dump_scheme_except([]), ['full_a','incr_a'],
    'dump_scheme_except: all tables in dump';
is_deeply helper_dump_scheme_except(['full_a']), ['incr_a'],
    'dump_scheme_except: some tables ignored';
is_deeply helper_dump_scheme_except(['full_a','incr_a']), [],
    'dump_scheme_except: all tables ignored';

$::dbh->do('DROP TABLES incr_a, full_a');

# - dump_full()
#   * empty $full and $unchanged
#   * some $full, empty $unchanged
#   * some $full, some $unchanged
#   * some $full, all $unchanged

$::dbh->do('CREATE TABLE full_a (i INT)');
$::dbh->do('CREATE TABLE full_b (i INT)');

dump_full([], []);
is_deeply [sort glob 'var/mysql/*.sql'], [],
    'dump_full: nothing to dump';
unlink glob 'var/mysql/*.sql';

dump_full(['full_a','full_b'], []);
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/full_a.sql',
    'var/mysql/full_b.sql',
    ],
    'dump_full: some full, no unchanged';
unlink glob 'var/mysql/*.sql';

dump_full(['full_a','full_b'], ['full_a']);
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/full_b.sql',
    ],
    'dump_full: some full, some unchanged';
unlink glob 'var/mysql/*.sql';

dump_full(['full_a','full_b'], ['full_a','full_b']);
is_deeply [sort glob 'var/mysql/*.sql'], [],
    'dump_full: some full, all unchanged';
unlink glob 'var/mysql/*.sql';

$::dbh->do('DROP TABLES full_a, full_b');

# - dump_incremental()
#   * empty $incremental
#   * throw on $incremental for table with wrong PRIMARY KEY (not *INT, not
#     AUTO_INCREMENTAL, multicolumn PRIMARY KEY, PRIMARY KEY not first column)
#   * some $incremental changed, some unchanged, some has no previous dumps

$::dbh->do('CREATE TABLE a (i INT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE b (i MEDIUMINT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE c (i TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE e1 (i FLOAT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE e2 (i INT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE e3 (s TEXT, i INT AUTO_INCREMENT PRIMARY KEY)');
$::dbh->do('CREATE TABLE e4 (i INT AUTO_INCREMENT, s TEXT, PRIMARY KEY(i,s(256)))');

dump_incremental([]);
is_deeply [sort glob 'var/mysql/*.sql'], [],
    'dump_incremental: do nothing';
unlink glob 'var/mysql/*.sql';

$::dbh->do('INSERT INTO e1 SET s="error1"');
$::dbh->do('INSERT INTO e2 SET s="error2"');
$::dbh->do('INSERT INTO e3 SET s="error3"');
$::dbh->do('INSERT INTO e4 SET s="error4"');
throws_ok { dump_incremental(['e1']); } qr/must be: INT AUTO_INCREMENT PRIMARY KEY/,
    'dump_incremental: wrong incremental table format';
throws_ok { dump_incremental(['e2']); } qr/must be: INT AUTO_INCREMENT PRIMARY KEY/,
    'dump_incremental: wrong incremental table format';
throws_ok { dump_incremental(['e3']); } qr/must be: INT AUTO_INCREMENT PRIMARY KEY/,
    'dump_incremental: wrong incremental table format';
throws_ok { dump_incremental(['e4']); } qr/must be: INT AUTO_INCREMENT PRIMARY KEY/,
    'dump_incremental: wrong incremental table format';

$::dbh->do('INSERT INTO a SET s="first"');
$::dbh->do('INSERT INTO a SET s="one more first"');
$::dbh->do('INSERT INTO b SET s="second"');
dump_incremental(['a','b','c']);
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/a.1-2.sql',
    'var/mysql/b.1-1.sql',
    ],
    'dump_incremental: some tables dumped';
$::dbh->do('INSERT INTO b SET s="one more second"');
$::dbh->do('INSERT INTO c SET s="third"');
dump_incremental(['a','b','c']);
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/a.1-2.sql',
    'var/mysql/b.1-1.sql',
    'var/mysql/b.2-2.sql',
    'var/mysql/c.1-1.sql',
    ],
    'dump_incremental: some unchanged, some changed and some new';
unlink glob 'var/mysql/*.sql';

$::dbh->do('DROP TABLES a, b, c, e1, e2, e3, e4');

# - main()
#   * no previous dumps, no tables
#   * some full, incremental, empty and ignore
#   * some full/incremental unchanged/changed

throws_ok { main('param') }    qr/Usage:/,
    'main: too many params';

main();
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/db.scheme.sql',
    ],
    'main: no previous dumps, no tables';

# XXX why I have to repeat this here?
$::dbh->do('SET default_storage_engine=MYISAM');

$::dbh->do('CREATE TABLE incr_a (i INT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE incr_b (i INT AUTO_INCREMENT PRIMARY KEY, s TEXT)');
$::dbh->do('CREATE TABLE full_a (i INT)');
$::dbh->do('CREATE TABLE full_b (i INT)');
$::dbh->do('CREATE TABLE empty_a (i INT)');
$::dbh->do('CREATE TABLE ignore_a (i INT)');
$::dbh->do('INSERT INTO incr_a SET s="first"');
$::dbh->do('INSERT INTO incr_a SET s="another first"');
$::dbh->do('INSERT INTO incr_b SET s="second"');
$::dbh->do('INSERT INTO full_a SET i=10');
$::dbh->do('INSERT INTO full_b SET i=100');
$::dbh->do('INSERT INTO empty_a SET i=1000');
$::dbh->do('INSERT INTO ignore_a SET i=10000');
set_config('mysql/dump/incremental', "incr_a\nincr_b\n");
set_config('mysql/dump/empty', "empty_a\n");
set_config('mysql/dump/ignore', "ignore_a\n");
main();
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/db.scheme.sql',
    'var/mysql/full_a.sql',
    'var/mysql/full_b.sql',
    'var/mysql/incr_a.1-2.sql',
    'var/mysql/incr_b.1-1.sql',
    ],
    'main: some full, incremental, empty and ignore';

$::dbh->do('INSERT INTO incr_b SET s="another second"');
$::dbh->do('INSERT INTO full_b SET i=200');
my %old_mtime = map {$_ => mtime($_)} glob 'var/mysql/*.sql';
main();
my %new_mtime = map {$_ => mtime($_)} glob 'var/mysql/*.sql';
is_deeply [sort glob 'var/mysql/*.sql'], [
    'var/mysql/db.scheme.sql',
    'var/mysql/full_a.sql',
    'var/mysql/full_b.sql',
    'var/mysql/incr_a.1-2.sql',
    'var/mysql/incr_b.1-1.sql',
    'var/mysql/incr_b.2-2.sql',
    ],
    'main: some full/incremental unchanged/changed';
my @unchanged = (
    'var/mysql/full_a.sql',
    'var/mysql/incr_a.1-2.sql',
    'var/mysql/incr_b.1-1.sql',
    );
my @changed = (
    'var/mysql/db.scheme.sql',
    'var/mysql/full_b.sql',
    'var/mysql/incr_b.2-2.sql',
    );
is   $old_mtime{$_}, $new_mtime{$_}, "unchanged $_" for @unchanged;
isnt $old_mtime{$_}, $new_mtime{$_}, "changed   $_" for @changed;

set_config('mysql/db', q{});
main();
is   $new_mtime{'var/mysql/db.scheme.sql'}, mtime('var/mysql/db.scheme.sql'),
    'main: do nothing without mysql/db';
set_config('mysql/db', $db);
main();
isnt $new_mtime{'var/mysql/db.scheme.sql'}, mtime('var/mysql/db.scheme.sql'),
    'main: recreate SCHEME with mysql/db';

}


system('narada-setup-mysql --clean');
done_testing();
