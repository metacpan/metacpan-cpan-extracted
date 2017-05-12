#perl

use strict;
use warnings;

use Test::More tests => 12;

use IO::Scalar;

sub test_logger {
  my ($logger) = @_;

  $logger->info('foo');
  $logger->error('Gah!');
}

{
  package TestCfgurator;
  BEGIN { our @ISA = qw/Log::Dispatch::Configurator/ }
  sub new {
      my $self = {};
      bless $self => shift; 
  }
  sub get_attrs_global { {format => undef, dispatchers => [ 'def' ]} }
  sub get_attrs {
    return {
        class     => 'Log::Dispatch::Screen',
        min_level => 'debug',
        stderr    => 1,
        format    => '[%p] %m (config via subclass)%n',
    }
  }
  sub needs_reload { 0 }
  1;
}

{
  package DefaultLogTest;
  use Moose;
  with 'MooseX::LogDispatch';
  
}

{
  package LogTestLevelsCustom;
  use Moose;
  with 'MooseX::LogDispatch::Levels';

  has log_dispatch_conf => (
     is => 'ro',
     #isa => 'HashRef',
     lazy => 1,
     #required => 1,
     default => sub {{
        class     => 'Log::Dispatch::Screen',
        min_level => 'debug',
        stderr    => 1,
        format    => '[%p] %m all custom-like%n',
     }},
   );
}

{
  package LogTestCustomClass;
  use Moose;
  with 'MooseX::LogDispatch';

  has log_dispatch_conf => (
     is => 'ro',
     #isa => 'Log::Dispatch::Configurator',
     lazy => 1,
     #required => 1,
     default => sub { TestCfgurator->new() },
  );
}

{
  package FileConfigTest;
  use Moose;
  with 'MooseX::LogDispatch';

  has log_dispatch_conf => (
    is => 'ro',
    #isa => 'Str',
    default => 't/test.cfg',
    #required => 1,
    lazy => 1,
  );
}

{
  my $logger = DefaultLogTest->new();

  isa_ok($logger->logger, 'Log::Dispatch');
  is($logger->can('error'), undef, 'Object not polluted');

  tie *STDERR, 'IO::Scalar', \my $err;
  local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

  test_logger($logger->logger);
  untie *STDERR;

  is($err, <<'EOF', 'Got correct errors to stderr');
[info] foo at t/02hash-config.t line 13
[error] Gah! at t/02hash-config.t line 14
EOF

}

{
  my $logger = LogTestLevelsCustom->new();

  isa_ok($logger->logger, 'Log::Dispatch');
  ok($logger->can('error'), 'Object polluted');

  tie *STDERR, 'IO::Scalar', \my $err;
  local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

  test_logger($logger);
  untie *STDERR;

  is($err, <<'EOF', 'Got correct errors to stderr');
[info] foo all custom-like
[error] Gah! all custom-like
EOF

}

{
  my $logger = LogTestCustomClass->new();

  isa_ok($logger->logger, 'Log::Dispatch');
  is($logger->can('error'), undef, 'Object not polluted');

  tie *STDERR, 'IO::Scalar', \my $err;
  local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

  test_logger($logger->logger);
  untie *STDERR;

  is($err, <<'EOF', 'Got correct errors to stderr');
[info] foo (config via subclass)
[error] Gah! (config via subclass)
EOF

}

{
  my $logger = new FileConfigTest;

  isa_ok($logger->logger, 'Log::Dispatch');
  is($logger->can('error'), undef, "Object not polouted");

  tie *STDERR, 'IO::Scalar', \my $err;
  local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

  test_logger($logger->logger);
  untie *STDERR;

  is($err, <<'EOF', "Got correct errors to stderr");
[info] foo at t/02hash-config.t line 13
[error] Gah! at t/02hash-config.t line 14
EOF

}
