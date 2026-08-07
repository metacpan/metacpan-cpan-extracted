#!perl

use strict;
use warnings;

use Test::More;

use_ok('SSVC::Supplier');

while (my $line = <DATA>) {

    chomp($line);
    next unless length $line;
    next if $line =~ /^#/;

    my ($exploitation, $automatable, $value_density, $technical_impact, $safety_impact, $expected) = split /\|/, $line;

    my $ssvc = eval {
        SSVC::Supplier->new(
            exploitation     => $exploitation,
            automatable      => $automatable,
            value_density    => $value_density,
            technical_impact => $technical_impact,
            safety_impact    => $safety_impact,
        );
    };

    fail($@) if $@;

    is($ssvc->decision, $expected, $line) or diag explain $ssvc;

}

done_testing();

__DATA__
# https://github.com/CERTCC/SSVC/blob/main/data/csv/ssvc/utility_1_0_0.csv
# https://github.com/CERTCC/SSVC/blob/main/data/csv/ssvc/supplier_patch_development_priority_1_0_0.csv
none|no|diffuse|partial|negligible|defer
none|no|diffuse|partial|marginal|scheduled
none|no|diffuse|total|negligible|scheduled
none|no|diffuse|total|marginal|out_of_cycle
none|no|concentrated|partial|negligible|scheduled
none|no|concentrated|partial|marginal|out_of_cycle
none|no|concentrated|total|negligible|scheduled
none|no|concentrated|total|marginal|out_of_cycle
none|yes|concentrated|partial|negligible|scheduled
none|yes|concentrated|partial|marginal|out_of_cycle
none|yes|concentrated|total|negligible|out_of_cycle
none|yes|concentrated|total|marginal|out_of_cycle
public_poc|no|diffuse|partial|negligible|scheduled
public_poc|no|diffuse|partial|marginal|out_of_cycle
public_poc|no|diffuse|total|negligible|scheduled
public_poc|no|diffuse|total|marginal|immediate
public_poc|no|concentrated|partial|negligible|scheduled
public_poc|no|concentrated|partial|marginal|immediate
public_poc|no|concentrated|total|negligible|out_of_cycle
public_poc|no|concentrated|total|marginal|immediate
public_poc|yes|concentrated|partial|negligible|out_of_cycle
public_poc|yes|concentrated|partial|marginal|immediate
public_poc|yes|concentrated|total|negligible|out_of_cycle
public_poc|yes|concentrated|total|marginal|immediate
active|no|diffuse|partial|negligible|out_of_cycle
active|no|diffuse|partial|marginal|immediate
active|no|diffuse|total|negligible|out_of_cycle
active|no|diffuse|total|marginal|immediate
active|no|concentrated|partial|negligible|out_of_cycle
active|no|concentrated|partial|marginal|immediate
active|no|concentrated|total|negligible|out_of_cycle
active|no|concentrated|total|marginal|immediate
active|yes|concentrated|partial|negligible|immediate
active|yes|concentrated|partial|marginal|immediate
active|yes|concentrated|total|negligible|immediate
active|yes|concentrated|total|marginal|immediate
