# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
# $Id: test.pl,v 1.1.1.1 2002/02/26 00:11:27 hasant Exp $

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 10 };
BEGIN {$^W=1}
use Sub::Usage qw(:all parse_fqpn);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# parse_fqpn
my $package = 'My::Package';
my $method  = 'SomeMethod';
my $fqpn    = $package . '::' . $method;
my $sub = parse_fqpn $fqpn;
ok($sub, $method, "parse_fqpn($fqpn)");                     #2

my $pack;
($pack, $sub) = parse_fqpn $fqpn, 2;
ok($sub, $method, "parse_fqpn($fqpn, 2)");                  #3
ok($pack, $package, "parse_fqpn($fqpn, 2)");                #4

package My::Package;
use Sub::Usage qw/usage warn_hard warn_soft/;
sub SomeMethod {
	my($arg1, $arg2) = @_;
	usage 'ARG1 [, ARG2]'      unless $arg1;
	warn_hard('ARG1 [, ARG2]') if     $arg1 eq 'hard';
	warn_soft('ARG1 [, ARG2]') if     $arg1 eq 'soft';
	return 1;
}

package main;
my $usage_regex = qr/usage: SomeMethod\(ARG1 \[, ARG2\]\)/;
eval {My::Package::SomeMethod()};
#My::Package::SomeMethod();
ok($@, $usage_regex,                                        #5
	"Calling SomeMethod without arg, expecting usage");

my $warn;
local $SIG{__WARN__} = sub { $warn = shift };
{
# warn_hard should go through even if warning is disabled
local $^W = 0;
My::Package::SomeMethod('hard');
ok($warn, $usage_regex,                                     #6
	"Calling SomeMethod arg1=hard, expecting warn_hard");
}

$warn = '';
{
# warn_soft never goes through if warning is disabled
local $^W = 0;
My::Package::SomeMethod('soft');
ok($warn, '',                                               #7
	"Calling SomeMethod arg1=soft, W=0, no warning should be issued");
}

# warn_soft should go through now
My::Package::SomeMethod('soft');
ok($warn, $usage_regex,                                     #8
	"Calling SomeMethod arg1=soft, expecting warn_soft");

ok(1, My::Package::SomeMethod('ok'));                       #9

package Sample::Module::OO;
use Sub::Usage;
# die without reason
sub method { usage undef, '$obj' }

package main;

$usage_regex = qr/usage: \$obj->method\(\)/;
eval {Sample::Module::OO->method()};
ok($@, $usage_regex,                                        #10
	"Calling Sample::Module::OO->method() expecting usage");

# TODO
#eval {usage()};
#ok($@, qr/Sub::Usage::usage\(\) must be called/);           #11
#ok(0);           #11
