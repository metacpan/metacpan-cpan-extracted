use strict;
use Net::NBName;

my $nb = Net::NBName->new;
my $param = shift;
my $host = shift;
if ($param =~ /^([\w-]+)\#(\w{1,2})$/) {
    my $name = $1;
    my $suffix = hex $2;

    my $nq;
    if (defined($host) && $host =~ /\d+\.\d+\.\d+\.\d+/) {
        printf "querying %s for %s<%02X>...\n", $host, $name, $suffix;
        $nq = $nb->name_query($host, $name, $suffix);
    } else {
        printf "broadcasting for %s<%02X>...\n", $name, $suffix;
        $nq = $nb->name_query(undef, $name, $suffix);
    }
    if ($nq) {
        print $nq->as_string;
    }
} else {
    die "expected: <name>#<suffix> [<host>]\n";
}
