use Test::More;
use strict;

eval "use Test::Signature";

if ($@) {
        plan skip_all => "Test::Signature required for testing SIGNATURE";
} else {
        Test::Signature->import;
        
        plan tests => 1;

        signature_ok();

}

