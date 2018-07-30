use strict;
use warnings;

use Test::More;
use Model::Envoy;

my %variations = (
    'DBIC'                            => 'Model::Envoy::Storage::DBIC',
    '+DBIC'                           => 'DBIC',
    'Nonsense'                        => 'Model::Envoy::Storage::Nonsense',
    '+My::Custom::NS'                 => 'My::Custom::NS',
    'Model::Envoy::Storage::FullPath' => 'Model::Envoy::Storage::FullPath',
);

while( my ( $input, $output ) = each %variations ) {
    is( Model::Envoy::_resolve_namespace($input), $output );
}

done_testing;

1;