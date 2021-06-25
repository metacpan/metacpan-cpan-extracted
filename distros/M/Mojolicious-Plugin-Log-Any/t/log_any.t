use strict;
use warnings;
use Test::Needs {'Log::Any' => '1.00'};

use Log::Any::Test;
use Mojo::Log;
use Test::More;

{
  package My::Exception;
  use overload '""' => sub { scalar caller }, fallback => 1;
  sub new { bless {}, shift }
}

my @levels = qw(debug info warn error fatal);

my $log = Mojo::Log->with_roles('Mojo::Log::Role::AttachLogger')->new
  ->unsubscribe('message')->attach_logger('Log::Any', {category => 'Test::Category', prepend_level => 0, message_separator => ' '});

my $log_any = Log::Any->get_logger(category => 'Test::Category');
foreach my $level (@levels) {
  $log_any->clear;
  $log->$level('test', 'message');
  $log_any->category_contains_ok('Test::Category', qr/test message$/m, "$level log message");
  $log_any->clear;
  $log->$level(My::Exception->new);
  $log_any->category_does_not_contain_ok('Test::Category', qr/^Mojo::Log::Role::AttachLogger$/m, "$level log object not stringified");
}

done_testing;
