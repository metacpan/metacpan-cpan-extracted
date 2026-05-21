use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAX::Capture;
use PAX::Manifest;

my $fixture = "$FindBin::Bin/fixtures/dynamic.pl";
my $capture = PAX::Capture->new(mode => 'live')->capture($fixture);
is($capture->{status}, 'ok', 'dynamic fixture captures');
ok($capture->{source_features}{string_eval}, 'string eval feature detected');
ok($capture->{source_features}{autoload}, 'AUTOLOAD feature detected');

my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
ok(@{ $manifest->{compatibility}{barriers} } >= 1, 'compatibility barriers reported');
like(
    join("\n", map { $_->{feature} } @{ $manifest->{compatibility}{barriers} }),
    qr/string_eval/,
    'string eval barrier reported',
);

done_testing;

=pod

=head1 NAME

t/compatibility.t - regression coverage for compatibility comparison reporting and mismatch explanation

=head1 DESCRIPTION

This test exercises compatibility comparison reporting and mismatch explanation. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for compatibility comparison reporting and mismatch explanation. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/compatibility.t

=head1 WHY IT EXISTS

PAX uses this test to keep compatibility comparison reporting and mismatch explanation from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
