#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Scalar::Util;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Module::Generic::TieHash' );
};

use strict;
use warnings;
no warnings 'once';

# my %this = ();
# my $hash = \%this;
my $hash = {};
my $obj = eval
{
    tie( %$hash => 'Module::Generic::TieHash', { debug => $DEBUG, key_object => 1 } );
};
if( $@ )
{
    diag( "Fatal error while tieing hash: $@" );
}
ok( !$@, 'tie' );
isa_ok( $obj => 'Module::Generic::TieHash', 'tie object' );
my $array = [qw( John Paul Jack Peter )];
my $ref = { names => $array };
my $code = sub{ return( $array->[0] ) };
my $scalar = \$array->[0];
my $glob = \*main;
my $foo = Foo::Bar->new( $array->[0] );
$hash->{ $array } = 'array';
$hash->{ $ref } = 'hash';
$hash->{ $code } = 'code';
$hash->{ $scalar } = 'scalar';
$hash->{ $glob } = 'glob';
$hash->{ $foo } = 'object';
$hash->{name} = $array->[0];

subtest 'exists' => sub
{
    ok( exists( $hash->{ $array } ), 'array exists in hash' );
    ok( exists( $hash->{ $ref } ), 'hash exists in hash' );
    ok( exists( $hash->{ $code } ), 'code exists in hash' );
    ok( exists( $hash->{ $scalar } ), 'scalar exists in hash' );
    ok( exists( $hash->{ $glob } ), 'glob exists in hash' );
    ok( exists( $hash->{ $foo } ), 'object exists in hash' );
    ok( exists( $hash->{name} ), 'string exists in hash' );
};

# foreach my $k ( %$hash )
while( my( $k, $type ) = each( %$hash ) )
{
    diag( "Key is '$k' (", overload::StrVal( $k ), ") a ", ( ref( $k ) // 'string' ) ) if( $DEBUG );
    # my $type = $hash->{ $k };
    ok( $type, "value is set -> ${type}" );
    next if( !defined( $type ) );
    diag( "Check hash key of type ${type}" ) if( $DEBUG );

    if( $type eq $array->[0] )
    {
        is( $k, 'name', 'key as string' );
    }
    else
    {
        SKIP:
        {
            ok( ref( $k ), "key of type ${type} is a reference" );
            if( !ref( $k ) )
            {
                skip( overload::StrVal( $k ) . ' is not a reference. It is a ' . ( Scalar::Util::reftype( $k ) // 'string' ), 1 );
            }
            
            if( $type eq 'array' )
            {
                is_deeply( $k => $array, "$type key -> value" );
            }
            elsif( $type eq 'hash' )
            {
                is_deeply( $k => $ref, "$type key -> value" );
            }
            elsif( $type eq 'code' )
            {
                is( $k->(), $code->(), "$type key -> value" );
            }
            elsif( $type eq 'scalar' )
            {
                is( $$k, $$scalar, "$type key -> value" );
            }
            elsif( $type eq 'glob' )
            {
                is( Scalar::Util::refaddr( $k ), Scalar::Util::refaddr( $glob ), "$type key -> value" );
            }
            elsif( $type eq 'object' )
            {
                isa_ok( $k => 'Foo::Bar', "$type key -> value" );
                is( "$k", "$foo", 'Foo::Bar object value' );
            }
        };
    }
}

$hash->{nested} = { type => 'nested' };
my $val = $hash->{nested};
ok( tied( %$val ), 'nested hash value is itself tied' );

done_testing();

{
    package
        Foo::Bar;
    use overload '""' => sub{ $_[0]->{name} };
    sub new
    {
        my $this = shift( @_ );
        my $name = shift( @_ );
        return( bless( { name => $name } => ( ref( $this ) || $this ) ) );
    }
}
__END__

