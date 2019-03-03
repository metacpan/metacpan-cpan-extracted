#!perl

use strict;
use warnings;

use Test::More;
use Test::DNS;

plan skip_all => 'requires AUTHOR_TESTING' unless $ENV{'AUTHOR_TESTING'};

my $dns = Test::DNS->new();

# TXT in hash
$dns->is_txt( {
    'perl.org' => [
        'v=spf1 include:develooper.com include:pobox.com ~all',
        '_globalsign-domain-verification=mVYWxIl-2ab_B1yPPFxEmDCLrBcl6ucouXJOU_P0_C',
        '_globalsign-domain-verification=O60kZMoa5mBPIKKqd9FSRXcGUhU6s3rzZHzWNLAlL7',
    ],
} );

done_testing();
