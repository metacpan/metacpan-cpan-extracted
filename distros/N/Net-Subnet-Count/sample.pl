use Net::Subnet::Count;
use IP::Address;

my $counter 
    = new Net::Subnet::Count (
			      'test-00' => new IP::Address("10.0.0.0/9"),
			      'test-01' => new IP::Address("10.128.0.0/9"),
			      'test-02' => new IP::Address("161.196.0.0/16"),
			      );

$counter->add('test-03', new IP::Address("200.44.0.0/18"));
$counter->add('test-03', new IP::Address("200.44.192.0/18")); 

$counter->cache(2);

my @list;

foreach my $ip (qw(10.120.0.1 161.196.0.1 10.0.0.5 10.0.0.3 10.0.0.1 
		   10.128.9.1 10.0.0.3 161.196.66.2 161.196.66.2 161.196.66.5
		   200.44.32.10 200.44.200.10))
{
    my $ipa = new IP::Address($ip);
    push @list, $ipa;
    $counter->count($ipa);
}

$counter->count(@list);

my $r_count = $counter->result;

foreach my $subnet (sort keys %{$r_count}) {
    print "Group $subnet has ", $r_count->{$subnet},
    " matches\n";
}
