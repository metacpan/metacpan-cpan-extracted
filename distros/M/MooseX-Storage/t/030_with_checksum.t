use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use Test::Requires qw(
    Digest::HMAC_SHA1
    JSON::MaybeXS
);
diag 'using JSON backend: ', JSON;

plan tests => 25;

{
    package Foo;
    use Moose;
    use MooseX::Storage;

    with Storage(base => 'WithChecksum', format => "JSON");

    has 'number' => ( is => 'ro', isa => 'Int' );
    has 'string' => ( is => 'ro', isa => 'Str' );
    has 'float'  => ( is => 'ro', isa => 'Num' );
    has 'array'  => ( is => 'ro', isa => 'ArrayRef' );
    has 'hash'   => ( is => 'ro', isa => 'HashRef' );
    has 'object' => ( is => 'ro', isa => 'Foo' );
}

{
    my $foo = Foo->new(
        number => 10,
        string => 'foo',
        float  => 10.5,
        array  => [ 1 .. 10 ],
        hash   => { map { $_ => undef } ( 1 .. 10 ) },
        object => Foo->new( number => 2 ),
    );
    isa_ok( $foo, 'Foo' );

    my $packed = $foo->pack;

    cmp_deeply(
        $packed,
        {
            __CLASS__ => 'Foo',
            __DIGEST__  => re('[0-9a-f]+'),
            number    => 10,
            string    => 'foo',
            float     => 10.5,
            array     => [ 1 .. 10 ],
            hash      => { map { $_ => undef } ( 1 .. 10 ) },
            object    => {
                            __CLASS__ => 'Foo',
                            __DIGEST__  => re('[0-9a-f]+'),
                            number    => 2
                         },
        },
        '... got the right frozen class'
    );

    my $foo2;
    is( exception {
        $foo2 = Foo->unpack($packed);
    }, undef, '... unpacked okay');
    isa_ok($foo2, 'Foo');

    cmp_deeply(
        $foo2->pack,
        {
            __CLASS__ => 'Foo',
            __DIGEST__  => re('[0-9a-f]+'),
            number    => 10,
            string    => 'foo',
            float     => 10.5,
            array     => [ 1 .. 10 ],
            hash      => { map { $_ => undef } ( 1 .. 10 ) },
            object    => {
                            __CLASS__ => 'Foo',
                            __DIGEST__  => re('[0-9a-f]+'),
                            number    => 2
                         },
        },
        '... got the right frozen class'
    );
}

{
    my $foo = Foo->new(
        number => 10,
        string => 'foo',
        float  => 10.5,
        array  => [ 1 .. 10 ],
        hash   => { map { $_ => undef } ( 1 .. 10 ) },
        object => Foo->new( number => 2 ),
    );
    isa_ok( $foo, 'Foo' );

    my $frozen = $foo->freeze;

    ok( length($frozen), "got frozen data" );

    $frozen =~ s/foo/bar/;

    my $foo2 = eval { Foo->thaw( $frozen ) };
    my $e = $@;

    ok( !$foo2, "not thawed" );
    ok( $e, "has error" );
    like( $e, qr/bad checksum/i, "bad checksum error" );
}

SKIP: {
    eval { require Digest::HMAC_SHA1 };
    if ($@)
    {
        my $message = join( " ", "no Digest::HMAC", ( $@ =~ /\@INC/ ? () : do { chomp(my $e = $@); "($e)" } ) );
        die $message if $ENV{AUTHOR_TESTING};
        skip $message, 15;
    }

    local $::DEBUG = 1;

    my $foo = Foo->new(
        number => 10,
        string => 'foo',
        float  => 10.5,
        array  => [ 1 .. 10 ],
        hash   => { map { $_ => undef } ( 1 .. 10 ) },
        object => Foo->new( number => 2 ),
    );
    isa_ok( $foo, 'Foo' );

    my $frozen1 = $foo->freeze( digest => [ "HMAC_SHA1", "secret" ] );
    ok( length($frozen1), "got frozen data" );

    $::DEBUG = 0;

    my $d2 = Digest::HMAC_SHA1->new("s3cr3t");

    my $frozen2 = $foo->freeze( digest => $d2 );
    ok( length($frozen2), "got frozen data" );

    cmp_ok( $frozen1, "ne", $frozen2, "versions are different" );

    is( $frozen1, $foo->freeze( digest => [ HMAC_SHA1 => "secret" ] ), "refreeze" );

$::DEBUG = 1;

    my $foo1 = eval { Foo->thaw( $frozen1, digest => [ "HMAC_SHA1", "secret" ] ) };
    my $e = $@;

    ok( $foo1, "thawed" );
    ok( !$e, "no error" ) || diag $e;

    my $foo2 = eval { Foo->thaw( $frozen2, digest => $d2 ) };
    $e = $@;

    ok( $foo2, "thawed" );
    ok( !$e, "no error" ) || diag $e;

    $foo1 = eval { Foo->thaw( $frozen1, digest => $d2 ) };
    $e = $@;

    ok( !$foo1, "not thawed" );
    ok( $e, "has error" );
    like( $e, qr/bad checksum/i, "bad checksum error" );

    $frozen1 =~ s/foo/bar/;

    $foo1 = eval { Foo->thaw( $frozen1, digest => [ "HMAC_SHA1", "secret" ] ) };
    $e = $@;

    ok( !$foo1, "not thawed" );
    ok( $e, "has error" );
    like( $e, qr/bad checksum/i, "bad checksum error" );
}
