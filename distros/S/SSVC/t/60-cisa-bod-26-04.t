#!perl

use strict;
use warnings;

use Test::More;

use_ok('SSVC::CISA::BOD2604');

while (my $line = <DATA>) {

    chomp($line);
    next unless length $line;
    next if $line =~ /^#/;

    my ($in_kev, $publicly_exposed, $automatable, $technical_impact, $expected) = split /\|/, $line;

    my $ssvc = eval {
        SSVC::CISA::BOD2604->new(
            in_kev           => $in_kev,
            publicly_exposed => $publicly_exposed,
            automatable      => $automatable,
            technical_impact => $technical_impact,
        );
    };

    fail($@) if $@;

    is($ssvc->decision, $expected, $line) or diag explain $ssvc;

}

done_testing();

__DATA__
# https://github.com/CERTCC/SSVC/blob/main/data/csv/cisa/cisa_bod_26_04_1_0_0.csv
no|no|no|partial|fix_on_system_upgrade
yes|no|no|partial|14_days
no|yes|no|partial|60_days
no|no|yes|partial|60_days
no|no|no|total|fix_on_system_upgrade
yes|yes|no|partial|14_days
yes|no|yes|partial|14_days
no|yes|yes|partial|14_days
yes|no|no|total|14_days
no|yes|no|total|14_days
no|no|yes|total|60_days
yes|yes|yes|partial|3_days
yes|yes|no|total|3_days_forensic_investigation
yes|no|yes|total|3_days_forensic_investigation
no|yes|yes|total|3_days
yes|yes|yes|total|3_days_forensic_investigation
