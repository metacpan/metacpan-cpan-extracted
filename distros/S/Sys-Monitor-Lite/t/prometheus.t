use strict;
use warnings;
use Test::More;
use Sys::Monitor::Lite;

my $data = {
    timestamp => 1234567890,
    cpu       => { usagePct => { total => 50 } },
    load      => { '1min' => 0.12 },
    disk      => [
        {
            mount        => '/',
            filesystem   => '/dev/sda1',
            total_bytes  => 1024,
            used_bytes   => 512,
            read_only    => 0,
        },
    ],
    values => [1, 2],
    status => 'ok',
};

my $text = Sys::Monitor::Lite::to_prometheus(
    $data,
    prefix    => 'sysmon_',
    labels    => { role => 'test' },
    timestamp => 1,
);

like($text, qr/^# TYPE sysmon_cpu_usage_pct_total gauge$/m, 'includes TYPE line');
like($text, qr/^sysmon_cpu_usage_pct_total\{role="test"\} 50 1234567890$/m, 'cpu metric rendered with prefix and timestamp');
like($text, qr/^sysmon_load_1min\{role="test"\} 0.12 1234567890$/m, 'load average rendered');
like(
    $text,
    qr/^sysmon_disk_total_bytes\{filesystem="\/dev\/sda1",index="0",mount="\/",role="test"\} 1024 1234567890$/m,
    'disk metric with labels'
);
like($text, qr/^sysmon_disk_read_only\{filesystem="\/dev\/sda1",index="0",mount="\/",role="test"\} 0 1234567890$/m, 'boolean fields become gauges');
like($text, qr/^sysmon_values\{index="1",role="test"\} 2 1234567890$/m, 'array index label added');
unlike($text, qr/status\s+ok/, 'string-only values are not emitted as metrics');

my $custom = Sys::Monitor::Lite::to_prometheus({ value => 1 }, prefix => 'Test-Prefix');
like($custom, qr/^test_prefix_value 1$/m, 'prefix sanitized to snake_case');

my $labels = Sys::Monitor::Lite::to_prometheus({ metric => 2 }, labels => { 'Node-Name' => "app-01\n" });
like($labels, qr/\{node_name="app-01\\n"\}/, 'labels are snake_cased and escaped');

done_testing();
