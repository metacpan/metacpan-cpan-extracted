#perl

use strict;
use warnings;

use Test::More tests => 4;

use IO::Scalar;

sub test_logger {
  my ($logger) = @_;

  $logger->info('foo');
  $logger->error('Gah!');
}

{
  package TestCfgurator;
  use base qw(Log::Dispatch::Configurator);
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

use Log::Dispatch::Config;
Log::Dispatch::Config->configure( TestCfgurator->new );

{
  package DefaultLogTest;
  use Moose;
  with 'MooseX::LogDispatch';

  has '+use_logger_singleton' => ( default => 1 );
}

{
  my $logger = DefaultLogTest->new();

  isa_ok($logger->logger, 'Log::Dispatch');
  is($logger->can('error'), undef, 'Object not polluted');

  is( $logger->logger, Log::Dispatch::Config->instance, "it's the singleton" );

  tie *STDERR, 'IO::Scalar', \my $err;
  local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

  test_logger($logger->logger);
  untie *STDERR;

  is($err, <<'EOF', 'Got correct errors to stderr');
[info] foo (config via subclass)
[error] Gah! (config via subclass)
EOF


}
