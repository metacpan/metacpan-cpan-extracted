#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Module::Generic - t/xs_methods.t
## Tests for XS-accelerated methods in Module::Generic
## Verifies that the XS implementations match the expected Perl semantics
## exactly, including edge cases and boundary conditions.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use utf8;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use open ':std' => 'utf8';
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

# Ensure we can load Module::Generic at all
use_ok( 'Module::Generic' ) or BAIL_OUT( "Cannot load Module::Generic" );

# Create a test object; we need a concrete instance to call methods on
{
    package
        My::Test;
    use parent -norequire, 'Module::Generic';
    sub new { return( bless( {}, shift ) ) }
}

my $o = My::Test->new;
isa_ok( $o, 'Module::Generic', 'test object' );

# Report whether we are running XS or pure-Perl
my $xs = do
{
    no warnings 'once';
    $Module::Generic::XS_LOADED ? 'XS' : 'pure-Perl';
};
diag( "Running $xs implementation" ) if( $DEBUG );

# NOTE: _get_args_as_array
subtest '_get_args_as_array' => sub
{
    # No args
    my $r = $o->_get_args_as_array;
    is( ref( $r ), 'ARRAY',      '_get_args_as_array: no args -> arrayref' );
    is( scalar( @$r ), 0,        '_get_args_as_array: no args -> empty' );

    # Single arrayref -> returned as-is (same reference)
    my $orig = [1, 2, 3];
    my $r2 = $o->_get_args_as_array( $orig );
    is( $r2, $orig,              '_get_args_as_array: single arrayref -> same ref' );
    is_deeply( $r2, [1,2,3],     '_get_args_as_array: single arrayref -> correct contents' );

    # Single non-arrayref -> wrapped
    my $r3 = $o->_get_args_as_array( 42 );
    is( ref( $r3 ), 'ARRAY',     '_get_args_as_array: single scalar -> arrayref' );
    is_deeply( $r3, [42],        '_get_args_as_array: single scalar -> wrapped' );

    # Multiple args -> wrapped
    my $r4 = $o->_get_args_as_array( 1, 2, 3 );
    is_deeply( $r4, [1, 2, 3],   '_get_args_as_array: multiple args -> arrayref' );

    # Single hashref -> wrapped (not an array)
    my $r5 = $o->_get_args_as_array( {a => 1} );
    is_deeply( $r5, [{a=>1}],    '_get_args_as_array: single hashref -> wrapped' );

    # Elements must be mutable copies, not read-only aliases to the call stack.
    # This mirrors [ @_ ] behaviour whereby assigning to $elem must not croak.
    my $r6 = $o->_get_args_as_array( '.pl', '.pm' );
    my $ok = eval { $r6->[0] = qr/\.pl$/i; 1 };
    ok( $ok, '_get_args_as_array: elements are mutable (not read-only)' );

    # Single string arg: the returned element must also be mutable
    my $r7 = $o->_get_args_as_array( '.txt' );
    my $ok2 = eval { $r7->[0] = qr/\.txt$/i; 1 };
    ok( $ok2, '_get_args_as_array: single string element is mutable' );
};

# NOTE: _is_array
subtest '_is_array' => sub
{
    ok( !$o->_is_array( undef ),             '_is_array: undef -> false' );
    ok( !$o->_is_array( 42 ),                '_is_array: integer -> false' );
    ok( !$o->_is_array( {} ),                '_is_array: hashref -> false' );
    ok( !$o->_is_array( sub{} ),             '_is_array: coderef -> false' );
    ok(  $o->_is_array( [] ),                '_is_array: plain arrayref -> true' );
    ok(  $o->_is_array( [1,2,3] ),           '_is_array: non-empty arrayref -> true' );
    ok(  $o->_is_array( bless([],'Foo') ),   '_is_array: blessed arrayref -> true' );
};

# NOTE: _is_code
subtest '_is_code' => sub
{
    ok( !$o->_is_code( undef ),              '_is_code: undef -> false' );
    ok( !$o->_is_code( 42 ),                 '_is_code: integer -> false' );
    ok( !$o->_is_code( [] ),                 '_is_code: arrayref -> false' );
    ok( !$o->_is_code( {} ),                 '_is_code: hashref -> false' );
    ok(  $o->_is_code( sub{} ),              '_is_code: plain coderef -> true' );
    ok(  $o->_is_code( sub{ return 1 } ),    '_is_code: coderef with body -> true' );
    ok(  $o->_is_code( bless(sub{},'Foo') ), '_is_code: blessed coderef -> true' );
    # A reference to \&CORE::say is still a coderef
    ok(  $o->_is_code( \&CORE::die ),        '_is_code: CORE coderef -> true' );
};

# NOTE: _is_glob
subtest '_is_glob' => sub
{
    ok( !$o->_is_glob( undef ),              '_is_glob: undef -> false' );
    ok( !$o->_is_glob( 42 ),                 '_is_glob: integer -> false' );
    ok( !$o->_is_glob( [] ),                 '_is_glob: arrayref -> false' );
    ok( !$o->_is_glob( {} ),                 '_is_glob: hashref -> false' );
    ok(  $o->_is_glob( \*STDOUT ),           '_is_glob: typeglob ref -> true' );
    ok(  $o->_is_glob( \*STDERR ),           '_is_glob: typeglob ref -> true' );
};

# NOTE: _is_hash
subtest '_is_hash' => sub
{
    ok( !$o->_is_hash( undef ),              '_is_hash: undef -> false' );
    ok( !$o->_is_hash( 42 ),                 '_is_hash: integer -> false' );
    ok( !$o->_is_hash( [] ),                 '_is_hash: arrayref -> false' );
    ok( !$o->_is_hash( sub{} ),              '_is_hash: coderef -> false' );
    ok(  $o->_is_hash( {} ),                 '_is_hash: plain hashref -> true' );
    ok(  $o->_is_hash( {a=>1} ),             '_is_hash: non-empty hashref -> true' );
    ok(  $o->_is_hash( bless({},'Foo') ),    '_is_hash: blessed hashref -> true (non-strict)' );
    # strict mode: blessed hashrefs return false
    ok( !$o->_is_hash( bless({},'Foo'), 'strict' ), '_is_hash: blessed hashref -> false (strict)' );
    ok(  $o->_is_hash( {}, 'strict' ),       '_is_hash: plain hashref -> true (strict)' );
};

# NOTE: _is_integer
subtest '_is_integer' => sub
{
    ok( !$o->_is_integer( undef ),           '_is_integer: undef -> false' );
    ok( !$o->_is_integer( '' ),              '_is_integer: empty string -> false' );
    ok( !$o->_is_integer( 'abc' ),           '_is_integer: alpha string -> false' );
    ok( !$o->_is_integer( '3.14' ),          '_is_integer: float string -> false' );
    ok( !$o->_is_integer( '1e5' ),           '_is_integer: scientific notation -> false' );
    ok( !$o->_is_integer( [] ),              '_is_integer: ref -> false' );
    ok(  $o->_is_integer( '42' ),            '_is_integer: string "42" -> true' );
    ok(  $o->_is_integer( 42 ),              '_is_integer: integer literal -> true' );
    ok(  $o->_is_integer( '0' ),             '_is_integer: zero string -> true' );
    ok(  $o->_is_integer( '+42' ),           '_is_integer: +42 -> true' );
    ok(  $o->_is_integer( '-42' ),           '_is_integer: -42 -> true' );
    ok(  $o->_is_integer( '0001' ),          '_is_integer: leading zeros -> true' );
};

# NOTE: _is_number
subtest '_is_number' => sub
{
    # _is_number checks actual numeric SV flags (IOK/NOK), not string appearance
    ok( !$o->_is_number( undef ),            '_is_number: undef -> false' );
    ok( !$o->_is_number( 'hello' ),          '_is_number: plain string -> false' );
    ok( !$o->_is_number( '42' ),             '_is_number: string "42" -> false (no IOK flag)' );
    ok( !$o->_is_number( [] ),               '_is_number: arrayref -> false' );
    # Actual numeric literals have IOK/NOK set by the parser
    ok(  $o->_is_number( 42 ),               '_is_number: integer literal -> true' );
    ok(  $o->_is_number( 3.14 ),             '_is_number: float literal -> true' );
    ok(  $o->_is_number( 0 ),                '_is_number: zero -> true' );
    ok(  $o->_is_number( -1 ),               '_is_number: negative -> true' );
    # JSON-decoded numbers have IOK/NOK set
    my $json_num = do { use JSON; JSON->new->decode('{"n":99}')->{n} };
    ok(  $o->_is_number( $json_num ),        '_is_number: JSON-decoded integer -> true' );
};

# NOTE: _is_object
subtest '_is_object' => sub
{
    ok( !$o->_is_object( undef ),            '_is_object: undef -> false' );
    ok( !$o->_is_object( 42 ),               '_is_object: integer -> false' );
    ok( !$o->_is_object( 'string' ),         '_is_object: string -> false' );
    ok( !$o->_is_object( [] ),               '_is_object: plain arrayref -> false' );
    ok( !$o->_is_object( {} ),               '_is_object: plain hashref -> false' );
    ok( !$o->_is_object( sub{} ),            '_is_object: plain coderef -> false' );
    ok(  $o->_is_object( $o ),               '_is_object: blessed object -> true' );
    ok(  $o->_is_object( bless({}, 'Foo') ), '_is_object: blessed hashref -> true' );
    ok(  $o->_is_object( bless([], 'Foo') ), '_is_object: blessed arrayref -> true' );
};

# NOTE: _is_overloaded
subtest '_is_overloaded' => sub
{
    {
        package
            My::Overloaded;
        use overload '""' => sub { 'overloaded' }, fallback => 1;
        sub new { bless {}, shift }
    }
    {
        package
            My::NotOverloaded;
        sub new { bless {}, shift }
    }

    ok( !$o->_is_overloaded( undef ),                  '_is_overloaded: undef -> false' );
    ok( !$o->_is_overloaded( {} ),                     '_is_overloaded: plain hashref -> false' );
    ok( !$o->_is_overloaded( My::NotOverloaded->new ), '_is_overloaded: non-overloaded object -> false' );
    ok(  $o->_is_overloaded( My::Overloaded->new ),    '_is_overloaded: overloaded object -> true' );
};

# NOTE: _is_scalar
subtest '_is_scalar' => sub
{
    my $x = 42;
    my $s = 'hello';
    ok( !$o->_is_scalar( undef ),           '_is_scalar: undef -> false' );
    ok( !$o->_is_scalar( 42 ),              '_is_scalar: integer (non-ref) -> false' );
    ok( !$o->_is_scalar( [] ),              '_is_scalar: arrayref -> false' );
    ok( !$o->_is_scalar( {} ),              '_is_scalar: hashref -> false' );
    ok( !$o->_is_scalar( sub{} ),           '_is_scalar: coderef -> false' );
    ok(  $o->_is_scalar( \$x ),             '_is_scalar: ref to scalar -> true' );
    ok(  $o->_is_scalar( \$s ),             '_is_scalar: ref to string -> true' );
    ok(  $o->_is_scalar( \42 ),             '_is_scalar: ref to literal -> true' );
    # Ref to ref is also a scalar in reftype() terms
    my $rref = \( \42 );
    ok( !$o->_is_scalar( $rref ),           '_is_scalar: ref-to-ref -> false' );
};

# NOTE: _obj2h
subtest '_obj2h' => sub
{
    my $h = $o->_obj2h;
    ok( defined( $h ),             '_obj2h: returns something' );
    ok( ref( $h ),                 '_obj2h: returns a reference' );
    is( ref( $h ), ref( $o ),      '_obj2h: returns same blessed type' );
    # For a plain hash object, _obj2h returns $self itself
    is( $h, $o,                    '_obj2h: returns self for hash-based object' );
};

# NOTE: _refaddr
subtest '_refaddr' => sub
{
    use Scalar::Util qw( refaddr );
    ok( !defined( $o->_refaddr(undef) ),     '_refaddr: undef -> undef' );
    ok( !defined( $o->_refaddr(42) ),        '_refaddr: non-ref -> undef' );
    is( $o->_refaddr( $o ), refaddr( $o ),   '_refaddr: matches Scalar::Util::refaddr' );
    my $anon_array = [];
    is( $o->_refaddr( $anon_array ), refaddr( $anon_array ) + 0, '_refaddr: arrayref addr is numeric' );
    # Two calls on the same ref must return the same address
    my $ref = {};
    is( $o->_refaddr( $ref ), $o->_refaddr( $ref ), '_refaddr: stable across calls' );
};

done_testing();

__END__
