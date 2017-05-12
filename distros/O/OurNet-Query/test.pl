#!/usr/bin/perl
use strict;
use Test;
use vars qw/%sites %found/;

# use a BEGIN block so we print our plan before MyModule is loaded

BEGIN {
    %sites = map {
        (substr($_, rindex($_, '/') + 1) => $_)
    } map {
        glob("$_/OurNet/Site/*.tt2")
    } @INC;

    plan tests => (scalar keys %sites) * 2;
}

use OurNet::Query;
use Socket 'inet_aton';

my ($query, $hits) = ('autrijus', 10);

while (my ($site, $file) = each %sites) {
    # Generate a new Query object
    ok(my $query = OurNet::Query->new($query, $hits, $file));

    if ($] < 5.006) {
	skip('tt2 query not tested on v5.5 and before.', 1);
    }
    elsif (inet_aton('google.com')) {
	# Perform a query
	my $found = $query->begin(\&callback, 30); # Timeout after 30 seconds
	ok($found);
    }
    else {
	skip('not connected to google.com.', 1);
    }
}

sub callback {
    my %entry = @_;
    my $entry = \%entry;

    unless ($found{$entry{url}}++) {
	print "[$entry->{title}]\n=> $entry->{url}\n";
    }
}

