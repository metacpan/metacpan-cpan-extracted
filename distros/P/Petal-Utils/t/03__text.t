#!/usr/bin/perl

##
## Tests for Petal::Utils :text modifiers
##

use blib;
use strict;
#use warnings;

use Test::More qw( no_plan );

use Carp;
use t::LoadPetal;

use Petal::Utils qw( :text );

my $template = Petal->new('text.html');
my $out      = $template->process( {} );

like($out, qr/lc: all_caps/, 'lc');
like($out, qr/uc: ALL_LOWER/, 'uc');
like($out, qr/uc_first: William mckee/, 'uc_first');
