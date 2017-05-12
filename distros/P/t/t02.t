#!/usr/bin/perl
use strict; use warnings;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
binmode STDIN, ':encoding(UTF-8)';

# vim=:SetNumberAndWidth

## Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl t01.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#########################


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


use Test::More; #tests => 5;
use P;

my $struct= {a => {
									array=>[1,2,'c'=>{hash1=>{1=>'one'}},3,4,5],
									ahash=>{a=>1, b=>2, c=>'three',d=>undef},
								}};

my $ans = q({a=>{array=>[1, 2, 'c', {…}, 3, 4, 5], ahash=>{a=>1, b=>2, c=>"three", d=>∄}}});

my $default_out = P "%s", $struct;

cmp_ok($default_out, 'eq', $ans, "check standard output options");
#P "%s", $default_out;

{	package one;
	use Test::More; #tests => 5;
	use P (':depth=5');
	my $out = P "%s", $struct;
	#P "%s", $out;
	like ($out, qr/array.*one.*ahash.*three.*/, 'check increase depth');
}

{	package two;
	use Test::More; #tests => 5;
	use P qw[:undef="(undef)"];
	my $out = P "%s", $struct;
	#P "%s", $out;
	like ($out,  qr{.*d=>.*\(undef\).*}, "Check for redef of undef sign");
	like ($out,  qr{.*d=>\(undef\).*}, "Check for Dquote removal");
	unlike($out, qr/array.*one.*ahash.*three.*/, 'check depth is default');

}

done_testing();
