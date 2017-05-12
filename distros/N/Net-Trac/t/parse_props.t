use Test::More tests => 3;

my $props = <<'EOF';

<strong>owner</strong> changed from <em>somebody</em> to <em>jrv</em>.</li>
    <li><strong>status</strong> changed from <em>new</em> to <em>assigned</em>.</li>
    <li><strong>type</strong> changed from <em>defect</em> to <em>enhancement</em>.</li>

EOF

use_ok('Net::Trac::TicketHistoryEntry');

my $e = Net::Trac::TicketHistoryEntry->new();
my $prop_data = $e->_parse_props($props);
is(scalar keys %$prop_data, 3, "Four properties");
my @keys = sort (qw(owner status type));
is_deeply([sort keys %$prop_data], [sort @keys]);

