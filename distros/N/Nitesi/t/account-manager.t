#! perl
#
# Tests for Nitesi Account Manager

use strict;
use warnings;

use Test::More tests => 16;

use Data::Dumper;
use Nitesi::Account::Manager;

my ($account, $ret, $start_time);

# without account providers
$account = Nitesi::Account::Manager->new;
isa_ok($account, 'Nitesi::Account::Manager');
isa_ok($account->password_manager, 'Nitesi::Account::Password');
$ret = $account->login(username => 'racke', password => 'nevairbe');
ok ($ret == 0);

$start_time = time;

# with sample account provider
$account = Nitesi::Account::Manager->new(provider_sub => \&providers);
isa_ok($account, 'Nitesi::Account::Manager');
isa_ok($account->password_manager, 'Nitesi::Account::Password');
$ret = $account->login(username => 'racke', password => 'nevairbe');

ok ($ret == 1);
$ret = $account->last_login;
ok ($ret == 0, "Test initial last login value.")
    || diag "Last login is $ret instead of 0.";


my @parr = $account->permissions;
my $pref = $account->permissions;
is_deeply([sort @parr], ['authenticated', 'test'])
    || diag "Returned array from permissions method: ", Dumper(\@parr);
is_deeply([sort keys %$pref], ['authenticated', 'test'])
    || diag "Returned hash from permissions method: ", Dumper($pref);

# test last login
$account->logout;
$ret = $account->login(username => 'racke', password => 'nevairbe');
ok ($ret == 1)
    || diag "Login failed with $ret.";
$ret = $account->last_login;

ok ($ret >= $start_time, "Test last login value.")
    || diag "Last login $ret is older than $start_time.";

# test permission for authenticated user
@parr = $account->permissions;
is_deeply([sort @parr], ['authenticated', 'test'])
    || diag "Returned array from permissions method: ", Dumper(\@parr);

# with bogus password
$ret = $account->login(username => 'racke', password => 'neviarbe');
ok ($ret == 0);

sub providers {
    return [['Nitesi::Account::Provider::Test',
            users => {racke => {password => 'nevairbe',
                                uid => 666,
                                permissions => [qw/test/],
                               }}]];
}

diag "Testing unauthenticated";
$account = Nitesi::Account::Manager->new(provider_sub => \&providers);
$account->login(username => 'pippo', password => 'puppa');
ok($account->uid == 0, "account uid is 0");
ok(!$account->username, "account username returns false");
eval {
    $account->logout;
};
ok(!$@, "No crash on log out");

