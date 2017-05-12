#!/usr/bin/perl

use strict;
use warnings;

use lib "./lib";
use TVGuide::NL;
use Data::Dumper;

my $g = TVGuide::NL->new(debug=>0);

$g->update_schedule('ned1','rtl4');
#print $g->whats_on('ned1'), "\n";

$g->update_movies;
my @films = $g->movies_today(0,'sbs6');
print Dumper(\@films),"\n";

print Dumper($g->{schedule}),"\n";


