use Net::NBName;

my $nb = Net::NBName->new;
my $host = shift;
if (defined($host) && $host =~ /\d+\.\d+\.\d+\.\d+/) {
    my $ns = $nb->node_status($host);
    if ($ns) {
        print $ns->as_string;
    } else {
        print "no response\n";
    }
} else {
    die "expected: <host>\n";
}
