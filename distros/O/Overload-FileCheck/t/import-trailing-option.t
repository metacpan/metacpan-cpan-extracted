#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

# Load the module without calling import so we can test import() directly.
require Overload::FileCheck;

# Verify that a trailing dash-option without a CODE ref in the import list
# produces a clear error instead of being silently discarded.

like(
    dies {
        Overload::FileCheck->import( '-e' => sub { 1 }, '-f' );
    },
    qr/Missing CODE ref for mock '-f'/,
    'trailing dash-option without value croaks'
);

# Clean up the -e mock from the partial import above (it succeeded before -f error).
Overload::FileCheck::unmock_all_file_checks();

like(
    dies {
        Overload::FileCheck->import('-z');
    },
    qr/Missing CODE ref for mock '-z'/,
    'single dash-option without value croaks'
);

# Valid imports should still work fine.
ok(
    lives {
        Overload::FileCheck->import(':check');
    },
    'exporter tag imports normally'
);

done_testing;
