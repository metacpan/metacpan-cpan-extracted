# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl OpenSMTPD-Password-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('OpenSMTPD::Password::XS');
	use_ok('OpenSMTPD::Password', qw(newhash checkhash))
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $hash = newhash('password');
ok(defined($hash), 'newhash returns something');
ok(length($hash), 'and it wasn\'t empty');
ok(checkhash('password', $hash), 'checkhash likes our newhash');

open(SMTPCTL, "smtpctl encrypt password |") or die "Can't fork: $!";

my $newhash = <SMTPCTL>;

close(SMTPCTL);
chomp($newhash);

ok(checkhash('password', $newhash), 'checkhash likes smtpctl encrypted password');
