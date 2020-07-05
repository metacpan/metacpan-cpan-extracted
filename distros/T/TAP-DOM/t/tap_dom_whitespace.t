#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap_whitespace.tap") or die "Cannot read t/some_tap_whitespace.tap";
        $tap = <TAP>;
        close TAP;
}

my $dom1 = TAP::DOM->new(tap => $tap);
my $dom2 = TAP::DOM->new(tap => $tap, trim_fieldvalues => 1);

# ==================== Key/Values ====================

# 1 - no value trimming
is ($dom1->{document_data}{'linux-cmdline-bmk.fast'}, "1",  "no value whitespace trimming by default");
is ($dom1->{document_data}{'foo'}, "bar",  "no leading whitespace by default");

# 2 - value trimming
is ($dom2->{document_data}{'linux-cmdline-bmk.fast'}, '1',   "value whitespace trimming - 1");
is ($dom2->{document_data}{'foo'},                    "bar", "value whitespace trimming - 2");

done_testing();
