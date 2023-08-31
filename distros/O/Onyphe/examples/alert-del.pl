#!/usr/bin/env perl
#
# $Id: alert-del.pl,v 4089618a5aa7 2023/03/07 13:36:19 gomor $
#
use strict;
use warnings;

my $id = shift;
die("Give id") unless defined $id;

use Data::Dumper;
use Onyphe::Api;

my $oa = Onyphe::Api->new->init;

$oa->alert_del($id);
