BEGIN { $| = 1; print "1..1\n"; }

use utf8;
use Number::YAUID;

my %key_list;
my $lockfile = "./lock.key";

my $obj = Number::YAUID->new($lockfile, undef, node_id => 12);

for (1..1000)
{
	$key_list{$obj->get_key()} = 1;
}

undef $obj;
unlink($lockfile);

die if scalar(keys %key_list) < 1000;

print "ok 1\n";
