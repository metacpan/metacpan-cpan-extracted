use warnings;
use strict;

use Test::More;
use Test::Exception;
use PGObject::Util::DBAdmin;
use File::Temp;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 75;

# Constructor

my $dbh;
my $db;

ok($db = PGObject::Util::DBAdmin->new(
     username => 'postgres',
     password => $ENV{PGPASSWORD},
     dbname   => 'pgobject_test_db',
     host     => $ENV{PGHOST} // 'localhost',
     port     => $ENV{PGPORT} // '5432'
), 'Created db admin object');

# Drop db if exists
eval { $db->drop };

# List dbs
my @dblist;
ok(@dblist = $db->list_dbs, 'Got a db list');
ok (!grep {$_ eq 'pgobject_test_db'} @dblist, 'DB list does not contain pgobject_test_db');

# Create db
$db->create;

ok($db->server_version, 'Got a server version');

ok (grep {$_ eq 'pgobject_test_db'} $db->list_dbs, 'DB list does contain pgobject_test_db after create call');

# load with schema - valid sql
my $stdout_log = File::Temp->new->filename;
my $stderr_log = File::Temp->new->filename;
ok($db->run_file(
    file => 't/data/schema.sql',
    stdout_log => $stdout_log,
    errlog => $stderr_log, 
), 'Loaded schema');
ok(-f $stdout_log, 'run_file stdout_log file written');
ok(-f $stderr_log, 'run_file errlog file written');
cmp_ok(-s $stdout_log, '>', 0, 'run_file stdout_log file has size > 0 for valid sql');
cmp_ok(-s $stderr_log, '==', 0, 'run_file errlog file has size == 0 for valid sql');
ok(defined $db->stdout, 'after run_file stdout property is defined');
cmp_ok(length $db->stdout, '>', 0, 'after run_file, stdout property has length > 0');
ok(defined $db->stderr, 'after run_file stderr property is defined');
cmp_ok(length $db->stderr, '==', 0, 'after run_file, stderr property has length == 0 for valid sql');
unlink $stdout_log;
unlink $stderr_log;

ok ($dbh = $db->connect, 'Got dbi handle');

my ($foo) = @{ $dbh->selectall_arrayref('select count(*) from test_data') };
is ($foo->[0], 1, 'Correct count of data') ;

$dbh->disconnect;

# backup/drop/create/restore, formats undef, p, and c
foreach my $format ((undef, 'p', 'c')) {
    my $display_format = $format || 'undef';

    # Test backing up to specified file
    my $output_file = File::Temp->new->filename;
    my $backup;
    ok($backup = $db->backup(
           format => $format,
           file   => $output_file,
    ), "Made backup to specified file, format $display_format");
    ok($backup =~ m|^$output_file$|, 'backup respects file parameter');
    ok(-f $backup, "backup format $display_format output file exists");
    cmp_ok(-s $backup, '>', 0, "backup format $display_format output file has size > 0");
    unlink $backup;

    # Test backing up to auto-generated temp file
    ok($backup = $db->backup(
           format => $format,
           tempdir => 't/var/',
       ), "Made backup, format $display_format");
    ok($backup =~ m|^t/var/|, 'backup respects tempdir parameter');
    ok(-f $backup, "backup format $display_format output file exists");
    cmp_ok(-s $backup, '>', 0, "backup format $display_format output file has size > 0");

    ok($db->drop, "dropped db, format $display_format");
    ok (!(grep{$_ eq 'pgobject_test_db'} @dblist), 
           'DB list does not contain pgobject_test_db');

    dies_ok {
        $db->restore(
            format => $format,
            file   => 't/data/does-not-exist',
        )
    } "die when restore file does not exist, format $display_format";

    ok($db->create, "created db, format $display_format");
    ok($dbh = $db->connect, "Got dbi handle, format $display_format");
    ok($db->restore(
          format => $format,
          file   => $backup,
       ), "Restored backup, format $display_format");
    ok(defined $db->stderr, 'stderr captured during restore');
    ok(defined $db->stdout, 'stdout captured during restore');
    ok(($foo) = $dbh->selectall_arrayref('select count(*) from test_data'),
               "Got results from test data count, format $display_format");
    is($foo->[0]->[0], 1, "correct data count, format $display_format");
    $dbh->disconnect;
    unlink $backup;
}

# Test backing up to compressed auto-generated temp file
my $backup;
my $fh;
ok($backup = $db->backup(
    tempdir => 't/var/',
    compress => 9,
), "Made backup, compressed");
ok(-f $backup, "backup, compressed output file exists");
cmp_ok(-s $backup, '>', 0, "backup, compressed output file has size > 0");
ok(open ($fh, '<', $backup), "backup, compressed output file opened successfully");
like(<$fh>, qr/^\x1F\x8B/, 'backup, compressed output file is gzip format');
unlink $backup;
