use strict;
use warnings;
use Test::More;
use Path::Extended::Entity;

subtest 'no_logger' => sub {
  my $entity = Path::Extended::Entity->new;

  ok !$entity->{logger}, 'no logger by default';
};

subtest 'custom_logger' => sub {
  my $entity = Path::Extended::Entity->new;

  $entity->logger( MyTestLogger->new );

  ok $entity->log( level => 'message' ) eq 'levelmessage', 'custom logger is used';
};

subtest 'invalid_loggers' => sub {
  my %loggers = (
    broken => MyBrokenTestLogger->new,
#   class  => 'MyTestLogger',  # as Log::Dump allows class logger
  );

  for my $logger ( keys %loggers ) {
    my $entity = Path::Extended::Entity->new;
       $entity->logger($loggers{$logger});

    eval { $entity->log( fatal => 'message' ) };
    ok $@ =~ /\[fatal\] message/, "$logger logger falls back to the default";
  }
};

subtest 'fatal_log' => sub {
  my $entity = Path::Extended::Entity->new;
  eval { $entity->log( fatal => 'message' ) };
  ok $@ =~ /\[fatal\] message/,
    'proper fatal message';
};

subtest 'logs_to_stderr' => sub {
  eval { require Capture::Tiny0 } or do {
    SKIP: { skip 'this test requires Capture::Tiny', 1; fail; };
    return;
  };

  my $entity = Path::Extended::Entity->new;

  for my $level (qw( debug warn error )) {
    my ($out, $err) = Capture::Tiny::capture(sub {
      $entity->log( $level => { message => 'message' } );
    });

    # single quotations will be converted to double while dumping
    ok $err =~ /\[$level\] { message => "message" }/, "proper $level message";
  }
};

done_testing;

package #
  MyTestLogger;

sub new { bless {}, shift; }
sub log { shift; return join '', @_ }

package #
  MyBrokenTestLogger;

sub new { bless {}, shift; }

1;
