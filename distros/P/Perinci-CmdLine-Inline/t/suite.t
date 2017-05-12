#!perl

# run the Test::Perinci::CmdLine test suite

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::CmdLine;

pericmd_ok(
    class => 'Perinci::CmdLine::Inline',
    exclude_tags => [
         # probably won't ever be supported
        'embedded-meta',

        # probably won't be unsupported
        'completion',
        'tx',

        # already supported, but suite doesn't work yet
        'cmdline_src',

        # currently unsupported
        'config-file-sets-common-options',
        'dry-run',
        'validate-streaming-input',
        'validate-streaming-result',
        'validate-result',
    ],
);
done_testing;
