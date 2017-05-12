use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

my $i = 0;
sub new_singleton_pkg {
  my $pkg_name = sprintf 'MooseX::Singleton::Test%s', $i++;
  eval qq{
    package $pkg_name;
    use MooseX::Singleton;
    has number => (is => 'rw', isa => 'Num', required => 1);
    has string => (is => 'rw', isa => 'Str', default  => 'Hello!');
  };

  return $pkg_name;
}

like( exception { new_singleton_pkg()->instance },
    qr/\QAttribute (number) is required/,
    q{can't get the Singleton if requires attrs and we don't provide them});

like( exception { new_singleton_pkg()->string },
    qr/\QAttribute (number) is required/,
    q{can't call any Singleton attr reader if Singleton can't be inited});

for my $pkg (new_singleton_pkg) {
    my $mst = $pkg->new( number => 5 );
    isa_ok( $mst, $pkg );

    is( $mst->number, 5, "the instance has the given attribute value" );

    is(
        $pkg->number,
        5,
        "the class method, called directly, returns the given attribute value"
    );

    like( exception { $pkg->new( number => 3 ) },
        qr/already/,
        "can't make new singleton with conflicting attributes");

    my $second = eval { $pkg->new };
    ok( !$@, "...but a second ->new without args is okay" );

    is( $second->number, 5,
        "...we get the originally inited number from it" );

    like( exception { $pkg->initialize },
        qr/already/,
        "...but ->initialize() is still an error");
}

{
    package Single;

    use MooseX::Singleton;

    has foo => ( is => 'ro' );
}

{
    Single->initialize( foo => 2 );
    ok( Single->new, 'can call ->new without any args' );
    ok( Single->instance, 'can call ->instance without any args' );
}

done_testing;
