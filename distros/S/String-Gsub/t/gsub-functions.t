
use strict;
use warnings;
use Test::More tests => 12;

use String::Gsub::Functions qw(gsub gsubx subs subsx);

&test_gsub;
&test_gsubx;
&test_subs;
&test_subsx;

sub test_gsub
{
	my $s = "abcabc";
	my $r = gsub($s, qr/(b)/, sub{uc $1});
	is($r, "aBcaBc", 'gsub result');
	isnt($r, $s, 'gsub returns new object');
	is($s, "abcabc", 'gsub doesnt change original');
}

sub test_gsubx
{
	my $s = "abcabc";
	my $r = gsubx($s, qr/(b)/, sub{uc $1});
	is($r, "aBcaBc", 'gsubx result');
	is($r, $s, 'gsubx returns itself');
	is($s, "aBcaBc", 'gsubx changes original');
}

sub test_subs
{
	my $s = "abcabc";
	my $r = subs($s, qr/(b)/, sub{uc $1});
	is($r, "aBcabc", 'sub result');
	isnt($r, $s, 'sub returns new object');
	is($s, "abcabc", 'sub doesnt change original');
}

sub test_subsx
{
	my $s = "abcabc";
	my $r = subsx($s, qr/(b)/, sub{uc $1});
	is($r, "aBcabc", 'subx result');
	is($r, $s, 'subx returns itself');
	is($s, "aBcabc", 'subx changes original');
}

