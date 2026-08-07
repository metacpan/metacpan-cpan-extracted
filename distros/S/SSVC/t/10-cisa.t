#!perl

use strict;
use warnings;

use Test::More;

use_ok('SSVC::CISA');

while (my $line = <DATA>) {

    chomp($line);
    next unless length $line;

    my ($exploitation, $automatable, $technical_impact, $mission_prevalence, $public_well_being_impact, $expected)
        = split /\|/, $line;

    my $ssvc = eval {
        SSVC::CISA->new(
            exploitation             => $exploitation,
            automatable              => $automatable,
            technical_impact         => $technical_impact,
            mission_prevalence       => $mission_prevalence,
            public_well_being_impact => $public_well_being_impact,
        );
    };

    fail($@) if $@;

    is($ssvc->decision, $expected, $line) or diag explain $ssvc;

}

done_testing();

__DATA__
active|no|partial|minimal|irreversible|attend
active|no|partial|minimal|minimal|track
active|no|partial|minimal|material|track
active|no|total|minimal|irreversible|act
active|no|total|minimal|minimal|track
active|no|total|minimal|material|attend
active|yes|partial|minimal|irreversible|act
active|yes|partial|minimal|minimal|attend
active|yes|partial|minimal|material|attend
active|yes|total|minimal|irreversible|act
active|yes|total|minimal|minimal|attend
active|yes|total|minimal|material|act
none|no|partial|minimal|irreversible|track
none|no|partial|minimal|minimal|track
none|no|partial|minimal|material|track
none|no|total|minimal|irreversible|track*
none|no|total|minimal|minimal|track
none|no|total|minimal|material|track
none|yes|partial|minimal|irreversible|attend
none|yes|partial|minimal|minimal|track
none|yes|partial|minimal|material|track
none|yes|total|minimal|irreversible|attend
none|yes|total|minimal|minimal|track
none|yes|total|minimal|material|track
poc|no|partial|minimal|irreversible|track*
poc|no|partial|minimal|minimal|track
poc|no|partial|minimal|material|track
poc|no|total|minimal|irreversible|attend
poc|no|total|minimal|minimal|track
poc|no|total|minimal|material|track*
poc|yes|partial|minimal|irreversible|attend
poc|yes|partial|minimal|minimal|track
poc|yes|partial|minimal|material|track
poc|yes|total|minimal|irreversible|attend
poc|yes|total|minimal|minimal|track
poc|yes|total|minimal|material|track*
