use strict;
use warnings;
use Test::More;

use lib 'lib';
use Physics::Electrodeposition::CopperPlating;

my $sim = Physics::Electrodeposition::CopperPlating->new(
    wafer_diameter_mm => 300,
    pattern_type      => 'redistribution_lines',
    convection        => 'high',
    voltage_v         => 0.95,
    target_thickness_um => 10,
);

my $result = $sim->simulate;

is($result->{wafer_diameter_mm}, 300, 'uses requested wafer size');
is($result->{pattern_type}, 'redistribution_lines', 'uses requested pattern type');
ok($result->{expected_current_a} > 0, 'expected current is positive');
ok($result->{growth_rate_um_min} > 0, 'growth rate is positive');
ok($result->{estimated_uniformity_percent} >= 88, 'uniformity stays in expected lower bound');
ok($result->{estimated_uniformity_percent} <= 99.2, 'uniformity stays in expected upper bound');
ok($result->{estimated_plating_time_min} > 0, 'plating time is positive');

my $studs = $sim->simulate(pattern_type => 'studs');
ok(
    $studs->{estimated_uniformity_percent} > $result->{estimated_uniformity_percent},
    'stud plating is predicted to be more uniform than redistribution lines',
);

my $notes = $sim->process_notes(pattern_type => 'studs', wafer_diameter_mm => 200);
ok(@{$notes} >= 6, 'returns process notes');
like(join(' ', @{$notes}), qr/Faraday-law/i, 'notes mention growth-rate assumption');

done_testing();
