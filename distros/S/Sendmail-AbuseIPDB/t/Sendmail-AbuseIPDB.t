# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sendmail-AbuseIPDB.t'

#########################

use Test::More tests => 9;
BEGIN { use_ok('Sendmail::AbuseIPDB') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

eval
{
    my $broken = Sendmail::AbuseIPDB->new();
};
like( $@, qr/^Key argument is mandatory, get your API key by creating an account/, 'Missing argument' );

my $db = Sendmail::AbuseIPDB->new(Key => '123456');
isa_ok( $db, 'Sendmail::AbuseIPDB' );

eval
{
    my $broken = Sendmail::AbuseIPDB->new(Key => '123456', Strange => 'Hello there');
};
like( $@, qr/^Unknown argument Strange/, 'Unknown argument' );

# ====== Magic URL used for testing ======
$db = Sendmail::AbuseIPDB->new(Key => '123456', BaseURL => 'test://');
isa_ok( $db, 'Sendmail::AbuseIPDB' );

my %category_data = $db->get( '192.168.0.1' );
is( $category_data{'Email Spam'}, 11, 'Check email category' );
# use Data::Dumper;  diag( Dumper( \%category_data ));

my $url = $db->get( '192.168.0.3' );

is( $url, 'test://check/192.168.0.3/json?key=123456&days=30', 'Check URL parameters for get() with default days' );

is( $db->catg( 14 ), 'Port Scan', 'Category conversion' );

# ====== Magic URL check reporting ======
$url = $db->report( '192.168.0.3', 'Test Only', 'Port Scan', 'Exploited Host' );

is( $url, 'test://report/json?key=123456&category=14%2C20&comment=Test+Only&ip=192.168.0.3', 'Check URL parameters for report()' );


