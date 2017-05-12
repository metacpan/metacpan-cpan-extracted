use Test::More tests => 27;

# class tests
can_ok('MojoX::Log::Log4perl', qw(new log));
can_ok('MojoX::Log::Log4perl', qw(trace debug info warn error fatal));

can_ok('MojoX::Log::Log4perl', qw(logwarn logdie error_warn error_die
                                  logcarp logcluck logcroak logconfess)
      );
can_ok('MojoX::Log::Log4perl', qw(is_trace is_debug is_info is_warn
                                  is_error is_fatal)
      );
can_ok('MojoX::Log::Log4perl', qw(level is_level));

can_ok('MojoX::Log::Log4perl', qw(history max_history_size));

use MojoX::Log::Log4perl;
my $logger = MojoX::Log::Log4perl->new;
isa_ok($logger, 'MojoX::Log::Log4perl');

ok (!$logger->is_trace, 'default mode is debug (is_trace check)');
ok ($logger->is_debug, 'default mode is debug (is_debug check)');
ok ($logger->is_info, 'default mode is debug (is_info check)');
ok ($logger->is_warn, 'default mode is debug (is_warn check)');
ok ($logger->is_error, 'default mode is debug (is_error check)');
ok ($logger->is_fatal, 'default mode is debug (is_fatal check)');

is ($logger->level, 'DEBUG', 'level() should be DEBUG');
$logger->level('warn');
is ($logger->level, 'WARN', 'level("warn") should change log level');

$logger->level('OFF');
foreach (qw(fatal error warn info debug trace)) {
    ok (!$logger->is_level($_), "shouldn't be level $_");
    $logger->level($_);
    ok ($logger->is_level($_), "testing level '$_'");
}
