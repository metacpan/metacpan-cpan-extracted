# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 26-packages.t'

use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok('ZOOM') };

# yaz-ztest simply ignores all these package requests, returning a
# vacuous "success" status. There is really point in modifying the
# tests to work "correctly" under these circumstances, as they won't
# actually be testing anyting. So we'll just pull the plug right here.
exit 0;


# We will create, and destroy, a new database with a random name
my $host = "z3950.indexdata.com:2100";
my $dbname = join("", map { chr(ord("a") + int(rand(26))) } 1..10);

# Connect anonymously, and expect this to fail
my $conn = makeconn($host, undef, undef, 1011);

# Connect as a user, but with incorrect password -- expect failure
$conn->destroy();
$conn = makeconn($host, "user", "badpw", 1011);

# Connect as a non-privileged user with correct password
$conn->destroy();
$conn = makeconn($host, "user", "frog", 0);

# Non-privileged user can't create database
makedb($conn, $dbname, 223);

# Connect as a privileged user with correct password, check DB is absent
$conn->destroy();
$conn = makeconn($host, "admin", "fish", 0);
$conn->option(databaseName => $dbname);
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

    my $options = new ZOOM::Options();
    $options->option(user => $user)
	if defined $user;
    $options->option(password => $password)
	if defined $password;

    my $conn;
    eval { $conn = create ZOOM::Connection($options) };
    ok(!$@, "unconnected connection object created");

    eval { $conn->connect($host, 0) };
    my($errcode, $errmsg, $addinfo) = maybe_error($@);

    ok($errcode == $expected_error,
       "connection to '$host'" . ($errcode ? " refused ($errcode)" : ""));

    return $conn;
}


sub makedb {
    my($conn, $dbname, $expected_error) = @_;

    my $p = $conn->package();
    # Inspection of the ZOOM-C code shows that this can never fail, in fact.
    ok(defined $p, "created package");

    $p->option(databaseName => $dbname);
    my $val = $p->option("databaseName");
    ok($val eq $dbname, "package option retrieved as expected");

    eval { $p->send("create") };
    my($errcode, $errmsg, $addinfo) = maybe_error($@);
    ok($errcode == $expected_error, "database creation '$dbname'" .
       ($errcode ? " refused ($errcode)" : ""));

    # Now we can inspect the package options to find out more about
    # how the server dealt with the request.  However, it seems that
    # the "package database" described in the standard is not used,
    # and that the only options we can inspect are the following:
    $val = $p->option("targetReference");
    $val = $p->option("xmlUpdateDoc");
    # ... and we know nothing about expected or actual values.

    $p->destroy();
    ok(1, "destroyed createdb package");
}


sub dropdb {
    my($conn, $dbname, $expected_error) = @_;

    my $p = $conn->package();
    # No need to keep ok()ing this, or checking the option-setting
    $p->option(databaseName => $dbname);
    eval { $p->send("drop") };
    my($errcode, $errmsg, $addinfo) = maybe_error($@);
    ok($errcode == $expected_error,
       "database drop '$dbname'"  . ($errcode ? " refused $errcode" : ""));

    $p->destroy();
    ok(1, "destroyed dropdb package");
}


# We always use "specialUpdate", which adds a record or replaces it if
# it's already there.  By contrast, "insert" fails if the record
# already exists, and "replace" fails if it does not.
#
sub updaterec {
    my($conn, $id, $file, $expected_error) = @_;

    my $p = $conn->package();
    $p->option(action => "specialUpdate");
    $p->option(recordIdOpaque => $id);
    $p->option(record => $file);

    eval { $p->send("update") };
    my($errcode, $errmsg, $addinfo) = maybe_error($@);
    ok($errcode == $expected_error, "record update $id" .
       ($errcode ? " failed $errcode '$errmsg' ($addinfo)" : ""));

    $p->destroy();
    ok(1, "destroyed update package");
}


sub count_hits {
    my($conn, $dbname, $query, $expected_error, $expected_count) = @_;

    my $rs;
    eval { $rs = $conn->search_pqf($query) };
    my($errcode, $errmsg, $addinfo) = maybe_error($@);
    ok($errcode == $expected_error, "database '$dbname' " .
       ($errcode == 0 ? "can be searched" : "not searchable ($errcode)"));

    return if $errcode != 0;
    my $n = $rs->size($rs);
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


# Return the elements of an exception as separate scalars
sub maybe_error {
    my ($x) = @_;

    if ($x && $x->isa("ZOOM::Exception")) {
	return ($x->code(),
		$x->message(),
		$x->addinfo());
    } else {
	return (0, undef, undef);
    }
}


# To investigate the set of databases created, use Explain Classic:
#
#	$ yaz-client -u admin/fish test.indexdata.com:2118/IR-Explain-1
#	Z> find @attr exp1 1=1 databaseinfo
#	Z> format xml
#	Z> show 3
#
# It seems that Explain still knows about dropped databases.
