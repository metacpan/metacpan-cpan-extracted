use warnings;
use strict;

use Test::More;
use Test::Exception;
use PGObject::Util::DBAdmin;
use File::Temp;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 21;

# Constructor

my $dbh;
my $db;
my $temp;
my $backup_file;

ok($db = PGObject::Util::DBAdmin->new(
     username => 'postgres',
     password => undef,
     dbname   => 'pgobject_test_db',
     host     => 'localhost',
     port     => '5432'
), 'Created db admin object');

# Drop db if exists
eval { $db->drop };


# Test backup_globals to auto-generated temp file
ok($backup_file = $db->backup_globals(
    tempdir => 't/var/',
), 'backup_globals outputs to auto-generated file');
ok(-f $backup_file, 'backup_globals output to auto-generated file exists');
ok($backup_file =~ m|^t/var/|, 'backup_globals output to auto-generated file respects tempdir parameter');
cmp_ok(-s $backup_file, '>', 0, 'backup_globals output to auto-generated file has size > 0');
is((stat($backup_file))[2] & 07777, 0600, 'backup_globals output to auto-generated file has permissions 0600');
unlink $backup_file;


# Test backup_globals to not-existing specified file
$temp = File::Temp->new->filename;
ok(!-f $temp, 'backup_globals non-existent specified file does not exist');
ok($backup_file = $db->backup_globals(
    file => $temp,
), 'backup_globals outputs to non-existent specified file');
ok(-f $backup_file, 'backup_globals output to non-existent specified file exists');
ok($temp =~ m/^$backup_file$/, 'backup_globals output to non-existent specified file respects file parameter');
cmp_ok(-s $backup_file, '>', 0, 'backup_globals output to non-existent specified file has size > 0');
is((stat($backup_file))[2] & 07777, 0600, 'backup_globals output to non-existent specified file has permissions 0600');
unlink $backup_file;

# Test backup_globals to overwrite existing specified file with 'wrong' permssions
# Makes sure that file is written and permissions are unchanged
$temp = File::Temp->new;
chmod 0777, $temp->filename; # Give it wrong permissions
is((stat($temp->filename))[2] & 07777, 0777, 'specified backup_globals output file created with permissions 0777');
ok($backup_file = $db->backup_globals(
    file => $temp->filename,
), 'backup_globals outputs to existing specified file with permissions 0777');
ok($temp->filename =~ m/^$backup_file$/, 'backup_globals output to existing specified file respects file parameter');
cmp_ok(-s $backup_file, '>', 0, 'backup_globals output to existing specified file with permissions 0777 has size > 0');
is((stat($backup_file))[2] & 07777, 0777, 'backup_globals output to existing specified file retains permissions 0777');
undef $temp;

# Test backup_globals to overwrite existing specified file with 'right' permssions
# Make sure file is written and 'correct' 0600 permissions are retained
$temp = File::Temp->new;
is((stat($temp->filename))[2] & 07777, 0600, 'specified backup_globals output file created with permissions 0600');
ok($backup_file = $db->backup_globals(
    file => $temp->filename,
), 'backup globals outut to existing specified file with permissions 0600');
cmp_ok(-s $backup_file, '>', 0, 'backup_globals to existing specified file with permissions 0600 has size > 0');
is((stat($backup_file))[2] & 07777, 0600, 'backup_globals output to existing specified file retains permissions 0600');
undef $temp;

