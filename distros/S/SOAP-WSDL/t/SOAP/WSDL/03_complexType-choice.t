use Test::More tests => 2;
use lib '../lib';

use_ok qw/SOAP::WSDL/;

my $soap = SOAP::WSDL->new();


TODO: {
    local $TODO="implement tests";
    fail "serialize choice element";
}