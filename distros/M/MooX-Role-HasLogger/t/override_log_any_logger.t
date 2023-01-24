#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( is ok ) ], tests => 5;
use Test::Output qw( stderr_is );

my $class = 'Foo';
my $role  = 'MooX::Role::HasLogger';

eval qq{
  package $class;

  use Moo;
  use MooX::TypeTiny;
  use Types::Standard              qw( HasMethods );
  use MooX::Role::HasLogger::Types qw( Logger );
  use namespace::clean;

  with qw( $role );

  has '+logger' => ( isa => ( Logger ) & ( HasMethods [ qw( tracef debugf infof warnf errorf fatalf ) ] ) );

  sub build_logger {
    return Log::Any->get_logger( category => ref shift, default_adapter => 'Stderr' );
  }

  1;
};

is $@, '', "Moo class '$class' created dynamically" or die "\n";

is __PACKAGE__, 'main', "current package is 'main'";
ok $class->does( $role ), "class '$class' consumes role '$role'";

my $logger = $class->new->logger;
is $class, $logger->category, "default logger has 'category' attribute with value '$class'";

stderr_is { $logger->infof( 'log %s', 'something' ) } "log something\n", "'Stderr' is the default 'Log::Any::Adapter'";
