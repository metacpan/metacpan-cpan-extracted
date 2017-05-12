use Test::More tests => 4;

{
    package Foo;

    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Types::JSON qw( JSON relaxedJSON );
    
    has json_strict  => ( is => 'rw', isa => JSON, coerce => 1        );
    has json_relaxed => ( is => 'rw', isa => relaxedJSON, coerce => 1 );
}

my %json    = ( 'foo' => 'bar', 'answer' => '42' );
my %nojson  = ( );

my $foo = Foo->new;

eval { $foo->json_strict(\%json) };
ok( $@ eq "", "hash => strict" );

eval { $foo->json_relaxed(\%json) };
ok( $@ eq "", "hash => relaxed" );

eval { $foo->json_strict(\%nojson) };
ok( $@ eq "", "nohash => strict" );

eval { $foo->json_relaxed(\%nojson) };
ok( $@ eq "", "nohash => relaxed" );
