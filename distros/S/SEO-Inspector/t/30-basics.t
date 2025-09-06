use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempfile);
use FindBin;
use lib "$FindBin::Bin/../lib";

use SEO::Inspector;

# -------------------------------
# Fake plugin
# -------------------------------
{
	package SEO::Inspector::Plugin::FakeCheck;
	sub new { bless {}, shift }
	sub run { return { name => 'FakeCheck', status => 'ok', notes => 'plugin ran' }; }
}

# -------------------------------
# Object creation
# -------------------------------
my $inspector = SEO::Inspector->new;
isa_ok($inspector, 'SEO::Inspector', 'Object created');

# -------------------------------
# Plugin loading
# -------------------------------
my $plugins = $inspector->{plugins};
ok(exists $plugins->{fakecheck}, 'FakeCheck plugin loaded');

# -------------------------------
# check_html
# -------------------------------
my $html = '<html><head><title>Test</title><meta name="description" content="desc"></head><body><h1>Heading</h1></body></html>';
my $plugin_results = $inspector->check_html($html);

isa_ok($plugin_results, 'HASH', 'check_html returns a hashref');
ok(exists $plugin_results->{fakecheck}, 'FakeCheck plugin ran');
is($plugin_results->{fakecheck}->{status}, 'ok', 'FakeCheck status is ok');
like($plugin_results->{fakecheck}->{notes}, qr/plugin ran/, 'FakeCheck notes correct');

# -------------------------------
# run_all
# -------------------------------
my $builtin = $inspector->run_all($html);
isa_ok($builtin, 'HASH', 'run_all returns a hashref');
diag(Data::Dumper->new([$builtin])->Dump()) if($ENV{'TEST_VERBOSE'});
ok($builtin->{title}->{notes} eq 'title too short (4 chars)', 'Title is too short');
ok($builtin->{meta_description}->{status} eq 'ok', 'Meta description check passed');

done_testing();
