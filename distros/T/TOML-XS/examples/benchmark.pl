#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;
use FindBin;

use TOML::XS;

my $has_toml_tiny = eval { require TOML::Tiny };
print "Including TOML::Tiny …$/" if $has_toml_tiny;

my @t = (
    [ small => 5000 ],
    [ large => 3 ],
);

for my $t_ar (@t) {
    my ($name, $numruns) = @$t_ar;

    my $toml_path = "$FindBin::Bin/assets/$name.toml";

    my $toml = slurp($toml_path) || do {
        require IO::Uncompress::Gunzip;

        my $gz = slurp("$toml_path.gz") or die "$toml_path.gz: $!";

        my $out;
        IO::Uncompress::Gunzip::gunzip(\$gz, \$out);

        $out;
    };

    my %benchmarks = (
        toml_xs => sub {
            my $struct = TOML::XS::from_toml($toml)->to_struct();
        },
    );

    if ($has_toml_tiny) {

        $benchmarks{'toml_tiny'} = sub {
            TOML::Tiny::from_toml($toml);
        };
    }

    print "$/$name …$/";

    Benchmark::cmpthese(
        -1,
        \%benchmarks,
    );
}

sub slurp {
    my $path = shift;

    if (open my $rfh, '<', $path) {
        return scalar do { local $/; <$rfh> };
    }

    return undef;
}

1;
