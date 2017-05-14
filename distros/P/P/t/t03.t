#!/usr/bin/perl
use strict; use warnings;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
# vim=:SetNumberAndWidth

## Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl t03.t'


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


use Test::More;
use P qw(:default :depth=5);

my $struct= {a => {
									array=>[1,2,'c'=>{hash1=>{1=>'one'}},3,4,5],
									ahash=>{a=>1, b=>2, c=>'three',d=>undef},
								}};

my $ans = q({a=>{array=>[1, 2, 'c', {…}, 3, 4, 5], ahash=>{a=>1, b=>2, c=>"three", d=>∄}}});

my @tstmsg = ("%s", $struct);

my $out = P @tstmsg;
#P "%s", $out;
like ($out, qr/array.*one.*ahash.*three.*/, 'check increase depth');

{	package one;
	use Test::More;
	use P (':depth=3');
	my $out = P @tstmsg;
	cmp_ok($out, 'eq', $ans, "check standard depth 3 as pkg-op");
}

{	package two;
	use Test::More;
	use P;
	my $out = P @tstmsg;
	like ($out, qr/array.*one.*ahash.*three.*/, 'check increased depth in new pkg (default standard)');
}

$out = P @tstmsg;
#P "%s", $out;
like ($out, qr/array.*one.*ahash.*three.*/, 'check depth in main again');



my $p=P::->ops({depth=>3});
$out = $p->P(@tstmsg);
cmp_ok($out, 'eq', $ans, "check depth 3 as OO-op");

$out = P @tstmsg;
#P "%s", $out;
like ($out, qr/array.*one.*ahash.*three.*/, 'check one last in main again');



done_testing();
