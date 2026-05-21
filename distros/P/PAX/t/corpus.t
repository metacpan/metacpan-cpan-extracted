use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAX::Corpus;
use PAX::Capture;
use PAX::Manifest;

my $manifest = "$FindBin::Bin/corpus.json";
my $result = PAX::Corpus->new(manifest_path => $manifest)->run;

ok($result->{passed}, 'corpus passes expected compatibility levels');
is($result->{total}, 5, 'corpus case count recorded');

my $capture = PAX::Capture->new(mode => 'live')->capture("$FindBin::Bin/fixtures/simple.pl");
my $pax_manifest = PAX::Manifest->new(capture => $capture)->to_hash;
if ($pax_manifest->{runtime}{baseline_match}) {
    is($result->{levels}{A}, 1, 'Level A aggregate recorded');
    is($result->{levels}{B}, 4, 'Level B aggregate recorded');
} else {
    is($result->{levels}{C}, 5, 'baseline mismatch aggregate recorded');
}

done_testing;

=pod

=head1 NAME

t/corpus.t - regression coverage for corpus manifest loading and grouped execution behavior

=head1 DESCRIPTION

This test exercises corpus manifest loading and grouped execution behavior. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for corpus manifest loading and grouped execution behavior. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/corpus.t

=head1 WHY IT EXISTS

PAX uses this test to keep corpus manifest loading and grouped execution behavior from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
