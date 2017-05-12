#!/usr/bin/perl
#
# Copyright (c) 2003 William Goedicke. All rights reserved. This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use PeopleSoft::EPM;
use PeopleSoft;
use strict;
use Data::Dumper;

my $load_seq = [];
my $MS = { foo => 1 };
my $SS = { foo => 1 };
my $TS = { foo => 1 };
my $LS = { foo => 1 };

my ( $aref, $mapping, $i );
@{$aref} = qw( HR80 );

my $dbh = get_dbh('sysadm','sysadm','eproto88');

( $MS, $SS, $TS, $LS ) = get_mapping_structs( $aref, $dbh );

$dbh->disconnect;

foreach $mapping ( keys(%{$MS}) ) {
  recurse( $mapping, $load_seq, $MS, $SS, $TS );
}

for ( $i=0 ; $i <= $#{$load_seq} ; $i++ ) {
  if ( $$load_seq[$i] =~ m/No Mapping/ ) { next; }
  if ( defined $MS->{$$load_seq[$i]}{USED} ) {
    $$load_seq[$i] = $$load_seq[$i] . " 1 1";
  }
  else {
    $$load_seq[$i] = $$load_seq[$i] . " 1 0";
  }
}

print join "\n", @{$load_seq}, "\n";
