# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl OpenSMTPD-Password.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('OpenSMTPD::Password', qw(newhash checkhash)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub randpassword {
	my $passwordlength = shift;

	return undef unless $passwordlength;

	my @chars = qw(. _ ! % ^ & $ - + = " ' : ; < > ~ ` ? / \ | 0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

	my $numchars = scalar(@chars);

	my @return;
	for (0 .. $passwordlength) {
		my $index = int(rand($numchars));
		push @return, $chars[$index];
	}
	my $fmt = '%s' x scalar(@return);

	my $password = sprintf("$fmt", @return);

	return $password if $password;
}

my $hash = newhash('password');

ok(defined($hash), 'newhash returns something');
ok(length($hash), 'and it wasn\'t empty');

ok(checkhash('password', $hash), 'checkhash likes our newhash');

open(SMTPCTL, "smtpctl encrypt password |") or die "Can't fork: $!";

my $newhash = <SMTPCTL>;

close(SMTPCTL);
chomp($newhash);

ok(checkhash('password', $newhash), 'checkhash likes smtpctl encrypted password');

my $randompassword = randpassword('20');
ok(defined($randompassword), 'randompassword defined');
ok(length($randompassword), 'and its not empty');

$hash = newhash($randompassword);

ok(defined($hash), 'newhash works with random password');
ok(length($hash), 'and its not empty');
ok(checkhash($randompassword, $hash), 'checkhash works with random password');
