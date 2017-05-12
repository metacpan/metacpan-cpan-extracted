#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
plan skip_all => 'these tests are for authors only' unless
        $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 4;
pod_coverage_ok(
        "POE::Component::IKC::Responder",
        { also_private => [ 
                    qr/^(DEBUG|do_you_have|inform_monitors|post2|raw_message|register_channel|remote_error|request|sig_INT|channel_error)$/
                ], 
        },
        "POE::Component::IKC::Responder, ignoring private functions",
);

pod_coverage_ok(
        "POE::Component::IKC::Client",
        { also_private => [ 
                    qr/^(DEBUG|connected|error|shutdown)$/
                ], 
        },
        "POE::Component::IKC::Client, ignoring private functions",
);

pod_coverage_ok(
        "POE::Component::IKC::Server",
        { also_private => [ 
                    qr/^(sig|DEBUG)_.+$/,
                    qr/^(DEBUG|WSAEAFNOSUPPORT|accept|check_kernel|error|fork|retry|rogues|waste_time)$/
                ], 
        },
        "POE::Component::IKC::Server, ignoring private functions",
);

pod_coverage_ok(
        "POE::Component::IKC::ClientLite",
        { also_private => [ 
                    qr/^(DEBUG|spawn)$/
                ], 
        },
        "POE::Component::IKC::ClientLite, ignoring private functions",
);

