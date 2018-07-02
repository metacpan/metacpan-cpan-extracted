use strict;
use warnings;

use Test::More;

# try LGP2 license

my $class = 'Software::LicenseMoreUtils';
require_ok($class);

foreach my $short (qw/GPL-2 LGPL-2 Apache_2_0 Artistic_1_0/) {
    my $license = $class->new_from_short_name({
        short_name => $short,
        holder => 'X. Ample'
    });

    if ($license->distribution eq 'debian') {
        like($license->summary_or_text, qr/common-licenses/i, "$short summary found");
    }
}

my %no_summary = (
    'Expat' => qr/substantial/i,
    'BSD-3-clause' => qr/The \(three-clause\) BSD License/,
);

foreach my $short (sort keys %no_summary) {
    my $license = $class->new_from_short_name({
        short_name => $short,
        holder => 'X. Ample'
    });

    like($license->summary_or_text, $no_summary{$short}, "$short license text found");
}

done_testing;
