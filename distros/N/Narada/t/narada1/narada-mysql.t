use lib 't'; use narada1::share; guard my $guard;
use DBI;
use Test::Database;
use Narada::Config qw( set_config );


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';
$::dbh = $h->dbh->clone({RaiseError=>1});
my $db = $h->name;
my $db_quoted = $::dbh->quote_identifier($db);
$::dbh->do("DROP DATABASE IF EXISTS $db_quoted");
$::dbh->do("CREATE DATABASE $db_quoted");


is   scalar `narada-mysql param </dev/null 2>&1`, "Usage: narada-mysql\n", 'usage';
is   scalar `narada-mysql       </dev/null 2>&1`, "ERROR: config/db/db absent or empty!\n", 'no db';
set_config('db/db', $db);
set_config('db/login', 'wrong login');
like scalar `narada-mysql       </dev/null 2>&1`, qr/Access denied|\A\z/i, 'bad login, empty pass';
set_config('db/pass', 'wrong pass');
like scalar `narada-mysql       </dev/null 2>&1`, qr/Access denied/i, 'bad pass';
set_config('db/login', $h->username);
set_config('db/pass', $h->password);
is   scalar `narada-mysql       </dev/null 2>&1`, q{}, 'auth ok';
is   scalar `echo "SELECT 1+2;" | narada-mysql 2>&1`, "1+2\n3\n", 'simple select';
set_config('db/host', '127.0.0.1');
set_config('db/port', '36');
like scalar `narada-mysql       </dev/null 2>&1`, qr/Can't connect/i, 'bad port';
set_config('db/port', '3306');
is   scalar `narada-mysql       </dev/null 2>&1`, q{}, 'good host:port';


$::dbh->prepare('DROP DATABASE '.$db)->execute();
done_testing();
