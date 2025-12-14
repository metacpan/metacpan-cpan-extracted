use strict;
use warnings;
use Test::More;
use Sys::Monitor::Lite;

subtest 'threshold evaluation helpers' => sub {
    my $data = {
        mem  => { used_pct => 75 },
        load => { '1min' => 1.2 },
    };

    my @metrics = Sys::Monitor::Lite::metrics_from_thresholds(
        ['mem.used_pct>80'],
        ['load.1min>2'],
    );
    is_deeply(\@metrics, [qw(load mem)], 'extracts metric roots from thresholds');

    my $ok = Sys::Monitor::Lite::evaluate_thresholds(
        $data,
        warn => ['mem.used_pct>80', 'load.1min>2'],
        crit => ['mem.used_pct>90'],
    );
    is($ok->{status}, 0, 'status OK when under thresholds');
    like($ok->{message}, qr/^OK - load\.1min=1\.2 \(>2\); mem\.used_pct=75 \(>80 >90\)$/, 'formats OK message with thresholds');

    my $warn = Sys::Monitor::Lite::evaluate_thresholds(
        $data,
        warn => ['mem.used_pct>=70'],
    );
    is($warn->{status}, 1, 'warn triggered');
    like($warn->{message}, qr/^WARN - mem\.used_pct=75 \(>=70\)$/, 'warn message shown');

    my $crit = Sys::Monitor::Lite::evaluate_thresholds(
        $data,
        crit => ['mem.used_pct>=75'],
    );
    is($crit->{status}, 2, 'crit triggered');
    like($crit->{message}, qr/^CRIT - mem\.used_pct=75 \(>=75\)$/, 'crit message shown');

    my $missing = Sys::Monitor::Lite::evaluate_thresholds(
        $data,
        crit => ['disk.0.used_pct>80'],
    );
    is($missing->{status}, 2, 'missing value treated as critical');
    like($missing->{message}, qr/CRIT - disk\.0\.used_pct=N\/A/, 'missing path noted');
};

# done_testing automatically counts subtests
done_testing();
