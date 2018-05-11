#!/usr/bin/env perl

use strict;

BEGIN {
    use Serge::Sync::Plugin::TranslationService::zanata;
}

use Test::More;

ok(1, "default check");

done_testing();