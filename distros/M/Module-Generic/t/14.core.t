#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    # 2021-11-01T08:12:10
    use Test::Time time => 1635754330;
    use DateTime;
    # use Nice::Try;
    use Scalar::Util;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Module::Generic' );
};

use strict;
use warnings;

my $o = MyObject->new(
    name => 'id',
    total => 12,
    type => 'attribute',
    user_id => '63d36776-c34e-49ad-8d51-02c8abbee3b2',
    value => 'hello',
    version => 'v1.2.3',
    debug => $DEBUG,
);
isa_ok( $o, 'MyObject', 'new' );
my $hash = $o->as_hash;
diag( "as_hash results in: ", $o->dump( $hash ) ) if( $DEBUG );
is_deeply( $hash, {
    name => 'id',
    total => 12,
    type => 'attribute',
    user_id => '63d36776-c34e-49ad-8d51-02c8abbee3b2',
    value => 'hello',
    version => 'v1.2.3',
});
if( $DEBUG )
{
    foreach my $e ( sort( keys( %MyObject:: ) ) )
    {
        if( defined( &{"MyObject::${e}"} ) )
        {
            printf( "%-20s: %s\n", $e, $MyObject::{ $e } );
        }
    }
}

my $o2 = $o->clone || die( $o->error );
ok( $o2->name eq $o->name && $o2->value eq $o->value, 'clone' );

$o->error( "Oopsie" );
my $ex = $o->error;
isa_ok( $ex, 'MyException', 'error' );
is( $ex->message, 'Oopsie', 'error->message' );

$o->error({
    class => 'MyOtherException',
    code  => 500,
    message => 'Mince !',
});
$ex = $o->error;
isa_ok( $ex, 'MyOtherException', 'error->class' );
is( $ex->message, 'Mince !' );

if( !eval
{
    $o->fatal(1);
    $o->error({ message => "Oh no!" });
#     $o->error("Oh no!");
#     my $ex = $o->error;
#     die( $ex );
    fail( "Should not have gotten here." );
})
{
    if( Scalar::Util::blessed( $@ ) && $@->isa( 'MyException' ) )
    {
        pass( "fatal triggered a die" );
        is( $@->message, 'Oh no!' );
    }
    else
    {
        diag( "\$e is '$@' (", overload::StrVal( $@ ), "). Is it undef ? ", ( defined( $@ ) ? 'no' : 'yes' ) );
        fail( "Should not have gotten here." );
    }
}

$o->fatal(0);

my $ar = $o->new_array;
isa_ok( $ar, 'Module::Generic::Array', 'new_array' );

my $f = $o->new_file( './t/test.txt' );
isa_ok( $f, 'Module::Generic::File', 'new_file' );

my $h = $o->new_hash;
isa_ok( $h, 'Module::Generic::Hash', 'new_hash' );

my $n = $o->new_number(10);
isa_ok( $n, 'Module::Generic::Number', 'new_number' );

my $s = $o->new_scalar( 'hello' );
isa_ok( $s, 'Module::Generic::Scalar', 'new_scalar' );

$o->setget( "Jack" );
is( $o->setget, 'Jack', '_set_get' );
$o->setget_assign = 'John';
is( $o->setget_assign, 'John', '_set_get_lvalue' );

# NOTE: Arrays
$o->array( qw( Jack John Paul ) );
$a = $o->array;
is( ref( $a ), 'ARRAY', '_set_get_array' );
SKIP:
{
    if( !defined( $a ) )
    {
        skip( "__set_get_array failed", 2 );
    }
    is( scalar( @$a ), 3 );
    is( $a->[-1], 'Paul' );
};

$a = $o->array_object( [qw( Jack John Paul )] );
isa_ok( $a, 'Module::Generic::Array', '_set_get_array_as_object' );
is( $a->length, 3, 'array object size' );
is( $a->last, 'Paul' );

use utf8;
$o->array_object = [qw( Emmanuel Gabriel Michel Raphaël )];
my $a2 = $o->array_object;
isa_ok( $a2, 'Module::Generic::Array', '_set_get_array_as_object as lvalue' );
is( $a2->length, 4, 'array object size' );
is( $a2->last, 'Raphaël' );

# NOTE: Code
$o->callback = sub{1};
my $cb = $o->callback;
is( ref( $cb ), 'CODE', '_set_get_code' );
$o->callback( sub{2} );
$cb = $o->callback;
is( ref( $cb ), 'CODE', '_set_get_code' );
my $cbv = $o->callback->();
is( $cbv, 2, '_set_get_code exec value' );

# NOTE: DateTime
my $now = time();
$o->created = 'now';
my $dt = $o->created;
$dt->set_time_zone( 'UTC' );
isa_ok( $dt, 'DateTime', '_set_get_datetime as lvalue' );
SKIP:
{
    # try-catch
    local $@;
    if( !eval
    {
        my $dt2 = DateTime->from_epoch( epoch => $now, time_zone => $dt->time_zone );
        diag( "created is '", $dt->iso8601, "' vs '", $dt2->iso8601, "'" ) if( $DEBUG );
        ok( ( $dt->ymd eq $dt2->ymd && $dt->hour == $dt2->hour && $dt->minute == $dt2->minute ), 'datetime value' );
        $o->created( '+1d' );
        my $dt4 = DateTime->now( time_zone => $dt->time_zone )->add( days => 1 );
        $dt4->truncate( to => 'minute' );
        my $dt3 = $o->created->set_time_zone( 'UTC' );
        $dt3->truncate( to => 'minute' );
        isa_ok( $dt3, 'DateTime', '_set_get_datetime' );
        is( $dt3->iso8601, $dt4->iso8601, '_set_get_datetime value' );
    })
    {
        if( $@ =~ /Invalid local time for date in time zone/i )
        {
            skip( "Invalid time when changing time zone", 3 );
        }
    }
};

# NOTE: File
$o->file = "./some/file.txt";
my $f2 = $o->file;
diag( "\$f2 is '", overload::StrVal( $f2 ), "'" ) if( $DEBUG );                             
isa_ok( $f2, 'Module::Generic::File', '_set_get_file as lvalue' );
$o->file( "./some/other.txt" );
my $f3 = $o->file;
isa_ok( $f3, 'Module::Generic::File', '_set_get_file' );

# NOTE: Hash
$o->hash = { name => 'John', type => 'human' };
$hash = $o->hash;
is( ref( $hash ), 'HASH', '_set_get_hash as lvalue' );
is_deeply( $hash, { name => 'John', type => 'human' }, '_set_get_hash value' );
$o->hash( age => 20, location => 'Tokyo' );
$hash = $o->hash;
is( ref( $hash ), 'HASH', '_set_get_hash' );
is_deeply( $hash, { age => 20, location => 'Tokyo' }, '_set_get_hash value' );
$o->hash({ age => 30, location => 'Houston' });
$hash = $o->hash;
is( ref( $hash ), 'HASH', '_set_get_hash' );
is_deeply( $hash, { age => 30, location => 'Houston' }, '_set_get_hash value' );

# NOTE: Lvalue scalar
$o->id = 100;
my $id = $o->id;
is( $id, 100, '_set_get_scalar as lvalue' );
$o->id( 'hello' );
$id = $o->id;
is( $id, 'hello', '_set_get_scalar' );

# NOTE: IP
$o->ip = '127.0.0.1';
my $ip = $o->ip;
is( $ip, '127.0.0.1', '_set_get_ip' );

$o->ip( '192.168.1.1' );
$ip = $o->ip;
is( $ip, '192.168.1.1', '_set_get_ip' );

$o->ip = 'bad ip';
$ip = $o->ip;
is( $ip, '192.168.1.1', '_set_get_ip with bad ip' );
SKIP:
{
    if( !$o->error )
    {
        skip( 'bad ip did not trigger an error', 1 );
        fail( 'bad ip did not trigger an error' );
    }
    is( $o->error->message, 'Value provided (bad ip) is not a valid ip address.', '_set_get_ip bad ip error' );
    diag( "Error is: ", $o->error ) if( $DEBUG );
};

# NOTE: Hash
$o->metadata = { trans_id => 12345, client_id => 67890 };
my $hash2 = $o->metadata;
isa_ok( $hash2, 'Module::Generic::Hash', '_set_get_hash_as_mix_object' );
is_deeply( $hash2, { trans_id => 12345, client_id => 67890 } );

my $ts = time();
$o->metadata( ts => $ts, token => 1234567 );
$hash2 = $o->metadata;
isa_ok( $hash2, 'Module::Generic::Hash', '_set_get_hash_as_mix_object' );
is_deeply( $hash2, { ts => $ts, token => 1234567 } );

$o->metadata({ ts => $ts, token => 7654321 });
$hash2 = $o->metadata;
isa_ok( $hash2, 'Module::Generic::Hash', '_set_get_hash_as_mix_object' );
is_deeply( $hash2, { ts => $ts, token => 7654321 } );

# NOTE: URI
$o->uri = 'https://example.org';
my $u = $o->uri;
isa_ok( $u, 'URI', '_set_get_uri as lvalue' );
is( $u, 'https://example.org', '_set_get_uri value' );

$o->uri( 'https://www.example.org' );
$u = $o->uri();
isa_ok( $u, 'URI', '_set_get_uri' );
is( $u, 'https://www.example.org', '_set_get_uri value' );

# NOTE: scalar
$o->type( 'transaction' );
my $t = $o->type;
isa_ok( $t, 'Module::Generic::Scalar', '_set_get_scalar_as_object' );
is( $t, 'transaction', '_set_get_scalar_as_object value' );

$o->value = 'completed';
my $v = $o->value;
isa_ok( $v, 'Module::Generic::Scalar', '_set_get_scalar_as_object as lvalue' );
is( $v, 'completed', '_set_get_scalar_as_object value' );

$o->value( 'pending' );
$v = $o->value;
isa_ok( $v, 'Module::Generic::Scalar', '_set_get_scalar_as_object' );
is( $v, 'pending', '_set_get_scalar_as_object value' );

# NOTE: DateTime
$dt = $o->datetime;
is( $dt, undef, 'lvalue->get -> undef' );
# $o->debug(4);
$o->datetime = { dt => 'nope' };
is( $o->datetime, undef, 'lvalue->set wrong value -> error' );
is( $o->error->message, 'Value provided is not a datetime.', 'error message' );
$o->fatal(1);
# try-catch
if( !eval
{
    $o->datetime = "plop";
})
{
    is( $@->message, 'Value provided is not a datetime.', 'lvalue -> fatal error' );
}

$now = DateTime->now;
# try-catch
if( !eval
{
    $o->datetime = $now;
})
{
    fail( "proper assignment failed: $@" );
}
$o->fatal(0);
my $dt2 = $o->datetime;
isa_ok( $dt2, 'DateTime', 'lvalue->get is a DateTime object' );
# is( ( $dt2->epoch - $now->epoch ), 10, 'lvalue->get' );
is( $dt2, $now, 'lvalue->get' );
my $now2 = DateTime->now->add( hours => 1 );
isnt( $now2, $now, "new datetime ($now2) isnt same as old datetime ($now)" );
my $now3 = $o->datetime( $now2 );
is( $now3, $now2, 'lvalue->set( $value ) -> return value' );
is( $o->datetime, $now2, 'lvalue->set( $value )' );
isnt( $now3, $now );
# diag( "Is ", overload::StrVal( $now ), " same as ", overload::StrVal( $now3 ) );
# ok( $now3 ne $now );

diag( "Testing for error returning data type instead of undef" ) if( $DEBUG );
subtest "want error" => sub
{
    $o->name( 'id' );
    my $name;
    # Array
    $name = $o->trigger_error->[0];
    is( $name => undef, 'error -> array' );
    # Code
    $name = $o->trigger_error->();
    is( $name => undef, 'error -> code' );
    # Glob
    my $io = *{$o->trigger_error};
    is( Scalar::Util::reftype( \$io ) => 'GLOB', 'error -> glob' );
    # Hash
    $name = $o->trigger_error->{name};
    is( $name => undef, 'error -> hash' );
    # Object
    $name = $o->trigger_error->name;
    is( $name => undef, 'error -> object' );
    # Scalar
    $name = ${$o->trigger_error};
    is( $name => undef, 'error -> scalar' );
};

# NOTE: Glob
subtest "glob" => sub
{
    require Module::Generic::File::IO;
    my $io = Module::Generic::File::IO->new;
    my $rv = $o->io( $io );
    isa_ok( $rv => 'Module::Generic::File::IO', 'glob returned from assignment' );
    $rv = $o->io;
    isa_ok( $rv => 'Module::Generic::File::IO', 'glob returned with accessor' );
    my $io2 = Module::Generic::File::IO->new;
    $o->io = $io2;
    my $rv2 = $o->io;
    is( $rv2, $io2, 'new glob set via lvalue assignment' );
    # diag( "$rv is not $rv2" );
    isnt( $rv, $rv2, 'new glob set' );
    isa_ok( $rv => 'Module::Generic::File::IO', 'glob set with lvalue' );
    $o->io( 'bad io' );
    $rv = $o->io;
    is( $rv, $io2, 'glob remains unchanged after bad assignment' );
};

# NOTE: Number
subtest "number" => sub
{
    my $rv = $o->total;
    isa_ok( $rv => 'Module::Generic::Number', 'number object' );
    is( "$rv", 12, 'number value is 12' );
    $o->total(20);
    $rv = $o->total;
    is( $rv, 20, 'number assigned' );
    $o->total = 30;
    $rv = $o->total;
    is( $rv, 30, 'number assigned via lvalue' );
    $o->total('not a number');
    $rv = $o->total;
    is( $rv, 30, 'number remains unchanged after bad assignment' );
    my $ex = $o->error;
    ok( $ex, 'error set' );
    # diag( "Error message is: ", $ex->message );
    like( $ex, qr/Invalid number/, 'bad number exception' );
};

# NOTE: uuid
subtest "uuid" => sub
{
    my $user_id = $o->user_id;
    is( $user_id, '63d36776-c34e-49ad-8d51-02c8abbee3b2', 'retrieve uuid' );
    $o->user_id = '18e55141-dedc-4bca-9729-ccf91e57d6b4';
    my $rv = $o->user_id;
    is( $rv, '18e55141-dedc-4bca-9729-ccf91e57d6b4', 'assigning uuid with lvalue' );
    my $rv2 = $o->user_id( '585b2f57-b6af-4619-8068-69672ecc407a' );
    is( $rv2, '585b2f57-b6af-4619-8068-69672ecc407a', 'assigning uuid' );
    my $rv3 = $o->user_id;
    is( $rv3, '585b2f57-b6af-4619-8068-69672ecc407a', 'accessing uuid' );
    $o->user_id = 'not an uuid';
    my $rv4 = $o->user_id;
    is( $rv4, '585b2f57-b6af-4619-8068-69672ecc407a', 'assigning bad uuid keeps value unchanged' );
    my $ex = $o->error;
    like( $ex->message, qr/not a valid uuid/, 'bad uuid exception' );
};

# NOTE: version
subtest "version" => sub
{
    my $vers = $o->version;
    isa_ok( $vers, 'version' );
    is( $vers, 'v1.2.3', 'retrieve version number' );
    $o->version = 'v2.3.4';
    my $rv = $o->version;
    isa_ok( $rv, 'version' );
    is( $rv, 'v2.3.4', 'version set with lvalue assignment' );
    $o->version( '3.4' );
    $rv = $o->version;
    isa_ok( $rv, 'version' );
    is( $rv, '3.4', 'version set with regular mutator' );
};

# NOTE: Serialisation
subtest "serialisation" => sub
{
    my $test = { name => 'John', age => 22, location => 'Somewhere' };
    my $has_base64 = $o->_has_base64(1);
    SKIP:
    {
        my $serialiser = 'CBOR::Free';
        if( !$o->_load_class( $serialiser ) )
        {
            skip( "$serialiser serialiser is not installed", ( $has_base64 ? 9 : 6 ) );
        }
        my $bin = $o->serialise( $test, serialiser => $serialiser, preserve_references => 1, scalar_references => 1 );
        diag( "Error serialising data with $serialiser: ", $o->error ) if( !defined( $bin ) );
        # diag( "Serialised data is '$bin'" ) if( $DEBUG );
        ok( defined( $bin ) && length( $bin ), "hash is serialised with $serialiser" );
        my $orig = $o->deserialise( data => $bin, serialiser => $serialiser );
        diag( "Error deserialising data with $serialiser: ", $o->error ) if( !defined( $orig ) );
        # diag( "Deserialised data is '$orig'" ) if( $DEBUG );
        ok( defined( $orig ) && ref( $orig ) eq 'HASH', "data is deserialised with $serialiser" );
        is_deeply( $orig => $test, 'deserialised data is identical' );
        my $tmp_file = $o->new_tempfile;
        my $rv = $o->serialise( $test, file => $tmp_file, serialiser => $serialiser );
        diag( "Error serialising data to file with $serialiser: ", $o->error ) if( !defined( $rv ) );
        ok( $rv, "Hash is serialised to $tmp_file" );
        undef( $orig );
        $orig = $o->deserialise( file => $tmp_file, serialiser => $serialiser );
        diag( "Error deserialising data from file with $serialiser: ", $o->error ) if( !defined( $orig ) );
        ok( defined( $orig ) && ref( $orig ) eq 'HASH', 'data is deserialised from file' );
        is_deeply( $orig => $test, 'deserialised data from file is identical' );
        $tmp_file->remove;
        # with base64 encoding
        if( $has_base64 )
        {
            $bin = $o->serialise( $test, serialiser => $serialiser, base64 => 1 );
            diag( "Error serialising data with $serialiser and base64: ", $o->error ) if( !defined( $bin ) );
            ok( defined( $bin ) && length( $bin ), "hash is serialised with $serialiser and base64" );
            my $orig = $o->deserialise( data => $bin, serialiser => $serialiser, base64 => 1 );
            diag( "Error deserialising data with $serialiser and base64: ", $o->error ) if( !defined( $orig ) );
            # diag( "Deserialised data is '$orig'" ) if( $DEBUG );
            ok( defined( $orig ) && ref( $orig ) eq 'HASH', "data is deserialised with $serialiser and base64" );
            is_deeply( $orig => $test, 'deserialised data is identical' );
        }
    };

    SKIP:
    {
        my $serialiser = 'CBOR::XS';
        if( !$o->_load_class( $serialiser ) )
        {
            skip( "$serialiser serialiser is not installed", ( $has_base64 ? 9 : 6 ) );
        }
        my $bin = $o->serialise( $test, serialiser => $serialiser );
        diag( "Error serialising data with $serialiser: ", $o->error ) if( !defined( $bin ) );
        # diag( "Serialised data is '$bin'" ) if( $DEBUG );
        ok( defined( $bin ) && length( $bin ), "hash is serialised with $serialiser" );
        my $orig = $o->deserialise( data => $bin, serialiser => $serialiser );
        diag( "Error deserialising data with $serialiser: ", $o->error ) if( !defined( $orig ) );
        # diag( "Deserialised data is '$orig'" ) if( $DEBUG );
        ok( defined( $orig ) && ref( $orig ) eq 'HASH', "data is deserialised with $serialiser" );
        is_deeply( $orig => $test, 'deserialised data is identical' );
        my $tmp_file = $o->new_tempfile;
        my $rv = $o->serialise( $test, file => $tmp_file, serialiser => $serialiser );
        diag( "Error serialising data to file with $serialiser: ", $o->error ) if( !defined( $rv ) );
        ok( $rv, "Hash is serialised to $tmp_file" );
        undef( $orig );
        $orig = $o->deserialise( file => $tmp_file, serialiser => $serialiser );
        diag( "Error deserialising data from file with $serialiser: ", $o->error ) if( !defined( $orig ) );
        ok( defined( $orig ) && ref( $orig ) eq 'HASH', 'data is deserialised from file' );
        is_deeply( $orig => $test, 'deserialised data from file is identical' );
        $tmp_file->remove;
        # with base64 encoding
        if( $has_base64 )
        {
            $bin = $o->serialise( $test, serialiser => $serialiser, base64 => 1 );
            diag( "Error serialising data with $serialiser and base64: ", $o->error ) if( !defined( $bin ) );
            ok( defined( $bin ) && length( $bin ), "hash is serialised with $serialiser and base64" );
            my $orig = $o->deserialise( data => $bin, serialiser => $serialiser, base64 => 1 );
            diag( "Error deserialising data with $serialiser and base64: ", $o->error ) if( !defined( $orig ) );
            # diag( "Deserialised data is '$orig'" ) if( $DEBUG );
            ok( defined( $orig ) && ref( $orig ) eq 'HASH', "data is deserialised with $serialiser and base64" );
            is_deeply( $orig => $test, 'deserialised data is identical' );
        }
    };

    SKIP:
    {
        my $serialiser = 'Sereal';
        if( !$o->_load_class( $serialiser ) )
        {
            skip( "$serialiser serialiser is not installed", ( $has_base64 ? 9 : 6 ) );
        }
        my $bin = $o->serialise( $test, serialiser => $serialiser );
        diag( "Error serialising data with $serialiser: ", $o->error ) if( !defined( $bin ) );
        # diag( "Serialised data is '$bin'" ) if( $DEBUG );
        ok( defined( $bin ) && length( $bin ), "hash is serialised with $serialiser" );
        my $orig = $o->deserialise( data => $bin, serialiser => $serialiser );
        diag( "Error deserialising data with $serialiser: ", $o->error ) if( !defined( $orig ) );
        # diag( "Deserialised data is '$orig'" ) if( $DEBUG );
        ok( defined( $orig ) && ref( $orig ) eq 'HASH', "data is deserialised with $serialiser" );
        is_deeply( $orig => $test, 'deserialised data is identical' );
        my $tmp_file = $o->new_tempfile;
        my $rv = $o->serialise( $test, file => $tmp_file, serialiser => $serialiser );
        diag( "Error serialising data to file with $serialiser: ", $o->error ) if( !defined( $rv ) );
        ok( $rv, "Hash is serialised to $tmp_file" );
        undef( $orig );
        $orig = $o->deserialise( file => $tmp_file, serialiser => $serialiser );
        diag( "Error deserialising data from file with $serialiser: ", $o->error ) if( !defined( $orig ) );
        ok( defined( $orig ) && ref( $orig ) eq 'HASH', 'data is deserialised from file' );
        is_deeply( $orig => $test, 'deserialised data from file is identical' );
        $tmp_file->remove;
        # with base64 encoding
        if( $has_base64 )
        {
            $bin = $o->serialise( $test, serialiser => $serialiser, base64 => 1 );
            diag( "Error serialising data with $serialiser and base64: ", $o->error ) if( !defined( $bin ) );
            ok( defined( $bin ) && length( $bin ), "hash is serialised with $serialiser and base64" );
            my $orig = $o->deserialise( data => $bin, serialiser => $serialiser, base64 => 1 );
            diag( "Error deserialising data with $serialiser and base64: ", $o->error ) if( !defined( $orig ) );
            # diag( "Deserialised data is '$orig'" ) if( $DEBUG );
            ok( defined( $orig ) && ref( $orig ) eq 'HASH', "data is deserialised with $serialiser and base64" );
            is_deeply( $orig => $test, 'deserialised data is identical' );
        }
    };
    
    SKIP:
    {
        my $serialiser = 'Storable';
        if( !$o->_load_class( $serialiser ) )
        {
            skip( "$serialiser serialiser is not installed", ( $has_base64 ? 14 : 11 ) );
        }
        my $bin = $o->serialise( $test, serialiser => $serialiser );
        if( !defined( $bin ) )
        {
            BAIL_OUT( $o->error );
        }
        diag( "Serialised data is '$bin'" ) if( $DEBUG );
        ok( defined( $bin ) && length( $bin ), "hash is serialised with $serialiser" );
        my $orig = $o->deserialise( data => $bin, serialiser => $serialiser );
        diag( "Error deserialising data with $serialiser: ", $o->error ) if( !defined( $orig ) );
        diag( "Deserialised data is '$orig'" ) if( $DEBUG );
        ok( defined( $orig ) && ref( $orig ) eq 'HASH', "data is deserialised with $serialiser" );
        is_deeply( $orig => $test, 'deserialised data is identical' );
        my $tmp_file = $o->new_tempfile;
        my $rv = $o->serialise( $test, file => $tmp_file, serialiser => $serialiser );
        diag( "Error serialising data to file with $serialiser: ", $o->error ) if( !defined( $rv ) );
        ok( $rv, "Hash is serialised to $tmp_file" );
        undef( $orig );
        $orig = $o->deserialise( file => $tmp_file, serialiser => $serialiser );
        diag( "Error deserialising data from file with $serialiser: ", $o->error ) if( !defined( $orig ) );
        ok( defined( $orig ) && ref( $orig ) eq 'HASH', 'data is deserialised from file' );
        is_deeply( $orig => $test, 'deserialised data from file is identical' );
        $rv = $o->serialise( $test, file => $tmp_file, serialiser => $serialiser, lock => 1 );
        diag( "Error serialising data to file with lock with $serialiser: ", $o->error ) if( !defined( $rv ) );
        ok( $rv, "Hash is serialised to $tmp_file using lock" );
        undef( $orig );
        $orig = $o->deserialise( file => $tmp_file, serialiser => $serialiser, lock => 1 );
        diag( "Error deserialising data from file with lock with $serialiser: ", $o->error ) if( !defined( $orig ) );
        ok( defined( $orig ) && ref( $orig ) eq 'HASH', 'data is deserialised from file using lock' );
        is_deeply( $orig => $test, 'deserialised data from file with lock is identical' );
        undef( $orig );
        my $fh = $tmp_file->open( '>', { binmode => 'raw', autoflush => 1 }) || do
        {
            fail( "Cannot write to temporary file \"$tmp_file\"." );
            skip( "Fail writing to file", 2 );
        };
        $rv = $o->serialise( $test, io => $fh, serialiser => $serialiser );
        diag( "Error serialising data to filehandle with $serialiser: ", $o->error ) if( !defined( $rv ) );
        $tmp_file->flush;
        # diag( "Temp file $tmp_file size is ", $tmp_file->length, " bytes." ) if( $DEBUG );
        diag( "Temp file $tmp_file size is ", $tmp_file->length, " bytes." );
        ok( !$tmp_file->is_empty, "writing serialised data using file handle" );
        $fh->close;
        $fh = $tmp_file->open( '<', { binmode => 'raw' });
        $orig = $o->deserialise( io => $fh, serialiser => $serialiser );
        diag( "Error deserialising data from filehandle with $serialiser: ", $o->error ) if( !defined( $orig ) );
        is_deeply( $orig => $test, 'deserialised data from file handle is identical' );
        $tmp_file->remove;
        # with base64 encoding
        if( $has_base64 )
        {
            $bin = $o->serialise( $test, serialiser => $serialiser, base64 => 1 );
            diag( "Error serialising data with $serialiser and base64: ", $o->error ) if( !defined( $bin ) );
            ok( defined( $bin ) && length( $bin ), "hash is serialised with $serialiser and base64" );
            my $orig = $o->deserialise( data => $bin, serialiser => $serialiser, base64 => 1 );
            diag( "Error deserialising data with $serialiser and base64: ", $o->error ) if( !defined( $orig ) );
            # diag( "Deserialised data is '$orig'" ) if( $DEBUG );
            ok( defined( $orig ) && ref( $orig ) eq 'HASH', "data is deserialised with $serialiser and base64" );
            is_deeply( $orig => $test, 'deserialised data is identical' );
        }
    };
};

# NOTE: on demand
subtest "on demand" => sub
{
    unless( scalar( keys( %$Module::Generic::AUTOLOAD_SUBS ) ) )
    {
        &Module::Generic::_autoload_subs();
    }
    
#     mkdir( 'dev/on_demand', 0755 ) if( !-e( 'dev/on_demand' ) );
    foreach my $sub ( sort( keys( %$Module::Generic::AUTOLOAD_SUBS ) ) )
    {
#         unless( -e( "dev/on_demand/$sub.pl" ) &&
#             !-z( "dev/on_demand/$sub.pl" ) )
#         {
#             my $fh = IO::File->new( ">dev/on_demand/$sub.pl" ) ||
#                 die( "Unable to write to file 'dev/on_demand/$sub.pl': $!" );
#             $fh->binmode( ':utf-8' );
#             $fh->print( $Module::Generic::AUTOLOAD_SUBS->{ $sub } ) ||
#                 die( "Unable to write to file 'dev/on_demand/$sub.pl': $!" );
#             $fh->close;
#         }
        my $code = "package Module::Generic;\n" . $Module::Generic::AUTOLOAD_SUBS->{ $sub };
        local $@;
        no warnings 'redefine';
        eval( $code );
        ok( !$@, $sub );
        diag( "sub $sub -> $@" ) if( $@ );
    }
};

subtest "symbols" => sub
{
    my $obj = MyObject->new;
    foreach my $n ( qw( array array_object callback created datetime file hash id io ip metadata name setget setget_assign trigger_error type total uri user_id value version ) )
    {
        ok( $obj->_has_symbol( '&' . $n ), "MyObject has symbol $n" );
    }
    ok( !$obj->_has_symbol( '$NOT_EXISTS' ), 'MyObject does not have symbol $NOT_EXISTS' );
    my $vers = $obj->_get_symbol( '$VERSION' );
    ok( defined( $vers ), '_get_symbol' );
    is( $$vers, 'v0.1.0' );
    my @all = sort( grep( !/^message$/, grep( /^[a-z]/, $obj->_list_symbols ) ) );
#     require Data::Pretty;
#     diag( Data::Pretty::dump( [sort( @all )] ) );
    is_deeply( \@all => [qw(
        array array_object as_hash callback can clone created
        datetime debug deserialise error error_handler fatal
        file hash id init io ip isa metadata name new
        new_array new_file new_hash new_number new_scalar
        new_tempfile pass_error serialise setget setget_assign
        total trigger_error type uri user_id value version
    )], '_list_symbols' );
};

done_testing();

# NOTE: Fake class MyObject
package
    MyObject;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'MyException';
    return( $self->SUPER::init( @_ ) );
}

sub array { return( shift->_set_get_array( 'array', @_ ) ); }

sub array_object : lvalue { return( shift->_set_get_array_as_object( 'array_object', @_ ) ); }

sub callback : lvalue { return( shift->_set_get_code( 'callback', @_ ) ); }

sub created : lvalue { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub datetime : lvalue { return( shift->_lvalue({
    set => sub
    {
        my( $self, @args ) = @_;
        if( $self->_is_a( $args[0] => 'DateTime' ) )
        {
            return( $self->{datetime} = shift( @args ) );
        }
        else
        {
            return( $self->error( "Value provided is not a datetime." ) );
        }
    },
    get => sub
    {
        my $self = shift( @_ );
        my $dt = $self->{datetime};
        return( $dt );
    }
}, @_ ) ); }

sub file : lvalue { return( shift->_set_get_file( 'file', @_ ) ); }

sub hash : lvalue { return( shift->_set_get_hash( 'hash', @_ ) ); }

sub id : lvalue { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub io : lvalue { return( shift->_set_get_glob( 'io', @_ ) ); }

sub ip : lvalue { return( shift->_set_get_ip( 'ip', @_ ) ); }

sub metadata : lvalue { return( shift->_set_get_hash_as_mix_object( 'metadata', @_ ) ); }

sub name : lvalue { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub setget { return( shift->_set_get( 'setget', @_ ) ); }

sub setget_assign : lvalue { return( shift->_set_get_lvalue( 'setget', @_ ) ); }

sub trigger_error { return( shift->error({
    message => "Oopsie",
    want => [qw( all )],
}) ); }

sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

sub total : lvalue { return( shift->_set_get_number( 'total', @_ ) ); }

sub uri : lvalue { return( shift->_set_get_uri( 'uri', @_ ) ); }

sub user_id : lvalue { return( shift->_set_get_uuid( 'user_id', @_ ) ); }

sub value : lvalue { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }

sub version : lvalue { return( shift->_set_get_version( 'version', @_ ) ); }

# NOTE: class MyException
package
    MyException;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
};

# NOTE: class MyOtherException
package
    MyOtherException;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
};

__END__

