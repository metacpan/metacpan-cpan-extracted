use strict;
use warnings;

use Test::More tests => 12;
use Protocol::Memcached;
use POSIX qw(floor);

my $mc = Protocol::Memcached->new;
ok(my $map = $mc->build_ketama_map(
	'127.0.0.1:11211' => 600,
	'192.168.1.75:11211' => 900,
	'192.168.1.42:11211' => 500,
), 'build map');
#note explain $map;
{ my %ip;
{ my %seen;
for my $idx (0..20000) {
	my $k = "had $idx some string $idx";
	my $point = $mc->ketama_find_point($k);
	$seen{$point->{ip}}++;
	$ip{$k} = $point->{ip};
}
is_deeply([sort keys %seen], [sort qw(192.168.1.75:11211 127.0.0.1:11211 192.168.1.42:11211)], 'have the right keys');
}
{
$mc->build_ketama_map(
	'127.0.0.1:11211' => 600,
	'192.168.1.42:11211' => 500,
);
my %seen;
my $matched = 0;
for my $idx (0..20000) {
	my $k = "had $idx some string $idx";
	my $point = $mc->ketama_find_point($k);
	$seen{$point->{ip}}++;
	++$matched if $ip{$k} eq $point->{ip};
}
is_deeply([sort keys %seen], [sort qw(127.0.0.1:11211 192.168.1.42:11211)], 'have the right keys');
cmp_ok($matched, '>', 8000, "matched $matched out of 20000");
}
{
$mc->build_ketama_map(
	'192.168.1.42:11211' => 500,
);
my %seen;
my $matched = 0;
for my $idx (0..20000) {
	my $k = "had $idx some string $idx";
	my $point = $mc->ketama_find_point($k);
	$seen{$point->{ip}}++;
	++$matched if $ip{$k} eq $point->{ip};
}
is_deeply([sort keys %seen], [sort qw(192.168.1.42:11211)], 'have the right keys');
cmp_ok($matched, '>', 3200, "matched $matched out of 20000");
}
}

# larger map
{
my @map = map { join('.', floor(rand(255)), floor(rand(255)),floor(rand(255)),floor(rand(255))) . ':' . 11211 => floor(rand(1000)) } 0..1000;
ok(my $map = $mc->build_ketama_map(
	@map
), 'build map');
my %seen;
my %ip;
for my $idx (0..20000) {
	my $k = "had $idx some string $idx";
	my $point = $mc->ketama_find_point($k);
	$seen{$point->{ip}}++;
	$ip{$k} = $point->{ip};
#	++$matched if $ip{$k} eq $point->{ip};
}
cmp_ok(scalar keys %seen, '>', 800, 'have ' . scalar(keys %seen) . ' keys');
for my $idx (reverse grep $_ % 2 == 0, 0..$#map) {
	splice @map, $idx, 2 if $map[$idx] =~ /^\d{1,2}\./;
}
cmp_ok(@map / 2, '<', 800, 'map is ' . (@map/2));
cmp_ok(@map / 2, '>', 400, 'map is ' . (@map/2));
ok($map = $mc->build_ketama_map(
	@map
), 'build map');
%seen = ();
for my $idx (0..20000) {
	my $k = "had $idx some string $idx";
	my $point = $mc->ketama_find_point($k);
	$seen{$point->{ip}}++;
	$ip{$k} = $point->{ip};
#	++$matched if $ip{$k} eq $point->{ip};
}
cmp_ok(scalar keys %seen, '>', 500, 'have ' . scalar(keys %seen) . ' keys');
#is_deeply([sort keys %seen], [sort qw(192.168.1.42:11211)], 'have the right keys');
#cmp_ok($matched, '>', 3200, "matched $matched out of 20000");

}
