use Test::More tests => 10*8;

{
    package Foo;

    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Digest qw( MD5 SHA1 SHA224 SHA256 SHA384 SHA512 SHA3_224 SHA3_256 SHA3_384 SHA3_512);

    has md5      => ( is => 'rw', isa => MD5      );
    has sha1     => ( is => 'rw', isa => SHA1     );
    has sha224   => ( is => 'rw', isa => SHA224   );
    has sha256   => ( is => 'rw', isa => SHA256   );
    has sha384   => ( is => 'rw', isa => SHA384   );
    has sha512   => ( is => 'rw', isa => SHA512   );
    has sha3_224 => ( is => 'rw', isa => SHA3_224 );
    has sha3_256 => ( is => 'rw', isa => SHA3_256 );
    has sha3_384 => ( is => 'rw', isa => SHA3_384 );
    has sha3_512 => ( is => 'rw', isa => SHA3_512 );
}

my %digest = (
    MD5 => {
        ok => [
            '3a59124cfcc7ce26274174c962094a20',
            '3A59124CFCC7CE26274174C962094A20'
        ],
        fail => [
            '3a59124cfcc7ce26274174c962094a2x',
            '3a59124cfcc7ce26274174c962094a2-',
            '3a59124cfcc7ce26274174c962094a200ab',
            '3a59124cfcc7ce26274174c96209'
        ]
    },
    SHA1 => {
        ok => [
            '1dff4026f8d3449cc83980e0e6d6cec075303ae3',
            '1DFF4026F8D3449CC83980E0E6D6CEC075303AE3'
        ],
        fail => [
            '1dff4026f8d3449cc83980e0e6d6cec075303aex',
            '1dff4026f8d3449cc83980e0e6d6cec075303ae-',
            '1dff4026f8d3449cc83980e0e6d6cec075303ae333',
            '1dff4026f8d3449cc83980e0e6d6cec07533'
        ]
    },
    SHA224 => {
        ok => [
            '906bbee30415aab29f8309b829b521bb4275de9a302b37480ab129e9',
            'df9e8421b7a93a4e91a54918efa9eab6d1a14772760649ff8f574eda'
        ],
        fail => [
            'df9e8421b7a93a4e91a54918efa9eab6d1a14772760649ff8f574edx',
            'df9e8421b7a93a4e91a54918efa9eab6d1a14772760649ff8f574ed-',
            '1dff4026f8d3449cc83980e0e6d6cec075303ae333',
            'df9e8421b7a93a4e91a54918efa9eab6d1a14772760649ff8f574edaabdc'
        ]
    },
    SHA256 => {
        ok => [
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc256fb7f16b901fb1317',
            '787ec76dcafd20c1908eb0936a12f91edd105ab5cd7ecc2b1ae2032648345dff'
        ],
        fail => [
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc256fb7f16b901fb131x',
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc256fb7f16b901fb131-',
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc2',
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc256fb7f16b901fb13179999999'
        ]
    },
    SHA384 => {
        ok => [
            'd3e23b4f16ea11c71aba0d23ba04a5625482a33bdcc69e63e2b86122470d22cf906bdbbcb204e73ec1338c8508bb2e2a',
            'd601486016cb1550e607e8d9b78c7a4b9afb5f96572a28f497960d3fbd31de0ffc3012ce875f84db8e1a32928a9f66cb'
        ],
        fail => [
            'd601486016cb1550e607e8d9b78c7a4b9afb5f96572a28f497960d3fbd31de0ffc3012ce875f84db8e1a32928a9f66cx',
            'd601486016cb1550e607e8d9b78c7a4b9afb5f96572a28f497960d3fbd31de0ffc3012ce875f84db8e1a32928a9f66c-',
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc2',
            'd601486016cb1550e607e8d9b78c7a4b9afb5f96572a28f497960d3fbd31de0ffc3012ce875f84db8e1a32928a9f66cbabc398'
        ]
    },
    SHA512 => {
        ok => [
            'f5a1114e161b25c70469124edce3dc800a929aaca4d2640cdb66afdeb0225e118f773434beb2d5eba908a0c2a8ab5843362c382eaaa5eb5233a24398df6d2a69',
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f272fd969fd6e2e6e35be35072e742c4b36fec48feb87df'
        ],
        fail => [
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f272fd969fd6e2e6e35be35072e742c4b36fec48feb87dx',
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f272fd969fd6e2e6e35be35072e742c4b36fec48feb87d-',
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f27',
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f272fd969fd6e2e6e35be35072e742c4b36fec48feb87dfabcdef'
        ]
    },
    SHA3_224 => {
        ok => [
            '906bbee30415aab29f8309b829b521bb4275de9a302b37480ab129e9',
            'df9e8421b7a93a4e91a54918efa9eab6d1a14772760649ff8f574eda'
        ],
        fail => [
            'df9e8421b7a93a4e91a54918efa9eab6d1a14772760649ff8f574edx',
            'df9e8421b7a93a4e91a54918efa9eab6d1a14772760649ff8f574ed-',
            '1dff4026f8d3449cc83980e0e6d6cec075303ae333',
            'df9e8421b7a93a4e91a54918efa9eab6d1a14772760649ff8f574edaabdc'
        ]
    },
    SHA3_256 => {
        ok => [
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc256fb7f16b901fb1317',
            '787ec76dcafd20c1908eb0936a12f91edd105ab5cd7ecc2b1ae2032648345dff'
        ],
        fail => [
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc256fb7f16b901fb131x',
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc256fb7f16b901fb131-',
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc2',
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc256fb7f16b901fb13179999999'
        ]
    },
    SHA3_384 => {
        ok => [
            'd3e23b4f16ea11c71aba0d23ba04a5625482a33bdcc69e63e2b86122470d22cf906bdbbcb204e73ec1338c8508bb2e2a',
            'd601486016cb1550e607e8d9b78c7a4b9afb5f96572a28f497960d3fbd31de0ffc3012ce875f84db8e1a32928a9f66cb'
        ],
        fail => [
            'd601486016cb1550e607e8d9b78c7a4b9afb5f96572a28f497960d3fbd31de0ffc3012ce875f84db8e1a32928a9f66cx',
            'd601486016cb1550e607e8d9b78c7a4b9afb5f96572a28f497960d3fbd31de0ffc3012ce875f84db8e1a32928a9f66c-',
            '718d54b2f9f41ef058c45f5bd0fec9730e40661f0c4dc2',
            'd601486016cb1550e607e8d9b78c7a4b9afb5f96572a28f497960d3fbd31de0ffc3012ce875f84db8e1a32928a9f66cbabc398'
        ]
    },
    SHA3_512 => {
        ok => [
            'f5a1114e161b25c70469124edce3dc800a929aaca4d2640cdb66afdeb0225e118f773434beb2d5eba908a0c2a8ab5843362c382eaaa5eb5233a24398df6d2a69',
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f272fd969fd6e2e6e35be35072e742c4b36fec48feb87df'
        ],
        fail => [
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f272fd969fd6e2e6e35be35072e742c4b36fec48feb87dx',
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f272fd969fd6e2e6e35be35072e742c4b36fec48feb87d-',
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f27',
            '13d6c73ac8cceeff9ff6b0ba2ce19c5fc47ac21f9fd403c151fe88e0fd39f4223c29bc9bded59e1e3f272fd969fd6e2e6e35be35072e742c4b36fec48feb87dfabcdef'
        ]
    }
);

my $foo = Foo->new;

for my $type ( keys %digest ) {
    my $method = lc $type;
    for my $value ( @{ $digest{$type}->{ok} } ) {

        eval { $foo->$method($value) };

        ok( $@ eq "", "eval" );
        ok( $foo->$method, $value );

    }
    for my $value ( @{ $digest{$type}->{fail} } ) {

        eval { $foo->$method($value) };

        like( $@, qr/$method/, "fail test" );

    }
}
