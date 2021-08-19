use strict;
use warnings;
use Test::Needs {'Log::Contextual' => '0.008001'};

use Mojolicious ();
use Mojo::Log;
use Mojo::Util 'dumper';
use Test::More;

my @log;
use Log::Contextual::SimpleLogger;
use Log::Contextual -logger => Log::Contextual::SimpleLogger->new({coderef => sub { push @log, @_ }, levels_upto => 'trace'});

my @levels = qw(debug info warn error fatal);
unshift @levels, 'trace' if eval { Mojolicious->VERSION('9.20'); 1 };

my $log = Mojo::Log->with_roles('Mojo::Log::Role::AttachLogger')->new
  ->unsubscribe('message')->attach_logger('Log::Contextual');
foreach my $level (@levels) {
  @log = ();
  $log->$level('test', 'message');
  ok +(grep { m/\[\Q$level\E\] test\nmessage$/m } @log), "$level log message"
    or diag dumper \@log;
}

done_testing;
