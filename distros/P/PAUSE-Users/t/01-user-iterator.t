#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 3;
use PAUSE::Users;

#-----------------------------------------------------------------------
# construct PAUSE::Users
#-----------------------------------------------------------------------

my $users = PAUSE::Users->new(path => 't/00whois-mini.xml');

ok(defined($users), 'instantiate PAUSE::Users');

#-----------------------------------------------------------------------
# construct the iterator
#-----------------------------------------------------------------------
my $iterator = $users->user_iterator();

ok(defined($iterator), 'create user iterator');

#-----------------------------------------------------------------------
# Construct a string with info
#-----------------------------------------------------------------------
my $expected = <<'END_EXPECTED';
NBERTRAM|Neil Bertram|CENSORED|0
NEILB|Neil Bowers|neil@bowers.com|1
NHAINER|Neil Hainer|CENSORED|0
END_EXPECTED

my $string = '';

while (my $user = $iterator->next_user) {
    $string .= $user->id()
               .'|'
               .$user->fullname()
               .'|'
               .$user->email()
               .'|'
               .$user->has_cpandir()
               ."\n";
}

is($string, $expected, "rendered user details");

