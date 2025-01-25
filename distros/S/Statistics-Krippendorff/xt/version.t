#!/usr/bin/perl
use warnings;
use strict;
use Test2::V0;

use Statistics::Krippendorff ();

plan(3);

my $code_version = $Statistics::Krippendorff::VERSION;
ok($code_version, 'version set');

ok(open(my $source, '<', $INC{'Statistics/Krippendorff.pm'}),
   'open the source');

my $in_version;
while (<$source>) {
    if (/^=head1 VERSION/) {
        $in_version = 1;
    } elsif (/^=head1/) {
        undef $in_version;
    }
    if ($in_version && /^Version ([0-9._]+)/) {
        is($code_version, $1, 'pod version');
    }
}
