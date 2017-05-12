#!/usr/bin/perl

=head1 NAME

tokenfilter.t - tests Plucene::Analysis::TokenFilter

=cut

use strict;
use warnings;

use Test::More tests => 2;

use_ok 'Plucene::Analysis::TokenFilter';

my $close = Plucene::Analysis::TokenFilter->close;

is $close => undef, "close does nothing";
