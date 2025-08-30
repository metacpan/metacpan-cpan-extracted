use strict;
use warnings;
use autodie qw(:all);

use File::Temp qw(tempfile tempdir);
use FindBin qw($Bin);
use IPC::Run3;
use JSON::MaybeXS;
use Test::Most;

use lib "$FindBin::Bin/../lib";

# -------------------------------
# Temporary plugin directory
# -------------------------------
my $plugin_dir = tempdir(CLEANUP => 1);
my $plugin_ns_dir = "$plugin_dir/SEO/Inspector/Plugin";
mkdir "$plugin_dir/SEO" or die $!;
mkdir "$plugin_dir/SEO/Inspector" or die $!;
mkdir "$plugin_ns_dir" or die $!;

# Create a fake plugin
my $plugin_file = "$plugin_ns_dir/FakeCLI.pm";
open my $fh, '>', $plugin_file or die $!;
print $fh <<'END';
package SEO::Inspector::Plugin::FakeCLI;
use strict;
use warnings;
sub new { bless {}, shift }
sub run { return { name => 'FakeCLI', status => 'ok', notes => 'plugin ran' }; }
sub name { 'FakeCLI' }
1;
END
close $fh;

# -------------------------------
# Temporary HTML file
# -------------------------------
my ($fh2, $html_file) = tempfile();
print $fh2 '<html><head><title>CLI Test</title><meta name="description" content="desc"></head><body><h1>Heading</h1></body></html>';
close $fh2;

# -------------------------------
# CLI script path
# -------------------------------
my $cli_script = "$FindBin::Bin/../bin/seo-inspect";

# -------------------------------
# Run CLI with --file option
# -------------------------------
my ($stdout, $stderr);
local $ENV{PERL5LIB} = "$plugin_dir:$FindBin::Bin/../lib:$ENV{PERL5LIB}";

# run3 [ $cli_script, '--file', $html_file ], undef, \$stdout, \$stderr;

# Build a perl command that always includes both real lib and test lib
my @perl = (
    $^X,
    '-I' . File::Spec->catdir($Bin, '..', 'lib'),  # project lib
    '-I' . File::Spec->catdir($Bin, 'lib'),        # test lib (FakeCLI.pm)
);

my $cmd = [
    @perl,
    $cli_script,
    '--file', $html_file,
];

run3 $cmd, undef, \$stdout, \$stderr;

diag($stderr) if(defined($stderr) && length($stderr));

ok(!$stderr, 'CLI did not produce errors');
like($stdout, qr/FakeCLI/, 'CLI output includes FakeCLI plugin');
like($stdout, qr/Title/, 'CLI output includes built-in check');
like($stdout, qr/Meta Description/, 'CLI output includes meta_description');

# -------------------------------
# Run CLI with --json option
# -------------------------------
$stdout = '';
$stderr = '';
run3 [ $cli_script, '--file', $html_file, '--json' ], undef, \$stdout, \$stderr;

ok(!$stderr, 'CLI JSON did not produce errors');

my $data;
# diag($stdout);
eval { $data = JSON::MaybeXS::decode_json($stdout) };
ok(!$@, 'CLI JSON output is valid JSON');
diag($@) if($@);

diag(Data::Dumper->new([$data])->Dump()) if($ENV{'TEST_VERBOSE'});
is($data->{'fakecli'}->{'name'}, 'FakeCLI', 'JSON includes plugin');
is($data->{'fakecli'}->{'notes'}, 'plugin ran', 'The plugin ran');
is($data->{'fakecli'}->{status}, 'ok', 'The plugin gave a sensible response');

done_testing();
