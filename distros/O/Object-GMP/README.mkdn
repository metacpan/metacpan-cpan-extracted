# NAME

Object::GMP - Moo Role for any object has GMP field

## USAGE

This module is a moo role

### Example

    package Foo;
    use Moo;
    with "Object::GMP";
    has a     => ( is => 'ro' );
    has b     => ( is => 'ro' );
    has prime => ( is => 'rw' );
    around BUILDARGS => __PACKAGE__->BUILDARGS_val2gmp('prime');
    1;

The above exmaple to declare the field 'prime' is a GMP value.

    my $prime =
     '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F';
    my $foo = Foo->new( a => 0, b => 7, prime => $prime );
    isnt( ref( $foo->a ), undef, 'a is not gmp' );
    isnt( ref( $foo->b ), undef, 'b is not gmp' );
    isa_ok( $foo->prime, 'Math::BigInt', 'prime is gmp' );

So when you create an object, a and b will be normal value
and prime will be a GMP value.

# LINKS

**Git Repo**: [https://github.com/mvu8912/perl5-object-gmp.git](https://github.com/mvu8912/perl5-object-gmp.git)

**CPAN Module**: [https://metacpan.org/pod/Object::GMP](https://metacpan.org/pod/Object::GMP)
