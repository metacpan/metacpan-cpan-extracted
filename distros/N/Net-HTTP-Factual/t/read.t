use Test::More;
use strict;
use warnings;

use_ok('Net::HTTP::Factual');
my $factual = Net::HTTP::Factual->new();

my $output = eval { $factual->client->read(
    api_key => 'S8bAIJhnEnVp05BmMBNeI17Kz3waDgRYU4ykpKU2MVZAMydjiuy88yi1vhBxGsZC',
    table_id => 'EZ21ij',
)};
SKIP: {
    skip "v2 authentication deprecated", 5 if ( $@ && !$output);
    is( $output->status, 200 );
    is( ref $output->body, 'HASH' );
    is( ref $output->body->{response}->{data}, 'ARRAY', 'json decoded body to array' );
    is( @{$output->body->{response}->{data}}, 20, '20 items in array' );

    my ( $status, $headers, $data ) = @$output;
    is ( $status, 200 ) or
        diag explain { headers => $headers, data => $data };
}

done_testing;
