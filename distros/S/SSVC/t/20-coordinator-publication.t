#!perl

use strict;
use warnings;

use Test::More;

use_ok('SSVC::CoordinatorPublication');

while (my $line = <DATA>) {

    chomp($line);
    next unless length $line;
    next if $line =~ /^#/;

    my ($supplier_involvement, $exploitation, $public_value_added, $expected) = split /\|/, $line;

    my $ssvc = eval {
        SSVC::CoordinatorPublication->new(
            supplier_involvement => $supplier_involvement,
            exploitation         => $exploitation,
            public_value_added   => $public_value_added,
        );
    };

    fail($@) if $@;

    is($ssvc->publish, $expected, $line) or diag explain $ssvc;

}

done_testing();

__DATA__
# https://github.com/CERTCC/SSVC/blob/main/data/csv/ssvc/coordinator_publish_decision_table_1_0_0.csv
fix_ready|none|limited|dont_publish
cooperative|none|limited|dont_publish
fix_ready|public_poc|limited|dont_publish
fix_ready|none|ampliative|dont_publish
uncooperative_unresponsive|none|limited|dont_publish
cooperative|public_poc|limited|dont_publish
fix_ready|active|limited|dont_publish
cooperative|none|ampliative|dont_publish
fix_ready|public_poc|ampliative|dont_publish
fix_ready|none|precedence|publish
uncooperative_unresponsive|public_poc|limited|dont_publish
cooperative|active|limited|dont_publish
uncooperative_unresponsive|none|ampliative|dont_publish
cooperative|public_poc|ampliative|dont_publish
fix_ready|active|ampliative|publish
cooperative|none|precedence|publish
fix_ready|public_poc|precedence|publish
uncooperative_unresponsive|active|limited|publish
uncooperative_unresponsive|public_poc|ampliative|publish
cooperative|active|ampliative|publish
uncooperative_unresponsive|none|precedence|publish
cooperative|public_poc|precedence|publish
fix_ready|active|precedence|publish
uncooperative_unresponsive|active|ampliative|publish
uncooperative_unresponsive|public_poc|precedence|publish
cooperative|active|precedence|publish
uncooperative_unresponsive|active|precedence|publish
