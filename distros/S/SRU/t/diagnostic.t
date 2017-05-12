use strict;
use warnings;
use Test::More qw( no_plan );
use SRU::Utils::XMLTest;

use_ok( 'SRU::Response::Diagnostic' );

my $d = SRU::Response::Diagnostic->new(
    uri     => 'info:srw/diagnostic/1/7',
    details => 'version',
    message => 'Version parameter missing. When you explicitly specify an explain, searchRetrieve, or scan operation you are suppose to send along a version parameter.' 
);

isa_ok( $d, 'SRU::Response::Diagnostic' );
is( $d->uri(), 'info:srw/diagnostic/1/7', 'uri()' );
is( $d->details(), 'version', 'details()' );
like( $d->message(), qr/Version parameter missing/, 'message()' );

ok( wellFormedXML( $d->asXML() ), 'asXML()' );
