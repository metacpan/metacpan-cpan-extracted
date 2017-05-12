#perl

use strict;
use warnings;

use IO::Scalar;

use Test::More tests => 9;
use Test::Exception;

dies_ok {
  package DeprecatedTest;

  use Moose;
  use MooseX::LogDispatch;

  with Logger();
} "Use of Logger() dies, now deprecated.";

{
  package ConfigLogTest;

  use Moose;
  with qw/MooseX::LogDispatch/;
  has config_filename => (
      is => 'ro',
      lazy => 1,
      default => '/path/to/my/logfile',
  );
} 

{
  package HardwiredLogTest;

  use Moose;
  with qw(MooseX::LogDispatch);
}

sub test_logger {
  my ($logger) = @_;

  $logger->debug('foo');
  $logger->info('foo');
  $logger->error('Gah!');
}

{
  my $logger = new ConfigLogTest(
    config_filename => 't/test.cfg'
  );

  isa_ok($logger->logger, 'Log::Dispatch');
  is($logger->can('error'), undef, "Object not polluted");

  tie *STDERR, 'IO::Scalar', \my $err;
  local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

  test_logger($logger->logger);
  untie *STDERR;

  is($err, <<'EOF', "Got correct errors to stderr");
[info] foo at t/01basic.t line 43
[error] Gah! at t/01basic.t line 44
EOF

}

{
  my $logger = new HardwiredLogTest;
  
  isa_ok($logger->logger, 'Log::Dispatch');
  is($logger->can('error'), undef, "Object not polluted");

  tie *STDERR, 'IO::Scalar', \my $err;
  local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

  test_logger($logger->logger);
  untie *STDERR;

  # Remove dates from front of lines
  $err =~ s{^\[\w+ \w+\s+\d{1,2}\s+\d\d:\d\d:\d\d \d{4}\] }{}gm;

  is($err, <<'EOF', "Got correct errors to stderr");
[debug] foo at t/01basic.t line 42
[info] foo at t/01basic.t line 43
[error] Gah! at t/01basic.t line 44
EOF

}

{
  package LevelsLogTest;

  use Moose;
  with qw/MooseX::LogDispatch::Levels/;
}

{
  my $logger = new LevelsLogTest;
  isa_ok($logger->logger, 'Log::Dispatch');

  tie *STDERR, 'IO::Scalar', \my $err;
  local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

  test_logger($logger);
  untie *STDERR;

  # Remove dates from front of lines
  $err =~ s{^\[\w+ \w+\s+\d{1,2}\s+\d\d:\d\d:\d\d \d{4}\] }{}gm;

  is($err, <<'EOF', "Got correct errors to stderr");
[debug] foo at t/01basic.t line 42
[info] foo at t/01basic.t line 43
[error] Gah! at t/01basic.t line 44
EOF

}

