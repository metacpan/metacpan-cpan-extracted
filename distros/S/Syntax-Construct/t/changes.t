#!/usr/bin/perl
use warnings;
use strict;

use FindBin;
use Test::More;
use Syntax::Construct ();


unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $version = $Syntax::Construct::VERSION;
ok $version, 'version';

my $changes_file = "$FindBin::Bin/../Changes";
ok open my $CH, '<', $changes_file;

my ($found, $format) = (0, 1);
my $date_re = qr/\d{4}-\d{2}-\d{2}/;
while (<$CH>) {
    $found++ if /\Q$version\E {4}$date_re$/;
    diag($_), undef $format unless /^(?:
                                      Revision\ history\ for\ Syntax-Construct
                                      | \d \. \d{2} \ {4} $date_re
                                      | \ {8} - \ .*
                                      | \ {10} .*
                                      |
                                  )$ /x
}

is $found, 1, "$version found in changes";
ok $format, 'format';

done_testing(4);
