#! perl
#
# Tests for Nitesi::Account::Password.

use strict;
use warnings;

use Test::More tests => 5;

use Nitesi::Account::Password;

my ($crypt, $hash, $ret);

$crypt = Nitesi::Account::Password->new;

$hash = $crypt->password('nevairbe');

# check whether password matches
$ret = $crypt->check($hash, 'nevairbe');
ok($ret, 'password match');

# check whether password fails
$ret = $crypt->check($hash, 'wrong');
ok(! $ret, 'password mismatch');

# repeat for md5
$hash = $crypt->password('nevairbe', 'md5');

# check whether password matches
$ret = $crypt->check($hash, 'nevairbe');
ok($ret, 'password match (md5)');

# check whether password fails
$ret = $crypt->check($hash, 'wrong');
ok(! $ret, 'password mismatch (md5)');

# creates random password
$ret = $crypt->make_password;
ok(defined $ret && length($ret) == 8, 'random password');
