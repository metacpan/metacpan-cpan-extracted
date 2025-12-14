use strict;
use warnings;
use Test::More;
use JSON::PP;
use File::Spec;

subtest 'cli integration' => sub {
    my $perl   = $^X;
    my $script = File::Spec->catfile('script', 'sys-monitor-lite');

    # --- JSON (system) ---
    my $output = qx{$perl $script --once --collect system --output json};
    ok($? == 0, 'cli exited successfully (json)');

    my $decoded = eval { JSON::PP->new->decode($output) };
    ok(!$@, 'cli output is valid JSON');
    isa_ok($decoded->{system}, 'HASH', 'cli returned system data');

    # --- YAML (system) ---
    my $yaml_output = qx{$perl $script --once --collect system --output yaml};
    ok($? == 0, 'cli exited successfully for YAML');
    like($yaml_output, qr/^system:/m, 'cli YAML output contains system key');

    # --- --top / process ---
    my $proc_output = qx{$perl $script --once --top cpu=3 --output json};
    ok($? == 0, 'cli exited successfully for --top');

    my $proc_decoded = eval { JSON::PP->new->decode($proc_output) };
    ok(!$@, 'cli --top output is valid JSON');
    isa_ok($proc_decoded->{process}, 'ARRAY', 'process metric returned');

    # --- Prometheus (IMPORTANT: keep as one line so the shell doesn't split it) ---
    my $prom_cmd = qq{$perl $script --once --collect system --output prometheus --prefix sysmon_ --labels role=tester};
    my $prom_output = qx{$prom_cmd};
    ok($? == 0, 'cli exited successfully for Prometheus');

    if ($^O eq 'linux') {
        like(
            $prom_output,
            qr/^# TYPE sysmon_[a-z_][a-z0-9_]* gauge$/m,
            'Prometheus output includes TYPE line'
        );

        like(
            $prom_output,
            qr/^sysmon_[a-z_][a-z0-9_]*(?:\{[^}]*\})?
               [-+]?(?:\d+(?:\.\d+)?|\.\d+)
               (?:[eE][-+]?\d+)?(?: \d+)?$/mx,
            'Prometheus output includes prefixed sample line'
        );

        like(
            $prom_output,
            qr/^\w+\{[^}]*role="tester"[^}]*\} /m,
            'Prometheus output includes fixed label role="tester"'
        );
    }
    else {
        ok(
            $prom_output =~ /^\s*\z/,
            'Prometheus output may be empty on non-Linux when collecting only system'
        );
    }
};

done_testing();

