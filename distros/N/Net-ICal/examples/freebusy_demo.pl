#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: freebusy_demo.pl,v 1.5 2001/07/23 15:09:50 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# Demo of how to use freebusys.

use strict;

use lib '../lib';
use Net::ICal;

my $p1 = new Net::ICal::Period("19970101T120000","19970101T123000");
my $p2 = new Net::ICal::Period("19970101T133000","19970101T140000");

my $item1 = new Net::ICal::FreebusyItem($p1, (fbtype => 'BUSY'));
my $item2 = new Net::ICal::FreebusyItem($p2, (fbtype => 'BUSY'));

# TODO: we ought to be able to do things like:
my $item3 = new Net::ICal::FreebusyItem([$p1, $p2], (fbtype => 'BUSY'));
# so that both items show up on the same line. This will require C::MM voodoo;
# right now it just returns an error.

my $f = new Net::ICal::Freebusy(freebusy => [$item1, $item2], comment => 'foo');

# TODO: [DOC] why is this commented out?
#my $t = new Net::ICal::Trigger (new Net::ICal::Time ('20000101T073000'));

print $f->as_ical . "\n";
