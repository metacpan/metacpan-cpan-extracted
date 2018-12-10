#!/usr/bin/perl
# Use our tags
use C1;
use C2;

use 5.010;

# get the value of the tag t1, applied to attribute a1
say C1->new->_tags->{t1}{a1};

# get the value of the tag t2, applied to attribute c2
say C2->new->_tags->{t2}{c2};
