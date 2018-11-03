use strict;
use warnings;

use Test::More;

# try LGP2 license

my $class = 'Software::LicenseMoreUtils';
require_ok($class);

subtest 'with summary' => sub {
    foreach my $short (qw/GPL-2 LGPL-2 Apache_2_0 Artistic_1_0 CC0-1.0/) {
        my $license = $class->new_from_short_name({
            short_name => $short,
            holder => 'X. Ample'
        });

        if ($license->distribution eq 'debian') {
            like($license->summary_or_text, qr/common-licenses/i, "$short summary found");
        }
        else {
            unlike($license->summary_or_text, qr/common-licenses/i, "$short summary not found");
        }
    }
};

subtest 'without summary' => sub {
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
};

subtest 'with notice and summary' => sub {
    my $short = 'GFDL_1_2';
    my $license = $class->new_from_short_name({
        short_name => $short,
        holder => 'X. Ample'
    });

    like($license->summary_or_text, qr/X. Ample/, "$short notice found");
    if ($license->distribution eq 'debian') {
        like($license->summary_or_text, qr/common-licenses/i, "$short summary found");
    }
};

subtest 'with notice and no summary' => sub {
    my $short = 'Perl_5';
    my $license = $class->new_from_short_name({
        short_name => $short,
        holder => 'X. Ample'
    });

    like($license->summary_or_text, qr/X. Ample/, "$short notice found");
    like($license->summary_or_text, qr/Terms of the Perl programming language/i, "$short full text found");
};

done_testing;
