use strict;
use warnings;
use utf8;

use Test::More;
use Nephia::Core;

subtest 'use and new' => sub {
    eval 'use Nephia::Plugin::Teng';
    pass;

    my $tp = Nephia::Plugin::Teng->new;
    isa_ok $tp, 'Nephia::Plugin::Teng';
};

done_testing;
