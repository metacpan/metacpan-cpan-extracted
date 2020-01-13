#!/usr/bin/perl
use warnings;
use strict;

use FindBin;
use Test::More tests => 5;
use Syntax::Construct ();


my $version = $Syntax::Construct::VERSION;
ok $version, 'version';

my $changes_file = "$FindBin::Bin/../Changes";
ok open my $CH, '<', $changes_file;

my $date_re = qr/\d{4}-\d{2}-\d{2}/;
my $version_re = qr/\d\.\d{2,3}/;
my ($found, $format) = (0, 1);
my $most_recent;
while (<$CH>) {
    $most_recent = $1 if ! $most_recent && /^($version_re)\s+$date_re$/;
    $found++ if /\Q$version\E {3,4}$date_re$/;
    diag($_), undef $format unless /^(?:
                                      Revision\ history\ for\ Syntax-Construct
                                      | $version_re \ {3,4} $date_re
                                      | \ {8} - \ .*
                                      | \ {10} .*
                                      |
                                  )$ /x
}

is $found, 1, "$version found in changes";
ok $format, 'format';
is $most_recent, $version, "in sync ($most_recent == $version)";
