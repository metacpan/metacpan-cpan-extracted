use strict;
use warnings;
use Test::Needs 'Log::Dispatch';

use Mojo::Log;
use Mojo::Util 'dumper';
use Test::Mojo;
use Test::More;

my @levels = qw(debug info warn error fatal);

my @log;
my $debug_log = Log::Dispatch->new(outputs => [['Code', code => sub { my %p = @_; push @log, $p{message} }, min_level => 'debug']]);
my $log = Mojo::Log->with_roles('+AttachLogger')->new
  ->unsubscribe('message')->attach_logger($debug_log);

foreach my $level (@levels) {
  @log = ();
  
  $log->$level('test', 'message');
  
  ok +(grep { m/\[\Q$level\E\] test\nmessage$/m } @log), "$level log message"
    or diag dumper \@log;
}

my $info_log = Log::Dispatch->new(outputs => [['Code', code => sub { my %p = @_; push @log, $p{message} }, min_level => 'info']]);
$log->unsubscribe('message')->attach_logger($info_log);

foreach my $level (@levels) {
  @log = ();
  
  $log->$level('test', 'message');
  
  if ($level eq 'debug') {
    is_deeply \@log, [], 'no log message' or diag dumper \@log;
  } else {
    ok +(grep { m/\[\Q$level\E\] test\nmessage$/m } @log), "$level log message"
      or diag dumper \@log;
  }
}

done_testing;
