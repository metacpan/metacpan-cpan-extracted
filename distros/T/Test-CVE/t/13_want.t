#!/usr/bin/perl

use 5.014000;
use warnings;

use Test::More;
use Test::CVE;

ok (my $cve = Test::CVE->new (want => "Test::More"));
my @want = map { s/-/::/gr } @{$cve->{want}};
is_deeply (\@want, [ "Test::More" ]);
$cve->want ($_) for qw( Test::More ExtUtils-MakeMaker );
   @want = map { s/-/::/gr } @{$cve->{want}};
is_deeply (\@want, [ "Test::More", "ExtUtils::MakeMaker" ]);

done_testing;
