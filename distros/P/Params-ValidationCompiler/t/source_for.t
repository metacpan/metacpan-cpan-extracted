use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Params::ValidationCompiler qw( source_for );

my ( $source, $env ) = source_for( params => { foo => 1 } );
like(
    $source,
    qr/exists \$args/,
    'source_for returns expected source'
);

is( $env, { '%known' => { foo => 1 } }, 'got expected environment' );

done_testing();
