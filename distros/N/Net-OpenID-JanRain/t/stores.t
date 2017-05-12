#!/usr/bin/perl 

use Test::More tests => 408;

use Net::OpenID::JanRain::Association;
use Net::OpenID::JanRain::CryptUtil qw( randomString );

use strict;

#generate $allowed_handle, $allowed_nonce
my $allowed_handle = "aeiouthsnmlrpc";
my $allowed_nonce = $allowed_handle;

sub genHandle {
    my($n) = @_;
    return randomString($n, $allowed_handle);
}

sub genNonce {
    return randomString(8, $allowed_nonce);
}

sub genSecret {
    return randomString @_;
}


my $server_url = 'http://www.myopenid.com/openid';

my $now = time;

sub genAssoc {
    my($issued, $lifetime) = @_;
    defined($issued) or $issued = 0;
    defined($lifetime) or $lifetime = 600;

    my $sec = genSecret(20);
    my $hdl = genHandle(28);
    return Net::OpenID::JanRain::Association->new($hdl, $sec, $now+$issued, 
                            $lifetime, 'HMAC-SHA1');
}

sub checkRetrieve {
    my($store, $url, $handle, $expected) = @_;
    
    my $retrieved_assoc = $store->getAssociation($url, $handle);
    
    if ((not defined($expected)) or $store->isDumb()) {
        is($retrieved_assoc, undef, "No assoc when not expected");
    }
    else {
        isa_ok($retrieved_assoc, "Net::OpenID::JanRain::Association",
                    "association from store");
        ok($retrieved_assoc->equals($expected), "retrieved association is same as expected assoc");
        isnt($retrieved_assoc, $expected, "the two assocs are not the same object");
        is($retrieved_assoc->{handle}, $expected->{handle}, "second guess equals method (handle)");
        is($retrieved_assoc->{secret}, $expected->{secret}, "second guess equals method (secret)");
    }
}

sub checkRemove {
    my($store, $url, $handle, $expected) = @_;
    my $present = $store->removeAssociation($url, $handle);
    my $expectedPresent = (not $store->isDumb() and $expected);
    # use not to ensure their truth values are used and not their values
    is((not $present), (not $expectedPresent), "assoc removal check");
}

sub testUseNonce {
    my($store, $nonce, $expected) = @_;
    #my $expected = $store->isDumb() if $store->isDumb();
    my $actual = $store->useNonce($nonce);
    # use not to ensure their truth values are used and not their values
    is((not $actual), (not $expected), "Nonce use check");
}
    
sub testStore {
    my($store) = @_;

    my $assoc = genAssoc();

    # Make sure that a missing $association returns no result
    # print "checkRetrieve($server_url);\n";
    checkRetrieve($store, $server_url);

    # Check that after storage, getting returns the same result
    $store->storeAssociation($server_url, $assoc);
    # print "checkRetrieve($server_url, undef, $assoc);\n";
    checkRetrieve($store, $server_url, undef, $assoc);

    # more than once
    # print "checkRetrieve($server_url, undef, $assoc);\n";
    checkRetrieve($store, $server_url, undef, $assoc);

    # Storing more than once has no ill effect
    $store->storeAssociation($server_url, $assoc);
    # print "checkRetrieve($server_url, undef, $assoc);\n";
    checkRetrieve($store, $server_url, undef, $assoc);

    # Removing an $association that does not exist returns not present
    # print "checkRemove($server_url, $assoc->{handle}x, undef);\n";
    checkRemove($store, $server_url, $assoc->{handle}."x", undef);

    # Removing an $association that does not exist returns not present
    # print "checkRemove($server_url x, $assoc->{handle}, undef);\n";
    checkRemove($store, $server_url."x", $assoc->{handle}, undef);

    # Removing an $association that is present returns present
    # print "checkRemove($server_url, $assoc->{handle}, 1);\n";
    checkRemove($store, $server_url, $assoc->{handle}, 1);

    # but not present on subsequent calls
    # print "checkRemove($server_url, $assoc->{handle}, undef);\n";
    checkRemove($store, $server_url, $assoc->{handle}, undef);

    # Put $assoc back in the store
    $store->storeAssociation($server_url, $assoc);

    # More recent and expires after $assoc
    my $assoc2 = genAssoc(1);
    $store->storeAssociation($server_url, $assoc2);

    # After storing an $association with a different handle, but the
    # same $server_url, the handle with the later expiration is returned.
    # print "checkRetrieve($server_url, undef, $assoc2);\n";
    checkRetrieve($store, $server_url, undef, $assoc2);

    # We can still retrieve the older $association
    # print "checkRetrieve($server_url, $assoc->{handle}, $assoc);\n";
    checkRetrieve($store, $server_url, $assoc->{handle}, $assoc);

    # Plus we can retrieve the $association with the later expiration
    # explicitly
    # print("checkRetrieve($server_url, $assoc2->{handle}, $assoc2);");
    checkRetrieve($store, $server_url, $assoc2->{handle}, $assoc2);

    # More recent, but expires earlier than $assoc2 or $assoc
    my $assoc3 = genAssoc(2, 100);
    $store->storeAssociation($server_url, $assoc3);

    checkRetrieve($store, $server_url, undef, $assoc3);
    checkRetrieve($store, $server_url, $assoc->{handle}, $assoc);
    checkRetrieve($store, $server_url, $assoc2->{handle}, $assoc2);
    checkRetrieve($store, $server_url, $assoc3->{handle}, $assoc3);

    checkRemove($store, $server_url, $assoc2->{handle}, 1);

    checkRetrieve($store, $server_url, undef, $assoc3);
    checkRetrieve($store, $server_url, $assoc->{handle}, $assoc);
    checkRetrieve($store, $server_url, $assoc2->{handle}, undef);
    checkRetrieve($store, $server_url, $assoc3->{handle}, $assoc3);

    checkRemove($store, $server_url, $assoc2->{handle}, undef);
    checkRemove($store, $server_url, $assoc3->{handle}, 1);

    checkRetrieve($store, $server_url, undef, $assoc);
    checkRetrieve($store, $server_url, $assoc->{handle}, $assoc);
    checkRetrieve($store, $server_url, $assoc2->{handle}, undef);
    checkRetrieve($store, $server_url, $assoc3->{handle}, undef);

    checkRemove($store, $server_url, $assoc2->{handle}, undef);
    checkRemove($store, $server_url, $assoc->{handle}, 1);
    checkRemove($store, $server_url, $assoc3->{handle}, undef);

    checkRetrieve($store, $server_url, undef, undef);
    checkRetrieve($store, $server_url, $assoc->{handle}, undef);
    checkRetrieve($store, $server_url, $assoc2->{handle}, undef);
    checkRetrieve($store, $server_url, $assoc3->{handle}, undef);

    checkRemove($store, $server_url, $assoc2->{handle}, undef);
    checkRemove($store, $server_url, $assoc->{handle}, undef);
    checkRemove($store, $server_url, $assoc3->{handle}, undef);

    # Nonce Functions

        # Random nonce (not in store);
    my $nonce1 = genNonce();

    # A nonce is not present by default
    testUseNonce($store, $nonce1, 0);

    # Storing once causes useNonce to return True the first, and only
    # the first, time it is called after the store.
    $store->storeNonce($nonce1);
    testUseNonce($store, $nonce1, 1);
    testUseNonce($store, $nonce1, 0);

    # Storing twice has the same effect as storing once.
    $store->storeNonce($nonce1);
    $store->storeNonce($nonce1);
    testUseNonce($store, $nonce1, 1);
    testUseNonce($store, $nonce1, 0);

    ### Auth key functions

    # There is no key to start with, so generate a new key and return it.
    my $key = $store->getAuthKey();

    # The second time around should return the same as last time.
    my $key2 = $store->getAuthKey();
    is($key, $key2, "AuthKey remains the same");
    length($key) == $store->{AUTH_KEY_LEN};

}

sub test_filestore {
    use Net::OpenID::JanRain::Stores::FileStore;
    my $tempdirname = "testfilestore";
    system "rm -r $tempdirname" if -d $tempdirname;
    mkdir $tempdirname;
    my $store = Net::OpenID::JanRain::Stores::FileStore->new($tempdirname);
    testStore($store);
    system "rm -r $tempdirname";
}

sub test_mysqlstore {
    use Net::OpenID::JanRain::Stores::MySQLStore;
    use DBI;

    my $drh = DBI->install_driver("mysql");

    my $now = time;
    my $db_host = 'dbtest';
    my $db_name = "perltest_${now}_$$";
    my $username = 'openid_test';
    my $password = '';
    
    my $dbh = DBI->connect("dbi:mysql:host=$db_host",
                            $username, $password);
    
    #my $rc = $dbh->func('createdb', $db_name, 'admin');
    my $rc = $dbh->do("CREATE DATABASE $db_name");
    
    $rc = $dbh->do("USE $db_name");
    
    my $store = Net::OpenID::JanRain::Stores::MySQLStore->new($dbh);

    $store->createTables;

    testStore($store);

    $dbh->func('dropdb', $db_name, 'admin');
}

sub test_postgresqlstore {
    use Net::OpenID::JanRain::Stores::PostgreSQLStore;
    use DBI;

    my $drh = DBI->install_driver("Pg");

    my $now = time;
    my $db_host = 'dbtest';
    my $db_name = "perltest_${now}_$$";
    my $username = 'openid_test';
    my $password = '';
    
    my $dbh = DBI->connect("dbi:Pg:dbname=template1;host=$db_host",
                            $username, $password);
    
    #my $rc = $dbh->func('createdb', $db_name, 'admin');
    $dbh->do("CREATE DATABASE $db_name") or die "could not create test db $dbh->errstr";
    
    $dbh->disconnect;

    $dbh = DBI->connect("dbi:Pg:dbname=$db_name;host=$db_host",
                            $username, $password);

    
    my $store = Net::OpenID::JanRain::Stores::PostgreSQLStore->new($dbh);

    $store->createTables;

    testStore($store);
    $dbh->disconnect;
    $dbh = DBI->connect("dbi:Pg:dbname=template1;host=$db_host",
                            $username, $password);
    $dbh->do("DROP DATABASE $db_name");
}


sub test_sqlitestore {
    use Net::OpenID::JanRain::Stores::SQLiteStore;
    use DBI;

    my $drh = DBI->install_driver("SQLite2");

    my $now = time;
    my $db_host = 'dbtest';
    my $db_name = "perltest_${now}_$$";
    
    my $dbh = DBI->connect("dbi:SQLite2:dbname=$db_name",
                            '', '');
    
    my $store = Net::OpenID::JanRain::Stores::SQLiteStore->new($dbh);

    $store->createTables;

    testStore($store);

}


test_filestore();
test_mysqlstore();
test_postgresqlstore();
test_sqlitestore();
exit(0);
