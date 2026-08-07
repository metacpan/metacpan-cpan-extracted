#!perl

use strict;
use warnings;

use Test::More;

use_ok('SSVC::Deployer');

while (my $line = <DATA>) {

    chomp($line);
    next unless length $line;
    next if $line =~ /^#/;

    my ($exploitation, $system_exposure, $automatable, $safety_impact, $mission_impact, $expected) = split /\|/, $line;

    my $ssvc = eval {
        SSVC::Deployer->new(
            exploitation    => $exploitation,
            system_exposure => $system_exposure,
            automatable     => $automatable,
            safety_impact   => $safety_impact,
            mission_impact  => $mission_impact,
        );
    };

    fail($@) if $@;

    is($ssvc->decision, $expected, $line) or diag explain $ssvc;

}

done_testing();

# https://github.com/CERTCC/SSVC/blob/main/data/csv/ssvc/human_impact_1_0_0.csv
# https://github.com/CERTCC/SSVC/blob/main/data/csv/ssvc/deployer_patch_application_priority_1_0_0.csv
__DATA__
none|small|no|negligible|degraded|defer
none|small|no|negligible|mef_failure|defer
none|small|no|critical|mef_support_crippled|scheduled
none|small|no|catastrophic|degraded|scheduled
none|small|yes|negligible|degraded|defer
none|small|yes|negligible|mef_failure|scheduled
none|small|yes|critical|mef_support_crippled|scheduled
none|small|yes|catastrophic|degraded|scheduled
none|controlled|no|negligible|degraded|defer
none|controlled|no|negligible|mef_failure|scheduled
none|controlled|no|critical|mef_support_crippled|scheduled
none|controlled|no|catastrophic|degraded|scheduled
none|controlled|yes|negligible|degraded|scheduled
none|controlled|yes|negligible|mef_failure|scheduled
none|controlled|yes|critical|mef_support_crippled|scheduled
none|controlled|yes|catastrophic|degraded|scheduled
none|open|no|negligible|degraded|defer
none|open|no|negligible|mef_failure|scheduled
none|open|no|critical|mef_support_crippled|scheduled
none|open|no|catastrophic|degraded|scheduled
none|open|yes|negligible|degraded|scheduled
none|open|yes|negligible|mef_failure|scheduled
none|open|yes|critical|mef_support_crippled|scheduled
none|open|yes|catastrophic|degraded|out_of_cycle
public_poc|small|no|negligible|degraded|defer
public_poc|small|no|negligible|mef_failure|scheduled
public_poc|small|no|critical|mef_support_crippled|scheduled
public_poc|small|no|catastrophic|degraded|scheduled
public_poc|small|yes|negligible|degraded|scheduled
public_poc|small|yes|negligible|mef_failure|scheduled
public_poc|small|yes|critical|mef_support_crippled|scheduled
public_poc|small|yes|catastrophic|degraded|scheduled
public_poc|controlled|no|negligible|degraded|defer
public_poc|controlled|no|negligible|mef_failure|scheduled
public_poc|controlled|no|critical|mef_support_crippled|scheduled
public_poc|controlled|no|catastrophic|degraded|scheduled
public_poc|controlled|yes|negligible|degraded|scheduled
public_poc|controlled|yes|negligible|mef_failure|scheduled
public_poc|controlled|yes|critical|mef_support_crippled|scheduled
public_poc|controlled|yes|catastrophic|degraded|out_of_cycle
public_poc|open|no|negligible|degraded|scheduled
public_poc|open|no|negligible|mef_failure|scheduled
public_poc|open|no|critical|mef_support_crippled|scheduled
public_poc|open|no|catastrophic|degraded|out_of_cycle
public_poc|open|yes|negligible|degraded|scheduled
public_poc|open|yes|negligible|mef_failure|scheduled
public_poc|open|yes|critical|mef_support_crippled|out_of_cycle
public_poc|open|yes|catastrophic|degraded|out_of_cycle
active|small|no|negligible|degraded|scheduled
active|small|no|negligible|mef_failure|scheduled
active|small|no|critical|mef_support_crippled|out_of_cycle
active|small|no|catastrophic|degraded|out_of_cycle
active|small|yes|negligible|degraded|scheduled
active|small|yes|negligible|mef_failure|out_of_cycle
active|small|yes|critical|mef_support_crippled|out_of_cycle
active|small|yes|catastrophic|degraded|out_of_cycle
active|controlled|no|negligible|degraded|scheduled
active|controlled|no|negligible|mef_failure|scheduled
active|controlled|no|critical|mef_support_crippled|out_of_cycle
active|controlled|no|catastrophic|degraded|out_of_cycle
active|controlled|yes|negligible|degraded|out_of_cycle
active|controlled|yes|negligible|mef_failure|out_of_cycle
active|controlled|yes|critical|mef_support_crippled|out_of_cycle
active|controlled|yes|catastrophic|degraded|out_of_cycle
active|open|no|negligible|degraded|scheduled
active|open|no|negligible|mef_failure|out_of_cycle
active|open|no|critical|mef_support_crippled|out_of_cycle
active|open|no|catastrophic|degraded|immediate
active|open|yes|negligible|degraded|out_of_cycle
active|open|yes|negligible|mef_failure|out_of_cycle
active|open|yes|critical|mef_support_crippled|immediate
active|open|yes|catastrophic|degraded|immediate
