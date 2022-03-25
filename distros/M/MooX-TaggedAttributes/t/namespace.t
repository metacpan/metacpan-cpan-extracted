#! perl

use Test2::V0;

use Test::CleanNamespaces;
use Test::Lib;

my @namespaces = qw(
  T12
  T2
  C7
  B1
  R1
  R2
  B3
  T1
  C8
  C9
  C2
  C1
  C5
  C31
  B2
  R3
  C6
  B4
  C10
  C3
  C4
);

namespaces_clean( @namespaces );

# classes which consume the role using 'with' will have 'import'
my @classes     = grep /^C/, @namespaces;
my @with_import = qw( C4 C6 C7 C8 C9);
my %with_import;
@with_import{@with_import} = ();
my @without_import = grep !exists $with_import{$_}, @classes;


sub _getglob {
    no strict 'refs';
    \*{ $_[0] };
}

subtest 'without import()' => sub {
    for my $class ( @without_import ) {
        my $glob = _getglob( "${class}::import" );
        is( *{$glob}{CODE}, U(), $class );
    }
};

subtest 'with import()' => sub {
    for my $class ( @with_import ) {
        my $glob = _getglob( "${class}::import" );
        is( *{$glob}{CODE}, D(), "no ${class}::import" );
    }
};

done_testing;
