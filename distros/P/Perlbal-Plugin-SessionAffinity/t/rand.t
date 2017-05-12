#!perl

# this test checks the hostname-style srand trick
# we're using

use strict;
use warnings;

use Test::More;
use Perlbal::Plugin::SessionAffinity;

my %generated = ();
my @domains   = qw<foo.com bar.org baz.net quux.info>;
my %found     = ();

foreach my $idx ( 1 .. 50 ) {
    diag("Round $idx");

    foreach my $domain (@domains) {
        my $index = Perlbal::Plugin::SessionAffinity::domain_index(
            $domain, scalar @domains
        );

        diag("Random index for $domain: $index");

        ok(
            ( $index > 0 ) && ( $index <= $#domains ),
            'Index is in the correct range',
        );

        exists $generated{$domain} or $generated{$domain} = $index;

        is(
            $index,
            $generated{$domain},
            "Index for $domain hasn't changed",
        );
    }
}

done_testing();
