use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempfile);

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

# ============================================================
# Test: --write-high-watermark / --write-low-watermark CLI flags
# ============================================================
# The watermark flags must flow: bin/pagi-server CLI -> server_options
# -> server constructor. PAGITest::FakeServer (t/lib) stands in for
# PAGI::Server and echoes the options it received to STDOUT.

my $pagi_server = "$FindBin::Bin/../bin/pagi-server";
my $tlib        = "$FindBin::Bin/../t/lib";

my ($app_fh, $app_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
print $app_fh "sub {}\n";
close $app_fh;

sub run_cli {
    my (@flags) = @_;
    local $ENV{PAGI_ENV} = 'production';   # deterministic mode, no Lint wrap
    return `$^X -Ilib -I$tlib $pagi_server @flags -s PAGITest::FakeServer $app_file 2>&1`;
}

subtest 'watermark flags reach the server constructor' => sub {
    my $out = run_cli('--write-high-watermark', '262144', '--write-low-watermark', '65536');
    like($out, qr/FAKESERVER write_high_watermark=262144/,
        '--write-high-watermark passes through via server_options');
    like($out, qr/FAKESERVER write_low_watermark=65536/,
        '--write-low-watermark passes through via server_options');
};

subtest 'watermark options are absent without the flags' => sub {
    my $out = run_cli();
    like($out, qr/FAKESERVER write_high_watermark=unset/,
        'no --write-high-watermark means no option');
    like($out, qr/FAKESERVER write_low_watermark=unset/,
        'no --write-low-watermark means no option');
};

subtest 'bin/pagi-server documents the watermark flags' => sub {
    open my $fh, '<', $pagi_server or die "Cannot open $pagi_server: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    like($content, qr/--write-high-watermark/, 'bin/pagi-server mentions --write-high-watermark');
    like($content, qr/--write-low-watermark/,  'bin/pagi-server mentions --write-low-watermark');
};

done_testing;
