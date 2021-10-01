#!perl

# run the Test::Perinci::CmdLine test suite

# put pragmas + test modules (sorted alphabetically) here
use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Perinci::CmdLine;

# put other modules here
pericmd_ok(
    class => 'Perinci::CmdLine::Lite',
    exclude_tags => [
        'tx',
        'validate-streaming-input',
        'validate-result',
        'validate-streaming-result',
    ],
);
done_testing;
