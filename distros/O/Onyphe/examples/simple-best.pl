#!/usr/bin/env perl
#
# $Id: simple-best.pl,v 4089618a5aa7 2023/03/07 13:36:19 gomor $
#
use strict;
use warnings;

use Data::Dumper;
use Onyphe::Api;

my $oa = Onyphe::Api->new->init;

$oa->simple_best('whois', '8.8.8.8');
