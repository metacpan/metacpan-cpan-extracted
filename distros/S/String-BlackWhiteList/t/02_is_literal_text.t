#!/usr/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use lib "$Bin/lib";
use My::Setup ':all';
use Test::More tests => 6;
my $matcher = get_matcher();

# without is_literal_text(), 'P.O.' should be interpreted as a regex, so
# 'Prof' etc. should be invalid
is_invalid($matcher, 'Prof. Dr. Foo Bar', 'Pool Street', 'P.O. Box');
$matcher->set_is_literal_text;
$matcher->update;

# with is_literal_text(), 'P.O.' should not be interpreted as a regex, so
# 'Prof' etc. should be ok.
is_valid($matcher, 'Prof. Dr. Foo Bar', 'Pool Street');
is_invalid($matcher, 'P.O. Box');
