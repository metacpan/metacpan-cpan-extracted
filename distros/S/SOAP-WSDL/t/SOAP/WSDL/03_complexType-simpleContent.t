use Test::More tests => 2;
use lib '../lib';
use lib 't/lib';
use lib 'lib';
use Cwd;
use File::Basename;

our $SKIP;
eval "use Test::SOAPMessage";
if ($@) {
    $SKIP = "Test::Differences required for testing. $@";
    }

use_ok qw/SOAP::WSDL/;

my $soap = SOAP::WSDL->new();


TODO: {
    local $TODO="implement <simpleContent> support";
    fail "serialize simpleContent element";
}