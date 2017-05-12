#!/usr/bin/perl -w
# $File: //depot/libOurNet/BBS/t/5-BBSAgent.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 1 $ $DateTime: 2002/06/11 15:35:12 $

use strict;
my ($addr, %sites);

BEGIN {
    %sites = map { 
        open(my $SITE, $_) or die "cannot open $_";
	scalar <$SITE>;
        chomp($addr = <$SITE>);
        (substr($_, rindex($_, '/') + 1) => (split(':', $addr))[0]);
    } map {
        glob("$_/OurNet/BBSAgent/*.bbs")
    } reverse @INC;
}

use Test::More (%sites ? (tests => keys(%sites) * 2) : skip_all => 'OurNet::BBSAgent not available');

# Load BBS
use OurNet::BBS;
use Socket 'inet_aton';

$OurNet::BBS::DEBUG = $OurNet::BBS::DEBUG++; # shut up warnings

print << "." unless @ARGV;
# note: when called with an argument, this script will
#       also test login + sanity for each .bbs files.
.

while (my ($site, $addr) = each %sites) {
    my $BBS = OurNet::BBS->new({
	backend => 'BBSAgent',
	bbsroot => $site
    });

    is(ref($BBS), $BBS->module('BBS'), "load: $site");

    SKIP: {
	skip "no \@ARGV, skips sanity test", 1
	    unless ($ARGV[0]);

	skip "not connected to $addr", 1
	    unless (defined inet_aton($addr));

        my $result = eval {
	    $BBS->sanity_test(!$ARGV[0])
	};

	ok($result, "connect: $site");
    }
}

__END__
