use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;
use FindBin;
use JSON;

use lib "$FindBin::Bin/lib";
use Class;

{
    package BadMethod;
    
    use Package::JSONable (
        fake => 'Str',
    );
}

{
    package BadType;
    
    use Package::JSONable (
        real => 'Fake',
    );
    
    sub real { return }
}

{
    package BadTypeRef;
    
    use Package::JSONable (
        real => [1,2,3],
    );
    
    sub real { return }
}

throws_ok(
    sub {
        BadMethod::TO_JSON;
    },
    qr/Can't locate object method "fake" via package "BadMethod"/,
    'no such method',
);

throws_ok(
    sub {
        BadType::TO_JSON;
    },
    qr/Invalid type: "Fake"/,
    'invalid type',
);

throws_ok(
    sub {
        BadTypeRef::TO_JSON;
    },
    qr/Invalid type: "ARRAY"/,
    'invalid type ref',
);

done_testing();
