#!perl

use strict;

use Test::More;
use Test::Warnings;
use Test::LoadAllModules;

plan tests => 1+1;

subtest 'use_ok' => sub {
    all_uses_ok(
        search_path => 'Net::Amazon::S3',
        except => [qw/ /],
    )
};
