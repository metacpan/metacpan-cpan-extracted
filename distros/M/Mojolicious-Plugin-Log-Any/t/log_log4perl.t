use strict;
use warnings;
use Test::Needs 'Log::Log4perl';

use Mojolicious ();
use Mojo::Log;
use Test::More;

my @levels = qw(debug info warn error fatal);
unshift @levels, 'trace' if eval { Mojolicious->VERSION('9.20'); 1 };

Log::Log4perl->init({
  'log4perl.logger.Test::Log::Debug' => 'TRACE, debug_log',
  'log4perl.logger.Test::Log::Info' => 'INFO, info_log',
  'log4perl.appender.debug_log' => 'Log::Log4perl::Appender::TestBuffer',
  'log4perl.appender.debug_log.name' => 'debug_log',
  'log4perl.appender.debug_log.layout' => 'Log::Log4perl::Layout::SimpleLayout',
  'log4perl.appender.info_log' => 'Log::Log4perl::Appender::TestBuffer',
  'log4perl.appender.info_log.name' => 'info_log',
  'log4perl.appender.info_log.layout' => 'Log::Log4perl::Layout::SimpleLayout',
});

my $log = Mojo::Log->with_roles('Mojo::Log::Role::AttachLogger')->new
  ->unsubscribe('message')->attach_logger('Log::Log4perl', 'Test::Log::Debug');

my $debug_log = Log::Log4perl::Appender::TestBuffer->by_name('debug_log');
foreach my $level (@levels) {
  $debug_log->clear;
  $log->$level('test', 'message');
  like $debug_log->buffer, qr/\[\Q$level\E\] test\nmessage$/m, "$level log message"
    or diag $debug_log->buffer;
}

$log->unsubscribe('message')->attach_logger('Log::Log4perl', {category => 'Test::Log::Info', prepend_level => 0});

my $info_log = Log::Log4perl::Appender::TestBuffer->by_name('info_log');
foreach my $level (@levels) {
  $info_log->clear;
  $log->$level('test', 'message');
  
  if ($level eq 'debug' or $level eq 'trace') {
    is $info_log->buffer, '', 'no log message' or diag $info_log->buffer;
  } else {
    like $info_log->buffer, qr/(?<!\[\Q$level\E\] )test\nmessage$/m, "$level log message (no prepend)"
      or diag $info_log->buffer;
  }
}

done_testing;
