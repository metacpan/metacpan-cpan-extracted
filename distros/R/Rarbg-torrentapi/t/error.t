use strict;
use Test::More;
use JSON;

BEGIN {
    use_ok('Rarbg::torrentapi::Error');
}

# Testing Rarbg::torrentapi::Error methods and attributes
can_ok( 'Rarbg::torrentapi::Error', ('new') );
can_ok( 'Rarbg::torrentapi::Error', qw( error error_code ) );
my $error_msg = <<ERR;
{
    "error": "No results found",
    "error_code": 20
}
ERR
my $error_res = decode_json($error_msg);
my $error     = Rarbg::torrentapi::Error->new($error_res);

ok( $error->error_code == 20, 'Error code check' );
is( $error->error, 'No results found', 'Error message check' );

done_testing;
