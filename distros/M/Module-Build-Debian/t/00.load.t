use Test::More tests => 3;

BEGIN {
use_ok( 'Module::Build::Debian' );
}

diag( "Testing Module::Build::Debian $Module::Build::Debian::VERSION" );

my $builder = My::Module::Build::Subclass->new( );

ok( $builder->can('ACTION_debian'),       'ACTION_debian       imported' );
ok( $builder->can('ACTION_debianclean'),  'ACTION_debianclean  imported' );

package My::Module::Build::Subclass;

BEGIN {
   eval 'use Module::Build::Debian';
}

sub new {
   return bless { }, shift;
}
