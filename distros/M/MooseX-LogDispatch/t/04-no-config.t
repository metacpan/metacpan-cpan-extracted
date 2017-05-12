use strict;
use warnings;
use Test::More tests => 3;
my $log;

{ package Logger;
  use base 'Log::Dispatch::Null';
  sub log_message {
      my $self = shift;
      my %args = @_;
      $log = $args{message};
  };
}

{ package Class;
  use Moose;
  with 'MooseX::LogDispatch::Levels';

  sub msg { $_[0]->debug('hello') }
}

my $logger = Log::Dispatch->new;
isa_ok $logger, 'Log::Dispatch';
$logger->add(Logger->new( min_level => 'debug', name => 'foo' ));

my $class = Class->new( logger => $logger );
isa_ok $class, 'Class';

$class->msg;

is $log, 'hello', 'logging worked';

