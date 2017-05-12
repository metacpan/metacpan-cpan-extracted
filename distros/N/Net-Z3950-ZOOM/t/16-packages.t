# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 16-packages.t'

# Tests:
#	connect anonymously => refused
#	connect as "user" with incorrect password => refused
#	connect as "user" with correct password
#		try to create tmpdb => EPERM
#	connect as admin with correct password
#		try to create tmpdb => OK
#		try to create tmpdb => EFAIL

use strict;
use warnings;
use Test::More tests => 39;

BEGIN { use_ok('Net::Z3950::ZOOM') };


# We will create, and destroy, a new database with a random name
my $host = "z3950.indexdata.com:2100";
my $dbname = join("", map { chr(ord("a") + int(rand(26))) } 1..10);

# Connect anonymously, and expect this to fail
my $conn = makeconn($host, undef, undef, 1011);

# Connect as a user, but with incorrect password -- expect failure
Net::Z3950::ZOOM::connection_destroy($conn);
$conn = makeconn($host, "user", "badpw", 1011);

# Connect as a non-privileged user with correct password
Net::Z3950::ZOOM::connection_destroy($conn);
$conn = makeconn($host, "user", "frog", 0);

# Non-privileged user can't create database
makedb($conn, $dbname, 223);

# Connect as a privileged user with correct password, check DB is absent
Net::Z3950::ZOOM::connection_destroy($conn);
$conn = makeconn($host, "admin", "fish", 0);
Net::Z3950::ZOOM::connection_option_set($conn, databaseName => $dbname);
count_hits($conn, $dbname, "the", 109);

# Now create the database and check that it is present but empty
makedb($conn, $dbname, 0);
count_hits($conn, $dbname, "the", 114);

# Trying to create the same database again will fail EEXIST
makedb($conn, $dbname, 224);

# Add a single record, and check that it can be found
updaterec($conn, 1, content_of("samples/records/esdd0006.grs"), 0);
count_hits($conn, $dbname, "the", 0, 1);

# Add the same record with the same ID: overwrite => no change
updaterec($conn, 1, content_of("samples/records/esdd0006.grs"), 0);
count_hits($conn, $dbname, "the", 0, 1);

# Add it again record with different ID => new copy added
updaterec($conn, 2, content_of("samples/records/esdd0006.grs"), 0);
count_hits($conn, $dbname, "the", 0, 2);

# Now drop the newly-created database
dropdb($conn, $dbname, 0);

# A second dropping should fail, as the database is no longer there.
dropdb($conn, $dbname, 235);


sub makeconn {
    my($host, $user, $password, $expected_error) = @_;

    my $options = Net::Z3950::ZOOM::options_create();
    Net::Z3950::ZOOM::options_set($options, user => $user)
	if defined $user;
    Net::Z3950::ZOOM::options_set($options, password => $password)
	if defined $password;

    my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");
    my $conn = Net::Z3950::ZOOM::connection_create($options);
    $errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
    ok($errcode == 0, "unconnected connection object created");

    Net::Z3950::ZOOM::connection_connect($conn, $host, 0);
    $errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
    ok($errcode == $expected_error,
       "connection to '$host'" . ($errcode ? " refused ($errcode)" : ""));

    return $conn;
}


sub makedb {
    my($conn, $dbname, $expected_error) = @_;

    my $o = Net::Z3950::ZOOM::options_create();
    my $p = Net::Z3950::ZOOM::connection_package($conn, $o);
    # Inspection of the ZOOM-C code shows that this can never fail, in fact.
    ok(defined $p, "created package");

    Net::Z3950::ZOOM::package_option_set($p, databaseName => $dbname);
    my $val = Net::Z3950::ZOOM::package_option_get($p, "databaseName");
    ok($val eq $dbname, "package option retrieved as expected");

    Net::Z3950::ZOOM::package_send($p, "create");
    my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");
    $errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
    ok($errcode == $expected_error, "database creation '$dbname'" .
       ($errcode ? " refused ($errcode)" : ""));

    # Now we can inspect the package options to find out more about
    # how the server dealt with the request.  However, it seems that
    # the "package database" described in the standard is not used,
    # and that the only options we can inspect are the following:
    $val = Net::Z3950::ZOOM::package_option_get($p, "targetReference");
    $val = Net::Z3950::ZOOM::package_option_get($p, "xmlUpdateDoc");
    # ... and we know nothing about expected or actual values.

    Net::Z3950::ZOOM::package_destroy($p);
    ok(1, "destroyed createdb package");
}


sub dropdb {
    my($conn, $dbname, $expected_error) = @_;

    my $o = Net::Z3950::ZOOM::options_create();
    my $p = Net::Z3950::ZOOM::connection_package($conn, $o);
    # No need to keep ok()ing this, or checking the option-setting
    Net::Z3950::ZOOM::package_option_set($p, databaseName => $dbname);
    Net::Z3950::ZOOM::package_send($p, "drop");
    my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");
    $errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
    ok($errcode == $expected_error,
       ("database drop '$dbname'" . ($errcode ? " refused $errcode" : "") .
	($expected_error ? " expected $expected_error but succeeded" : "")));

    Net::Z3950::ZOOM::package_destroy($p);
    ok(1, "destroyed dropdb package");
}


# We always use "specialUpdate", which adds a record or replaces it if
# it's already there.  By contrast, "insert" fails if the record
# already exists, and "replace" fails if it does not.
#
sub updaterec {
    my($conn, $id, $file, $expected_error) = @_;

    my $o = Net::Z3950::ZOOM::options_create();
    my $p = Net::Z3950::ZOOM::connection_package($conn, $o);
    Net::Z3950::ZOOM::package_option_set($p, action => "specialUpdate");
    Net::Z3950::ZOOM::package_option_set($p, recordIdOpaque => $id);
    Net::Z3950::ZOOM::package_option_set($p, record => $file);

    Net::Z3950::ZOOM::package_send($p, "update");
    my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");
    $errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
    ok($errcode == $expected_error, "record update $id" .
       ($errcode ? " failed $errcode '$errmsg' ($addinfo)" : ""));

    Net::Z3950::ZOOM::package_destroy($p);
    ok(1, "destroyed update package");
}


sub count_hits {
    my($conn, $dbname, $query, $expected_error, $expected_count) = @_;

    my $rs = Net::Z3950::ZOOM::connection_search_pqf($conn, $query);
    my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");
    $errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
    ok($errcode == $expected_error, "database '$dbname' " .
       ($errcode == 0 ? "can be searched" : "not searchable ($errcode)"));
    return if $errcode != 0;
    my $n = Net::Z3950::ZOOM::resultset_size($rs);
    ok($n == $expected_count,
       "database '$dbname' has $n records (expected $expected_count)");
}


sub content_of {
    my($filename) = @_;

    use IO::File;
    my $f = new IO::File("<$filename")
	or die "can't open file '$filename': $!";
    my $text = join("", <$f>);
    $f->close();

    return $text;
}
