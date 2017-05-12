use Net::NBName;
use Net::Netmask;

$mask = shift or die "expected: <subnet>\n";

$nb = Net::NBName->new;
$subnet = Net::Netmask->new2($mask);
for $ip ($subnet->enumerate) {
    print "$ip ";
    $ns = $nb->node_status($ip);
    if ($ns) {
        for my $rr ($ns->names) {
            if ($rr->suffix == 0 && $rr->G eq "GROUP") {
                $domain = $rr->name;
            }
            if ($rr->suffix == 3 && $rr->G eq "UNIQUE") {
                $user = $rr->name;
            }
            if ($rr->suffix == 0 && $rr->G eq "UNIQUE") {
                $machine = $rr->name unless $rr->name =~ /^IS~/;
            }
        }
        $mac_address = $ns->mac_address;
        print "$mac_address $domain\\$machine $user";
    }
    print "\n";
}
