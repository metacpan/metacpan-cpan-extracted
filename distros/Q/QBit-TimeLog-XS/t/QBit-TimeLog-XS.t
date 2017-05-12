use Test::More;

use qbit;

use QBit::TimeLog::XS;
use Test::LeakTrace;

my $timelog = new_ok('QBit::TimeLog::XS');

$timelog->start(gettext('Main prog'));

$timelog->start('Action 1');
$_++ foreach (0 .. 1000);
$timelog->finish();

$timelog->start('Action 2');
$timelog->start('Действие 3');
$_++ foreach (0 .. 5000);
$timelog->finish();
$timelog->finish();

$timelog->finish();

like(
    "$timelog", qr/^[0-9.]+ sec: Main prog
    [0-9.]+ sec: Working
    [0-9.]+ sec: Action 1
    [0-9.]+ sec: Working
    [0-9.]+ sec: Action 2
        [0-9.]+ sec: Working
        [0-9.]+ sec: Действие 3
        [0-9.]+ sec: Working
    [0-9.]+ sec: Working$/s, 'Checking timelog as text'
);

no_leaks_ok {
    my $timelog = QBit::TimeLog::XS->new();
    $timelog->start('Main prog');
    $timelog->start('Action 1');
    $timelog->finish();
    $timelog->start('Action 2');
    $timelog->start('Действие 3');
    $timelog->finish();
    $timelog->finish();
    $timelog->finish();
    my $text = $timelog->as_string();
}
'Checking memory leaks';

done_testing();
