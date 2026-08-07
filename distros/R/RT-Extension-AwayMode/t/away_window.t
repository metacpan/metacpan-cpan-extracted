use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use RT::Extension::AwayMode;

my $class = 'RT::Extension::AwayMode';
my $today = '2026-08-04';

ok( !$class->IsAwayForPrefs( undef, $today ), 'no prefs at all => not away' );

ok( !$class->IsAwayForPrefs( {}, $today ), 'empty prefs => not away' );

ok( !$class->IsAwayForPrefs( { Enabled => 0 }, $today ),
    'disabled, no dates => not away' );

ok(
    !$class->IsAwayForPrefs(
        { Enabled => 0, StartDate => '2026-01-01', EndDate => '2026-12-31' },
        $today
    ),
    'disabled, dates cover today => still not away'
);

ok(
    $class->IsAwayForPrefs( { Enabled => 1 }, $today ),
    'enabled, no dates => away indefinitely'
);

ok(
    !$class->IsAwayForPrefs(
        { Enabled => 1, StartDate => '2026-09-01' }, $today
    ),
    'enabled, start-only in the future => not yet away'
);

ok(
    $class->IsAwayForPrefs(
        { Enabled => 1, StartDate => '2026-08-04' }, $today
    ),
    'enabled, start-only equal to today => away (inclusive)'
);

ok(
    $class->IsAwayForPrefs(
        { Enabled => 1, StartDate => '2026-01-01' }, $today
    ),
    'enabled, start-only in the past => away'
);

ok(
    !$class->IsAwayForPrefs(
        { Enabled => 1, EndDate => '2026-08-03' }, $today
    ),
    'enabled, end-only in the past => no longer away'
);

ok(
    $class->IsAwayForPrefs( { Enabled => 1, EndDate => '2026-08-04' }, $today ),
    'enabled, end-only equal to today => away (inclusive)'
);

ok(
    $class->IsAwayForPrefs( { Enabled => 1, EndDate => '2026-09-01' }, $today ),
    'enabled, end-only in the future => away'
);

ok(
    $class->IsAwayForPrefs(
        { Enabled => 1, StartDate => '2026-08-01', EndDate => '2026-08-10' },
        $today
    ),
    'enabled, today strictly inside range => away'
);

ok(
    $class->IsAwayForPrefs(
        { Enabled => 1, StartDate => '2026-08-04', EndDate => '2026-08-04' },
        $today
    ),
    'enabled, single-day range equal to today => away'
);

ok(
    !$class->IsAwayForPrefs(
        { Enabled => 1, StartDate => '2026-08-05', EndDate => '2026-08-10' },
        $today
    ),
    'enabled, range entirely in the future => not yet away'
);

ok(
    !$class->IsAwayForPrefs(
        { Enabled => 1, StartDate => '2026-07-01', EndDate => '2026-08-03' },
        $today
    ),
    'enabled, range entirely in the past => no longer away'
);

done_testing();
