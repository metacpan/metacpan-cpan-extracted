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
# Prepare temporary HTML file
# -------------------------------
my ($fh, $filename) = tempfile();
print $fh '<html><head><title>URL Test</title></head><body></body></html>';
close $fh;

# -------------------------------
# Object
# -------------------------------
my $inspector = SEO::Inspector->new;

# -------------------------------
# check_url with local file
# -------------------------------
# We simulate URL fetching by overriding _fetch_html
{
    no warnings 'redefine';
    *SEO::Inspector::_fetch_html = sub { local $_ = $filename; open my $fh, '<', $_ or die "Can't open $_"; local $/; <$fh>; };
}

my $results = $inspector->check_url('http://example.com');

isa_ok($results, 'HASH', 'check_url returns hashref');
ok(exists $results->{fakecheck}, 'Plugin ran in check_url');
ok(exists $results->{title}, 'Built-in check ran in check_url');

done_testing();
