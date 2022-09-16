#! perl

use Test2::V0;

use Test::CleanNamespaces;
use Test::Lib;
use My::Test;

my @namespaces = qw(
  B1
  B2
  B3
  B4
  C1
  C10
  C2
  C3
  C31
  C4
  C5
  C6
  C7
  C8
  C9
  R1
  R2
  R3
  T1
  T12
  T2
);

my @Classes = grep /C|B/, @namespaces;

sub _getglob {
    no strict 'refs';
    \*{ $_[0] };
}

subtest( $_, \&test_it, $_ ) for
  'My::Class',
  'My::Role',
  ;

sub test_it {
    my $type = shift;

    my $is_role;
    my %loaded = map {
        ( my $name, $is_role ) = load( $_, $type );
        $_ => $name;
    } @Classes;
    my @classes = values %loaded;

    namespaces_clean( @classes );

    # classes which consume the role using 'with' will have 'import',
    # unless -propagate has been specified
    my @with_import = $is_role ? () : map { $loaded{$_} } qw( C4 C6 C7 C8 C9);
    my %with_import;
    @with_import{@with_import} = ();
    my @without_import = grep !exists $with_import{$_}, @classes;

    subtest 'without import()' => sub {
        for my $class ( @without_import ) {
            my $glob = _getglob( "${class}::import" );
            is( *{$glob}{CODE}, U(), $class );
        }
    };

    subtest 'with import()' => sub {
        skip_all "-propagate doesn't export 'import'" unless @with_import;
        for my $class ( @with_import ) {
            my $glob = _getglob( "${class}::import" );
            is( *{$glob}{CODE}, D(), "no ${class}::import" );
        }
    };
}


done_testing;
