use Test::More tests => 6;

{
    package Foo;

    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Types::JSON qw( JSON relaxedJSON );
    
    has json_strict  => ( is => 'rw', isa => JSON        );
    has json_relaxed => ( is => 'rw', isa => relaxedJSON );
}

my $json    = qq| { "foo": "bar", "answer": "42"   } |;
my $relaxed = qq| { "foo": "bar", "answer": "42",  } |;
my $nojson  = qq| {                                { |;

my $foo = Foo->new;

eval { $foo->json_strict($json) };
ok( $@ eq "", "strict => strict" );

eval { $foo->json_strict($relaxed) };
like( $@, qr/json_strict/, "relaxed => strict" );

eval { $foo->json_relaxed($json) };
ok( $@ eq "", "strict => relaxed" );

eval { $foo->json_relaxed($relaxed) };
ok( $@ eq "", "relaxed => relaxed" );

eval { $foo->json_relaxed($nojson) };
like( $@, qr/json_relaxed/, "nojson => relaxed" );

eval { $foo->json_strict($nojson) };
like( $@, qr/json_strict/, "nojson => strict" );
