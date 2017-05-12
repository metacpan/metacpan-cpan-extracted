#!/usr/bin/perl
#
# Copyright (c) 2003 William Goedicke. All rights reserved. This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use PeopleSoft::EPM;
use PeopleSoft;
use strict;
use Data::Dumper;

my ( $hr80_maps, @stage2_maps, @results );
my $apps_aref = [];

my @shrtgrp  = qw(POSN_HIST_RPT
                  POSN_HIST2_RPT
                  PERS_DT_FST_RPT
                  JOB_F00
                  );
my $dbh = get_dbh('sysadm','passwd','eproto88');


$hr80_maps = get_maps_aref( $apps_aref, $dbh );

foreach my $map ( @{$hr80_maps} ) {
  if ( $map ne "POSN_HIST_RPT" and $map ne "POSN_HIST2_RPT"
       and $map ne "PERS_DT_FST_RPT" and $map ne "JOB_F00" ) {
    push @stage2_maps, $map;
  }
}

remove_grp("HR80S2",$dbh);
create_grp(\@stage2_maps,"HR80S2 - stage 2 DL maps", "HR80S2", "N",$dbh);

$dbh->disconnect;
exit;
