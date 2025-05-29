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

subtest 'dynamic class creation' => sub
{
    my $obj = Module::Generic::Dynamic->new({
        name => 'Test Product',
        metadata => { sku => 'ABC123', price => 99.99 },
        tags => [qw( product test )],
        created => '2023-11-18',
    });
    ok( $obj, 'Object created successfully' );
    is( $obj->name, 'Test Product', 'Scalar method works' );
    isa_ok( $obj->metadata, 'Module::Generic::Dynamic', 'Hash method creates object' );
    is( $obj->metadata->sku, 'ABC123', 'Nested method works' );
    isa_ok( $obj->tags, 'Module::Generic::Array', 'Array method returns array object' );
    is( $obj->created->year, 2023, 'Datetime method works' );
};

subtest 'AUTOLOAD' => sub
{
    my $obj = Module::Generic::Dynamic->new;
    $obj->url( 'https://example.com' );
    isa_ok( $obj->url, 'URI', 'AUTOLOAD creates uri method' );
    $obj->id( 'c47e1113-8336-4437-ba20-54f8cd0afb18' );
    isa_ok( $obj->id, 'Module::Generic::Scalar', 'AUTOLOAD creates uuid method' );
};

subtest 'serialization' => sub
{
    my $obj = Module::Generic::Dynamic->new({
        name => 'Test',
        metadata => { sku => 'XYZ789' },
    });
    my $data = $obj->serialise( $obj, serialiser => 'Storable::Improved' );
    my $new_obj = Module::Generic->new->deserialise( data => $data, serialiser => 'Storable::Improved' );
    isa_ok( $new_obj, 'Module::Generic::Dynamic', 'Deserialized object is correct' );
    is( $new_obj->name, 'Test', 'Deserialized scalar preserved' );
    is( $new_obj->metadata->sku, 'XYZ789', 'Deserialized nested object preserved' );
};

# subtest 'threaded usage' => sub
# {
#     SKIP:
#     {
#         if( !$Config{useithreads} )
#         {
#             skip( 'Threads are not available on this system', 1 );
#         }
#         require threads;
#         threads->import;
#         my $thr = threads->create(sub
#         {
#             my $obj = Module::Generic::Dynamic->new({ name => 'Test' });
#             # Expect undef due to error
#             return( defined( $obj ) ? 0 : 1 );
#         });
#         my $result = $thr->join;
#         is( $result, 1, 'Dynamic class creation fails in thread (as expected)' );
#     }
# };

# subtest 'threaded AUTOLOAD' => sub
# {
#     SKIP:
#     {
#         if( !$Config{useithreads} )
#         {
#             skip( 'Threads are not available on this system', 1 );
#         }
#         require threads;
#         threads->import;
#         my $obj = Module::Generic::Dynamic->new;
#         ok( !$obj->can( 'test_url' ), 'test_url method does not exist before thread' );
#         my $thr = threads->create(sub
#         {
#             my $result = $obj->test_url( 'https://example.com' );
#             return( defined( $result ) ? 0 : 1 ); # Expect undef due to error
#         });
#         my $result = $thr->join;
#         is( $result, 1, 'AUTOLOAD fails in thread (as expected)' );
#     }
# };

done_testing();

__END__

