use Mojo::Base -strict;
use Test::More tests => 19;
use MojoX::Log::Log4perl;

ok my $logger = MojoX::Log::Log4perl->new({
	'log4perl.rootLogger' => 'DEBUG, TEST',
	'log4perl.appender.TEST' => 'Log::Log4perl::Appender::TestBuffer',
        'log4perl.appender.TEST.layout' => 'SimpleLayout',
}), 'able to create test log object';

is_deeply $logger->history, [], 'log history starts empty';
is $logger->max_history_size, 10, 'log max history size defaults to 10';
$logger->max_history_size(3);
is $logger->max_history_size, 3, 'able to set max history size';

ok my $appender = Log::Log4perl->appenders()->{TEST}, 'able to fetch test appender';

ok $logger->error('This is an error message!'), 'logged an error message';

is $appender->buffer, "ERROR - This is an error message!\n" => 'got the proper message back';

my $history = $logger->history;
is scalar @$history, 1 => 'history now has 1 item';
is scalar @{$history->[0]}, 3, 'each history item has 3 elements';
like $history->[0][0], qr/^\d+$/ => 'first element of history item looks like a timestamp';
is $history->[0][1], 'error' => 'log level properly set in history';
is $history->[0][2], 'This is an error message!' => 'log message properly set in history';

ok $logger->fatal('oh noes...'), 'logged a fatal message';
ok $logger->warn('danger! danger!'), 'logged a warning';
ok $logger->warn('yet another warning message'), 'logged another warning';

my $buff = <<'EOLOG';
ERROR - This is an error message!
FATAL - oh noes...
WARN - danger! danger!
WARN - yet another warning message
EOLOG
is $appender->buffer, $buff => 'all 4 test messages were properly logged';

is scalar @$history, 3 => 'history now has 3 items';
is $history->[0][2], 'oh noes...' => 'log history rotates properly';
is $history->[-1][2], 'yet another warning message' => 'last message properly set in history';

