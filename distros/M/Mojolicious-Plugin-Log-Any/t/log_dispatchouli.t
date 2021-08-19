use strict;
use warnings;
use Test::Needs 'Log::Dispatchouli';

use Mojolicious ();
use Mojo::Log;
use Mojo::Util 'dumper';
use Test::More;

my @levels = qw(debug info warn error fatal);
unshift @levels, 'trace' if eval { Mojolicious->VERSION('9.20'); 1 };

my $debug_log = Log::Dispatchouli->new_tester({debug => 1});
my $log = Mojo::Log->with_roles('Mojo::Log::Role::AttachLogger')->new
  ->unsubscribe('message')->attach_logger($debug_log);

foreach my $level (@levels) {
  $debug_log->clear_events;
  $log->$level('test', 'message');
  ok +(grep { $_->{message} =~ m/\[\Q$level\E\] test\nmessage$/m } @{$debug_log->events}), "$level log message"
    or diag dumper $debug_log->events;
}

my $muted_log = Log::Dispatchouli->new_tester;
$muted_log->set_muted(1);
$log->unsubscribe('message')->attach_logger($muted_log, {prepend_level => 0});

foreach my $level (@levels) {
  $muted_log->clear_events;
  $log->$level('test', 'message');
  
  if ($level eq 'fatal') {
    ok +(grep { $_->{message} =~ m/^test\nmessage$/m } @{$muted_log->events}), "$level log message (no prepend)"
      or diag dumper $muted_log->events;
  } else {
    is_deeply $muted_log->events, [], 'no log message' or diag dumper $muted_log->events;
  }
}

done_testing;
