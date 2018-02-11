use strict;
use warnings;
use Test::Needs {'Log::Any' => '1.00'};

use Log::Any::Test;
use Mojo::Log;
use Test::More;

my @levels = qw(debug info warn error fatal);

my $log = Mojo::Log->with_roles('+AttachLogger')->new
  ->unsubscribe('message')->attach_logger('Log::Any', 'Test::Category');

my $log_any = Log::Any->get_logger(category => 'Test::Category');
foreach my $level (@levels) {
  $log_any->clear;
  
  $log->$level('test', 'message');
  
  $log_any->category_contains_ok('Test::Category', qr/\[\Q$level\E\] test\nmessage$/m, "$level log message");
}

done_testing;
