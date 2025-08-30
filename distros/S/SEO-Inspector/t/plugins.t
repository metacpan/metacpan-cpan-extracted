use strict;
use warnings;
use Test::Most;
use FindBin;
use lib "$FindBin::Bin/../lib";

use SEO::Inspector;

# -------------------------------
# Fake plugin for testing
# -------------------------------
{
	package SEO::Inspector::Plugin::TestPlugin;
	sub new { bless {}, shift }
	sub run { return { name => 'TestPlugin', status => 'ok', notes => 'ran' }; }
}

my $inspector = SEO::Inspector->new();

# Plugin should be loaded
my $plugins = $inspector->{plugins};
ok(exists $plugins->{testplugin}, 'TestPlugin loaded');

# Run check_html
my $html = '<html></html>';
my $results = $inspector->check_html($html);
isa_ok($results, 'HASH', 'check_html returns hashref');
ok(exists $results->{testplugin}, 'TestPlugin ran');
is($results->{testplugin}->{status}, 'ok', 'TestPlugin status ok');
like($results->{testplugin}->{notes}, qr/ran/, 'TestPlugin notes correct');

done_testing();
