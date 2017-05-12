
use strict;
use warnings;
use Test::More tests => 17;

use String::Gsub qw(gstr);

&test_gsub;
&test_gsubx;
&test_subs;
&test_subsx;

&test_matcharg;
&test_matchvars;
&test_strregexp;

sub test_gsub
{
	my $s = gstr("abcabc");
	my $r = $s->gsub(qr/(b)/, '(\1)');
	is($r, "a(b)ca(b)c", 'gsub result');
	isnt($r, $s, 'gsub returns new object');
	is($s, "abcabc", 'gsub doesnt change original');
}

sub test_gsubx
{
	my $s = gstr("abcabc");
	my $r = $s->gsubx(qr/(b)/, '(\1)');
	is($r, "a(b)ca(b)c", 'gsubx result');
	is($r, $s, 'gsubx returns itself');
	is($s, "a(b)ca(b)c", 'gsubx changes original');
}

sub test_subs
{
	my $s = gstr("abcabc");
	my $r = $s->sub(qr/(b)/, '(\1)');
	is($r, "a(b)cabc", 'sub result');
	isnt($r, $s, 'sub returns new object');
	is($s, "abcabc", 'sub doesnt change original');
}

sub test_subsx
{
	my $s = gstr("abcabc");
	my $r = $s->subx(qr/(b)/, '(\1)');
	is($r, "a(b)cabc", 'subx result');
	is($r, $s, 'subx returns itself');
	is($s, "a(b)cabc", 'subx changes original');
}

sub test_matcharg
{
	my $s = gstr("abcabc");
	my $r = $s->gsub(qr/(b)/, sub{uc shift});
	is($r, "aBcaBc", 'argument of match callback');
}

sub test_matchvars
{
	my $s = gstr("abcabc");
	my $r = $s->gsub(qr/(b)/, '(\&)');
	is($r, "a(b)ca(b)c", 'gsub match value');
	
	$s = gstr("abcabc");
	$r = $s->gsub(qr/(b)/, q/(\`)/);
	is($r, "a(a)ca(abca)c", 'gsub prematch value');
	
	$s = gstr("abcabc");
	$r = $s->gsub(qr/(b)/, q/(\')/);
	is($r, "a(cabc)ca(c)c", 'gsub postmatch value');
}

sub test_strregexp
{
	my $s = gstr("abc.abc.");
	my $r = $s->gsub('.', '(\&)');
	is($r, "abc(.)abc(.)", ". matches just `.'");
}

