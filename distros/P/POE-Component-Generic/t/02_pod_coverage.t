#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 4;
pod_coverage_ok(
        "POE::Component::Generic",
        { also_private => [ 
                    qr/^(DEBUG|OOB_response|new|process_requests|response)$/
                ], 
        },
        "POE::Component::Generic, ignoring private functions",
);

pod_coverage_ok(
        "POE::Component::Generic::Object",
        { also_private => [ qr/^(DEBUG|new)$/ ], 
        },
        "POE::Component::Generic::Object, ignoring private functions",
);

pod_coverage_ok(
        "POE::Component::Generic::Child",
        { also_private => [ qr/^./, ], 
        },
        "POE::Component::Generic::Child, ignoring private functions",
);

pod_coverage_ok(
        "POE::Component::Generic::Net::SSH2",
        { also_private => [ qr/^(DEBUG|spawn|new)$/ ], 
        },
        "POE::Component::Generic::Net::SSH2, ignoring private functions",
);

