#!/usr/local/bin/perl
# $Revision: 1.4 $

use strict;
use Test::Assertions::TestScript;
use Pod::Hyperlink::BounceURL;
use Pod::Xhtml;

ASSERT($Pod::Hyperlink::BounceURL::VERSION, "Loaded $Pod::Hyperlink::BounceURL::VERSION");

my $lp = new Pod::Hyperlink::BounceURL;
$lp->configure( URL => '/apps/trampoline.rb?p=%s&n=%s&s=1' );
DUMP($lp);
ASSERT($lp, "created linkparser object");

my $px = new Pod::Xhtml(StringMode => 1, LinkParser => $lp);
DUMP($px);
ASSERT($px, "created pod parser object");

$px->parse_from_file( 'd.pod' );
my $xhtml = $px->asString;
$xhtml =~ s/^.*<body/<body/s;
$xhtml =~ s!</html>.*!!s;
DUMP("Made this XHTML >>>$xhtml<<<");

# Newer versions of URI::Escape escape more than what older versions did.
# Check to see if either baseline matches.  We don't care which since they are 
# functionally equivalent bits of XHTML.
my $match = "";
foreach my $f (qw/d.xhtml d.new.uriescape.xhtml/) {
    $match = $f if(EQUALS_FILE($xhtml, $f));
}
ASSERT($match, "Generated XHTML matched expected XHTML ($match)");
