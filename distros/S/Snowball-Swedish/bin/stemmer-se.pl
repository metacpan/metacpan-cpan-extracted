#!/usr/bin/perl
# $Id: stemmer.pl,v 1.1 2007/05/07 12:01:14 ask Exp $
# $Source: /opt/CVS/SeSnowball/examples/stemmer.pl,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/05/07 12:01:14 $
use strict;
use warnings;
use Lingua::Stem::Snowball::Se;
use vars qw($VERSION);
$VERSION = 1.2;

my $stemmer = Lingua::Stem::Snowball::Se->new(use_cache => 1);
while (my $line = <>) {
	chomp $line;
	foreach my $word ((split m/\s+/xms, $line)) {
		my $stemmed = $stemmer->stem($word);
		print "$stemmed\n";
	}
}
