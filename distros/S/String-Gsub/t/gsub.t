
use strict;
use warnings;
use Test::More tests => 16;

use String::Gsub qw(gstr);

&test_gsub;
&test_gsubx;
&test_subs;
&test_subsx;

sub test_gsub
{
	my $s = gstr("abcabc");
	my $r = $s->gsub(qr/(b)/, sub{uc $1});
	is($r, "aBcaBc", 'gsub result');
	isnt($r, $s, 'gsub returns new object');
	isa_ok($r, 'String::Gsub', 'gsub returns a object which isa String::Gsub');
	is($s->gsub(qr/(a)/, sub{uc $1})->gsub(qr/(c)/,sub{uc $1}), "AbCAbC", "gsub twice");
	is($s, "abcabc", 'gsub doesnt change original');
}

sub test_gsubx
{
	my $s = gstr("abcabc");
	my $r = $s->gsubx(qr/(b)/, sub{uc $1});
	is($r, "aBcaBc", 'gsubx result');
	is($r, $s, 'gsubx returns itself');
	is($s, "aBcaBc", 'gsubx changes original');
}

sub test_subs
{
	my $s = gstr("abcabc");
	my $r = $s->sub(qr/(b)/, sub{uc $1});
	is($r, "aBcabc", 'sub result');
	isnt($r, $s, 'sub returns new object');
	isa_ok($r, 'String::Gsub', 'sub returns a object which isa String::Gsub');
	is($s->sub(qr/(a)/, sub{uc $1})->sub(qr/(c)/,sub{uc $1}), "AbCabc", "sub twice");
	is($s, "abcabc", 'sub doesnt change original');
}

sub test_subsx
{
	my $s = gstr("abcabc");
	my $r = $s->subx(qr/(b)/, sub{uc $1});
	is($r, "aBcabc", 'subx result');
	is($r, $s, 'subx returns itself');
	is($s, "aBcabc", 'subx changes original');
}

