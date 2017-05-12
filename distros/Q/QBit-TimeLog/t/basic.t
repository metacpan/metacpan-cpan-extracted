use qbit;

use Test::More;

use QBit::TimeLog;

my $timelog = new_ok('QBit::TimeLog');

$timelog->start('Main prog');

$timelog->start('Action 1');
$_++ foreach (0..1000);
$timelog->finish();

$timelog->start('Action 2');
$timelog->start('Action 3');
$_++ foreach (0..5000);
$timelog->finish();
$timelog->finish();

$timelog->finish();

my $text = $timelog . '';

like( $text, qr/^[0-9.]+ sec: Main prog
    [0-9.]+ sec: Working
    [0-9.]+ sec: Action 1
    [0-9.]+ sec: Working
    [0-9.]+ sec: Action 2
        [0-9.]+ sec: Working
        [0-9.]+ sec: Action 3
        [0-9.]+ sec: Working
    [0-9.]+ sec: Working$/s, 'Checking timelog as text');

done_testing();
