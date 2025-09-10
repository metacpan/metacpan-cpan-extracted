BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    # use open ':std' => ':utf8';
    use Test::More;
    use Config;
    use_ok( 'Module::Generic::Dynamic' ) || BAIL_OUT( "Unable to load Module::Generic::Exception" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use JSON::PP;
use Module::Generic::Array;
use Module::Generic::Boolean;
use Module::Generic::File;
use Module::Generic::Number;
use URI;

subtest 'dynamic class creation' => sub
{
    my $obj = Module::Generic::Dynamic->new({
        name => 'Test Product',
        metadata => { sku => 'ABC123', price => 99.99 },
        tags => [qw( product test )],
        created => '2023-11-18T10:30:00',
        is_active => 1,
        ip_address => '192.168.1.1',
        version => '1.2.3',
        file => './config.ini',
        count => 42,
        code_ref => sub { return "test" },
    });
    ok( $obj, 'Object created successfully' );
    is( $obj->name, 'Test Product', 'Scalar method works' );
    isa_ok( $obj->metadata, 'Module::Generic::Dynamic', 'Hash method creates object' );
    is( $obj->metadata->sku, 'ABC123', 'Nested method works' );
    isa_ok( $obj->tags, 'Module::Generic::Array', 'Array method returns array object' );
    is( $obj->tags->length, 2, 'Array length correct' );
    isa_ok( $obj->created, 'DateTime', 'Datetime method returns DateTime object' );
    is( $obj->created->year, 2023, 'Datetime year correct' );
    isa_ok( $obj->is_active, 'Module::Generic::Boolean', 'Boolean method returns boolean object' );
    is( $obj->is_active, 1, 'Boolean value correct' );
    isa_ok( $obj->ip_address, 'Module::Generic::Scalar', 'IP method returns scalar object' );
    is( $obj->ip_address, '192.168.1.1', 'IP value correct' );
    isa_ok( $obj->version, 'version', 'Version method returns version object' );
    is( $obj->version->stringify, '1.2.3', 'Version value correct' );
    isa_ok( $obj->file, 'Module::Generic::File', 'File method returns file object' );
    is( $obj->file->basename, 'config.ini', 'File basename correct' );
    isa_ok( $obj->count, 'Module::Generic::Number', 'Integer method returns number object' );
    is( $obj->count, 42, 'Integer value correct' );
    ok( $obj->code_ref->(), 'Code ref method callable' );
    is( $obj->code_ref->(), 'test', 'Code ref returns correct value' );
};

subtest 'AUTOLOAD with specific types' => sub
{
    my $obj = Module::Generic::Dynamic->new;
    $obj->url( 'https://example.com' );
    isa_ok( $obj->url, 'URI', 'AUTOLOAD creates URI method' );
    is( $obj->url->host, 'example.com', 'URI host correct' );

    $obj->id( 'c47e1113-8336-4437-ba20-54f8cd0afb18' );
    isa_ok( $obj->id, 'Module::Generic::Scalar', 'AUTOLOAD creates UUID method' );
    is( $obj->id, 'c47e1113-8336-4437-ba20-54f8cd0afb18', 'UUID value correct' );

    $obj->has_feature(0);
    isa_ok( $obj->has_feature, 'Module::Generic::Boolean', 'AUTOLOAD creates boolean method' );
    is( $obj->has_feature, 0, 'Boolean value correct' );

    $obj->file_path( '~/documents/test.txt' );
    isa_ok( $obj->file_path, 'Module::Generic::File', 'AUTOLOAD creates file method' );
    is( $obj->file_path->basename, 'test.txt', 'File basename correct' );

    $obj->quantity(100);
    isa_ok( $obj->quantity, 'Module::Generic::Number', 'AUTOLOAD creates integer method' );
    is( $obj->quantity, 100, 'Integer value correct' );
};

subtest 'object handling' => sub
{
    my $obj = Module::Generic::Dynamic->new({
        bool_obj => $JSON::PP::true,
        file_obj => Module::Generic::File->new('test.pdf'),
        array_obj => Module::Generic::Array->new([1, 2, 3]),
        number_obj => Module::Generic::Number->new(42),
        custom_obj => bless({ foo => 'bar' }, 'My::Custom::Class'),
    });
    isa_ok( $obj->bool_obj, 'Module::Generic::Boolean', 'JSON::PP::Boolean object handled correctly' );
    is( $obj->bool_obj, 1, 'Boolean object value correct' );
    isa_ok( $obj->file_obj, 'Module::Generic::File', 'Module::Generic::File object handled correctly' );
    is( $obj->file_obj->basename, 'test.pdf', 'File object basename correct' );
    isa_ok( $obj->array_obj, 'Module::Generic::Array', 'Module::Generic::Array object handled correctly' );
    is( $obj->array_obj->length, 3, 'Array object length correct' );
    isa_ok( $obj->number_obj, 'Module::Generic::Number', 'Module::Generic::Number object handled correctly' );
    is( $obj->number_obj, 42, 'Number object value correct' );
    isa_ok( $obj->custom_obj, 'My::Custom::Class', 'Custom object handled correctly' );
    is( $obj->custom_obj->{foo}, 'bar', 'Custom object data preserved' );
};

subtest 'edge cases and invalid inputs' => sub
{
    my $obj = Module::Generic::Dynamic->new({
        invalid_uuid => 'not-a-uuid',
        invalid_ip => '256.256.256.256',
        invalid_file => "/api/v1\n",
        empty => '',
        undef_field => undef,
        '10invalid_method' => '123-invalid',
        nested_deep => { level1 => { level2 => { level3 => 'deep' } } },
    });
    is( $obj->invalid_uuid, 'not-a-uuid', 'Invalid UUID treated as scalar' );
    isa_ok( $obj->invalid_uuid, 'Module::Generic::Scalar', 'Invalid UUID returns scalar object' );
    is( $obj->invalid_ip, '256.256.256.256', 'Invalid IP treated as scalar' );
    isa_ok( $obj->invalid_ip, 'Module::Generic::Scalar', 'Invalid IP returns scalar object' );
    is( $obj->invalid_file, "/api/v1\n", 'Invalid file path treated as scalar' );
    isa_ok( $obj->invalid_file, 'Module::Generic::Scalar', 'Invalid file path returns scalar object' );
    is( $obj->empty, '', 'Empty string treated as scalar' );
    isa_ok( $obj->empty, 'Module::Generic::Scalar', 'Empty string returns scalar object' );
    # The following test does not work, because in scalar context, it returns undef if the value is undefined.
    # is( $obj->undef_field, 'undef', 'Undefined value treated as scalar' );
    # So, instead we do this:
    ok( $obj->_can( $obj->undef_field => 'defined' ), '$obj->undef_field is a Module::Generic::Scalar object' );
    # isa_ok( $obj->undef_field, 'Module::Generic::Scalar', 'Undefined value returns scalar object' );
    is( $obj->undef_field, undef, 'Undefined value returns undef' );
    # ok( !exists( $obj->{_data}->{invalid_method} ), 'Invalid method name ignored' );
    ok( !$obj->can( '10invalid_method' ), 'Invalid method name ignored' );
    ok( $obj->can( 'invalid_method' ), 'Modified method name acceptable' );
    isa_ok( $obj->nested_deep, 'Module::Generic::Dynamic', 'Deeply nested hash creates object' );
    is( $obj->nested_deep->level1->level2->level3, 'deep', 'Deeply nested method works' );
};

subtest 'serialization' => sub
{
    my $obj = Module::Generic::Dynamic->new({
        name => 'Test',
        metadata => { sku => 'XYZ789' },
        tags => [qw( product test )],
        created => '2023-11-18T10:30:00',
        is_active => 1,
        ip_address => '192.168.1.1',
        version => '1.2.3',
        file => './config.ini',
    });
    my $data = $obj->serialise( $obj, serialiser => 'Storable::Improved' );
    my $new_obj = Module::Generic->new->deserialise( data => $data, serialiser => 'Storable::Improved' );
    isa_ok( $new_obj, 'Module::Generic::Dynamic', 'Deserialised object is correct' );
    is( $new_obj->name, 'Test', 'Deserialised scalar preserved' );
    isa_ok( $new_obj->metadata, 'Module::Generic::Dynamic', 'Deserialised nested hash are Module::Generic::Dynamic objects' );
    is( $new_obj->metadata->sku, 'XYZ789', 'Deserialised nested object preserved' );
    isa_ok( $new_obj->tags, 'Module::Generic::Array', 'Deserialised array preserved' );
    is( $new_obj->tags->length, 2, 'Deserialised array length correct' );
    isa_ok( $new_obj->created, 'DateTime', 'Deserialised datetime preserved' );
    is( $new_obj->created->year, 2023, 'Deserialised datetime year correct' );
    isa_ok( $new_obj->is_active, 'Module::Generic::Boolean', 'Deserialised boolean preserved' );
    is( $new_obj->is_active, 1, 'Deserialised boolean value correct' );
    isa_ok( $new_obj->ip_address, 'Module::Generic::Scalar', 'Deserialised IP preserved' );
    is( $new_obj->ip_address, '192.168.1.1', 'Deserialised IP value correct' );
    isa_ok( $new_obj->version, 'version', 'Deserialised version preserved' );
    is( $new_obj->version->stringify, '1.2.3', 'Deserialised version value correct' );
    isa_ok( $new_obj->file, 'Module::Generic::File', 'Deserialised file preserved' );
    is( $new_obj->file->basename, 'config.ini', 'Deserialised file basename correct' );
};

subtest 'error handling' => sub
{
    # Test invalid hash ref input
    my $obj;
    {
        local *STDERR;
        open my $fh, '>', \my $stderr;
        local *STDERR = $fh;
        $obj = Module::Generic::Dynamic->new( 'invalid' );
        like( $stderr, qr/Parameter provided is not an hash reference/, 'Non-hash input triggers warning' );
    }
    ok( $obj, 'Object created despite invalid input' );

    # Test thread warning
    SKIP:
    {
        skip( "No threads support in this Perl", 2 ) unless( $Config{usethreads} );
        require threads;
        my $stderr;
        {
            local $SIG{__WARN__} = sub{ $stderr = join( '', @_ ); };
            threads->create(sub
            {
                Module::Generic::Dynamic->new({ name => 'Test' });
                like( $stderr, qr/Module::Generic::Dynamic is not thread-safe/, 'Thread usage triggers warning' );
            })->join;
        }
    }

    # Actually, due to the dynamic nature of Module::Generic::Dynamic, AUtOLOAD will create method on the fly, so there is never a failing method call.
    # Test invalid method call
    # $obj = Module::Generic::Dynamic->new;
    # ok( !eval{ $obj->invalid_method_name(123); }, 'Invalid method name fails safely' );
};

done_testing();

__END__

