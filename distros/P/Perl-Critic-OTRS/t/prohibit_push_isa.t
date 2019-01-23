#!/usr/bin/env perl

use strict;
use warnings;

use Perl::Critic;
use Perl::Critic::Utils qw{ :severities };
use Test::More;

use constant POLICY => 'Perl::Critic::Policy::OTRS::ProhibitPushISA';

diag 'Testing *::ProhibitPushISA version ' . POLICY->VERSION();

is_deeply [ POLICY->default_themes ], [qw/otrs/];

is POLICY->default_severity, $SEVERITY_HIGHEST, 'Check default severity';

is_deeply
    [ POLICY->applies_to ],
    [ "PPI::Token::Word" ],
    'Check node names this policy applies to';

done_testing();
