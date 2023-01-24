#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( is isa_ok ok ) ], tests => 5;

my $class = 'Foo';
my $role  = 'MooX::Role::HasLogger';

eval qq{
  package $class;

  use Log::Log4perl qw();
  use Moo;
  use MooX::TypeTiny; 
  use namespace::clean;

  with qw( $role );

  sub build_logger {
    return Log::Log4perl->get_logger(ref shift);
  }

  1;
};

is $@, '', "Moo class '$class' created dynamically" or die "\n";

is __PACKAGE__, 'main', "current package is 'main'";
ok $class->does( $role ), "class '$class' consumes role '$role'";

isa_ok my $logger = $class->new->logger, 'Log::Log4perl::Logger';
is $class, $logger->category, "custom logger has 'category' attribute with value '$class'";
