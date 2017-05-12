# -*- perl -*-

use Test::More tests => 4;
use Net::SMS::Mollie;

# Create the object and set some defaults
my $m = Net::SMS::Mollie->new(username => 'user', password => 'admin');

# Check
ok($m->username, 'user');
ok($m->password, 'admin');

# Reset the luser
$m->username('luser');
$m->password('p4ssw0rd!');

my @cred = $m->login;

# Check again
ok($cred[0], 'luser');
ok($cred[1], 'p4ssw0rd!');

