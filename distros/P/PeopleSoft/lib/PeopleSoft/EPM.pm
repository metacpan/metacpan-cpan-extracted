# Copyright (c) 2003 William Goedicke. All rights reserved. This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

=head1 NAME

PeopleSoft::EPM - Functions for EPM

=head1 SYNOPSIS

 use PeopleSoft::EPM;
 my $result = remove_grp($grpid,$dbh);
 my $result = create_grp(\@grp,,$grpid,$parallelflag $dbh)
 my $result = release_recsuite($rs_id, $js_id, $dbh);
 my $return = ren_repository($old_name, $new_name, $dbh);
 my ( $maps, $srcs, $tgts, $lkps ) = get_mapping_structs( $app_aref, $dbh );
 recurse( $mapping, $load_seq, $MS, $SS, $TS );
 my $mapname = get_mapname_with_target( $target_name, $dbh );
 my $mapname = get_mapname_with_source( $source_name, $dbh );

=cut

package PeopleSoft::EPM;
use DBI;
use strict;
use Data::Dumper;
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);

@EXPORT = qw(remove_grp
             create_grp
	     release_recsuite
	     get_mapping_structs
	     recurse
	     ren_repository
	     dl_run_seq
	     get_maps_aref
            );

=head1 DESCRIPTION

This module provides functionality associated with running
the data loader utility to move data from ODS staging into
the enterprise warehouse.

This module also provides a set of functions to query and manipulate
the informatica mappings.


=cut

# --------------------------------- remove_grp()

=over 3

=item remove_grp($grpid, $dbh)

The remove_grp() deletes the specified data loader map
group from the database associated with $dbh.

=back

=cut

sub remove_grp{
   my ($grpid,$dbh) = @_;
   my @sql_cmd;
   $sql_cmd[0] = "delete from ps_pf_dl_grp_defn where pf_dl_grp_id = '$grpid'";
   $sql_cmd[1] = "delete from ps_pf_dl_grp_step where pf_dl_grp_id = '$grpid'";
   foreach (@sql_cmd){
      $dbh->do($_);
      $dbh->commit;
   }
}
# --------------------------------- create_grp()

=over 3

=item create_grp(\@grp,,$grpid,$parallelflag $dbh)

create_grp creates a data loader map group including all the
maps in $maps_aref with description of $mapdesc and a group
id of $grpid.  The function will mark the group with $parallelflg, 
valid values are 'Y' and 'N'.

=back

=cut

sub create_grp{
  my ($maps_aref,$mapdesc,$grpid,$parallelflag,$dbh) = @_;
  my $counter = 1;
  
  my $sql_cmd = "insert into ps_pf_dl_grp_defn 
              (PF_DL_GRP_ID, PF_DL_GRP_STATUS, DESCR, 
               PF_DL_RUN_PARALLEL, PF_SYS_MAINT_FLG, DESCRLONG)
               values ('$grpid',' ','$mapdesc','$parallelflag',' ',
               '$mapdesc')";
  $dbh->do($sql_cmd);
  
  foreach my $mapname ( @{$maps_aref} ) {
    my $sql_cmd = 
      "INSERT INTO PS_PF_DL_GRP_STEP
        (PF_DL_GRP_ID,PF_DL_ROW_NUM,PF_ODS_SEQ,PF_DL_GRP_ENT_TYP,
        DS_MAPNAME,PF_DL_GRP_ENT_STAT,PF_DL_GRP_EXEC,DESCR,
        PROCESS_INSTANCE,TABLE_APPEND,DATAMAP_COL_SEQ,
        PF_DL_COL_DESCR,PF_SQL_ALIAS,FIELDNAME,PF_DL_LT_JOIN_OPER,
        METAVALUE,PF_SYS_MAINT_FLG,WHERECHUNK) 
        VALUES('$grpid',$counter,$counter,'M','$mapname',' ',' ',' ',
        0,' ',0,' ',' ',' ','=',' ',' ',' ')";
    $counter++;
    if ( defined $dbh->do($sql_cmd) ) { $dbh->commit; }
  }
}

#------------------------------------ release_recsuite

=over 3

=item release_recsuite( $rs_id, $js_id, $dbh )

Specifying a record suite id (e.g. 001) and a jobstream id
(e.g. PS_DL_RUN) will release the recordsuite in the database 
with handle $dbh.

=back

=cut

sub release_recsuite {
  my ( $rs_id, $js_id, $dbh ) = @_;

  my @sql_cmd = 
    ( "update ps_pf_recsuite_tbl set in_use_sw = 'N'
       where recsuite_id = '$rs_id'",

      "Update PS_PF_TEMP_REC_TBL Set PF_MERGE_FLG = 'N',
       PF_RERUN_OVERRIDE = 'N',
       PF_SELECT_WHERE = ' ',
       PF_MERGE_LOCK = 'N'
       where recsuite_id = '$rs_id'",

      "Update PS_PF_TEMP_RL_TBL 
      Set PF_RERUN_OVERRIDE = 'N' 
      where recsuite_id = '$rs_id'",

      "UPDATE PS_PF_JOBSTRM_TBL
       SET JOBSTREAM_STATUS='N',
       job_id=' ',
       business_unit=' ',
       pf_scenario_id=' ',
       run_cntl_id=' ',
       IN_USE_SW='N',
       PROCESS_INSTANCE=0
       WHERE JOBSTREAM_ID='$js_id'
       AND recsuite_id = '$rs_id'",

      "SELECT RECSUITE_ID, TO_CHAR(DTTM_STAMP,
       'YYYY-MM-DD-HH24.MI.SS.\"000000\"'), IN_USE_SW, 
       JOB_ID, PROCESS_INSTANCE, RUN_CNTL_ID, 
       PF_SPAWN_ID, PF_CHUNK_LOCK FROM PS_PF_RECSUITE_TBL
       WHERE RECSUITE_ID='$rs_id' FOR UPDATE OF IN_USE_SW" );

  foreach my $cmd ( @sql_cmd ) {
    if ( ! defined $dbh->do($cmd) ) {
      die "Uh oh!  Failed to execute $cmd\n";
    }
  }
  $dbh->commit;
}
#----------------------------------------------------

=over 3

=item get_maps_aref( $fldr_aref, $dbh )

This function returns a reference to an array that contains 
the names of all the data loader maps associated with any of
the "folders" contained in the array of the first parameter.

=back

=cut

sub get_maps_aref {
  my ( $apps, $dbh ) = @_;
  my ( $maps, @results );

  my $sql_cmd = "select ds_mapname from ps_pf_dl_map_defn where folder_name = 'HR'";

  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while( @results = $sth->fetchrow_array ) { 
    push( @{$maps}, $results[0]);
  }
  $sth->finish;

  return( $maps );
}
#------------------------------------------------------------
sub dl_run_seq {
  my ( $fldr_aref, $dbh ) = @_;
  my ( %mappings, @results, @r2, $mapnames );

  my $sql_cmd = "select ds_mapname from ps_pf_dl_map_defn ";
  if ( @{$fldr_aref} == 1 ) {
    $sql_cmd .= "where folder_name = '$$fldr_aref[0]'";
  }
  elsif ( @{$fldr_aref} > 1 ) {
    $sql_cmd .= "where folder_name = '", join "' or folder_name = '", @{$fldr_aref}, "'";
  }
  else { die "You have to supply at least one folder to dl_run_seq"; }

  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while( @results = $sth->fetchrow_array ) {     $mappings{$results[0]} = '';
    $sql_cmd = "select distinct ds_source_rec, edittable from PS_PF_DL_MAPDET_VW
                   where ds_mapname = '$results[0]' and
                   ds_source_rec not like ' ' and
	           edittable not like ' '";
    my $sth2 = $dbh->prepare($sql_cmd);
    $sth2->execute;
    while( @r2 = $sth2->fetchrow_array ) { 
      @results = @{populate_mapnames( $r2[0], 'SRC', \@results, \%mappings, $dbh)};
      @results = @{populate_mapnames( $r2[1], 'LKP', \@results, \%mappings, $dbh)};
    }
    $sth2->finish;

    $sql_cmd = "select distinct lookup_tbl from ps_pf_dl_edt_defn
                where ds_mapname = '$results[0]' 
                and lookup_tbl not like ' '";
    $sth2 = $dbh->prepare($sql_cmd);
    $sth2->execute;
    while( @r2 = $sth2->fetchrow_array ) { 
      @results = @{populate_mapnames( $r2[0], 'EDT', \@results, \%mappings, $dbh)};
    }
    $sth2->finish;
    $sql_cmd = "select distinct lookup_tbl from ps_pf_dl_trn_defn
                where ds_mapname = '$results[0]'
                and lookup_tbl not like ' '";
    $sth2 = $dbh->prepare($sql_cmd);
    $sth2->execute;
    while( @r2 = $sth2->fetchrow_array ) { 
      @results = @{populate_mapnames( $r2[0], 'TRN', \@results, \%mappings, $dbh)};
    }
    $sth2->finish;
  }
  $sth->finish;

  my ( %mn2 );

  foreach my $k ( sort keys %mappings ) {
    foreach my $type qw( SRC LKP TRN ) {
      foreach my $k2 ( keys %{$mappings{$k}{$type}} ) {
	if ( $k eq 'PERSONAL_D00' and $k2 eq 'JOB_F00' ) {next;}
	if ( defined $mappings{$k2} and $k2 ne $k ) { $mn2{$k}{$k2} = ''; }
      }
    }
  }

  return(\%mappings);

  my ( @ordered_dl_maps, $k, %done );

  foreach my $map ( sort keys %mappings ) {
    #  print "M: $map\n";
    if ( defined $done{$map} ) { next; }
    push @ordered_dl_maps, dl_recurse( $map, \%mn2, \%done, \@ordered_dl_maps );
    if ( defined $done{$map} ) { next; }
    #  print "PUSHED1: $ordered_dl_maps[-1]\n";
    push @ordered_dl_maps, $map;
    $done{$map} = 1;
    #  print "PUSHED2: $ordered_dl_maps[-1]\n";
  }

  my @uniq;
  my %seen = ();
  foreach my $item ( @ordered_dl_maps ){
    push(@uniq, $item) unless $seen{$item}++;
  }
  return(\@uniq);
}
#------------------------------------------------------------
sub dl_recurse {
  my ( $seed, $mn2, $done, $ordered_dl_maps ) = @_;

  foreach my $k ( keys %{$mn2->{$seed}} ) {
    if ( ! defined $done->{$k} ) { dl_recurse( $k, $mn2, $done, $ordered_dl_maps ); }
  }
  push @{$ordered_dl_maps}, $seed;
  $done->{$seed} = 1;
  return $seed;
}
#------------------------------------------------------------
sub populate_mapnames {
  my ( $obj_name, $obj_type, $results, $mapnames, $dbh ) = @_;
  my ( $tbl_aref, $tbl );

  print "1:$obj_name, 2:$obj_type, 3:$results, 4:$mapnames, 5:$dbh\n";

  if ( PeopleSoft::Tables::is_view("PS_$obj_name", $dbh) ) {
    print "is view\n";
    $mapnames->{$results->[0]}{VIEWS}{$obj_name} = '';
    $tbl_aref = where_from("PS_$obj_name", $dbh);
    if ( defined @{$tbl_aref} ) {
      foreach $tbl ( @{$tbl_aref} ) {
	$tbl =~ s/^PS_//;
	$mapnames->{$results->[0]}{$obj_type}{$tbl} = '';
      }
    }
  } else {
    print "0:$mapnames, 1:$results->[0], 2:$obj_type, 3:$obj_name\n";
#    $mapnames->{$results->[0]}{$obj_type}{$obj_name} = 0;
  }
}
# --------------------------------- ren_repository()

=over 3

=item ren_repository($old_name, $new_name, $dbh)

The ren_repository() function changes the name of an Informatica
repository.  It returns 1 on success and 0 on failure.

=back

=cut

sub ren_repository {
  my ( $old_name, $new_name, $dbh ) = @_;
  my ( $rec_count );

  my $sql_cmd = "select count(*) from OPB_REPOSIT";
  $sql_cmd .= " where REPOSIT_NAME = $old_name";
  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while ( ($rec_count) = $sth->fetchrow_array ) {
    if ( $rec_count != 1 ) {
      $sth->finish;
      return 0;
    }
  }
  $sth->finish;

  $sql_cmd = "select count(*) from OPB_REPOSIT_INFO";
  $sql_cmd .= " where REPOSITORY_NAME = $old_name";
  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while ( ($rec_count) = $sth->fetchrow_array ) {
    if ( $rec_count != 1 ) {
      $sth->finish;
      return 0;
    }
  }
  $sth->finish;

  $sql_cmd = "update OPB_REPOSIT";
  $sql_cmd .= " set REPOSIT_NAME = '$new_name'";
  $sql_cmd .= " where REPOSIT_NAME = '$old_name'";
  if ( ! ($sth = $dbh->prepare($sql_cmd)) ) { return 0; }
  $sth->execute;

  $sql_cmd = "update OPB_REPOSIT_INFO";
  $sql_cmd .= " set REPOSITORY_NAME = '$new_name'";
  $sql_cmd .= " where REPOSITORY_NAME = '$old_name'";
  if ( ! ($sth = $dbh->prepare($sql_cmd)) ) { return 0; }
  $sth->execute;
  $dbh->commit;
  return 1;
}

# ----------------------------------------------------------------------

=over 3

=item $mapname = get_mapname_with_target( $target_name, $dbh );

This function returns a reference to an array of map names that populate the 
table with the given name.

=back

=cut

sub get_mapname_with_target { 
  my ( $target_name, $dbh ) = @_;
  my ( @results, @maps );
  my $sql_cmd = 
    "select opb_mapping.mapping_name
     from opb_mapping, opb_widget_inst, opb_targ
     where opb_mapping.mapping_id = opb_widget_inst.mapping_id
     and opb_targ.target_id = opb_widget_inst.widget_id
     and opb_targ.target_name = '$target_name'
     and opb_widget_inst.widget_type = 2";

  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while ( ( @results ) = $sth->fetchrow_array ) {
    push @maps, $results[0];
  }
  $sth->finish;

  return \@maps;
}

# ----------------------------------------------------------------------

=over 3

=item $mapname = get_mapname_with_source( $source_name, $dbh );

This function returns a reference to an array of map names that are fed by the 
table with the given name.

=back

=cut

sub get_mapname_with_source { 
  my ( $source_name, $dbh ) = @_;
  my ( @results, @maps );
  my $sql_cmd = 
    "select opb_mapping.mapping_name
     from opb_mapping, opb_widget_inst, opb_src
     where opb_mapping.mapping_id = opb_widget_inst.mapping_id 
     and opb_widget_inst.widget_type = 1
     and opb_src.src_id = opb_widget_inst.widget_id
     and opb_src.source_name = '$source_name'";


  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while ( ( @results ) = $sth->fetchrow_array ) {
    push @maps, $results[0];
  }
  $sth->finish;

  return \@maps;
}

# ----------------------------------------------------------------------

=over 3

=item ( $maps, $srcs, $tgts, $lkps ) = get_mapping_structs( $app_aref, $dbh );

This function returns references to four seperate hashes that contain critical
dependency information regarding informatica maps.  The first (i.e. $maps) 
contains sections for: source tables, target tables, and lookups.  The other 
three are simply inversions to expedite searchs.

The function takes an array reference containing "applications" whose maps you
want to get information on and a database handle that point to the informatica
you are analyzing.

=back

=cut

sub get_mapping_structs { 
  my ( $app_aref, $dbh, $map_name ) = @_;
  my ( @results, @r2, $tbl_name, %mappings, %sources, %targets, %lookups );
  my ( $mapping, $name_clause );
  my @apps = @{$app_aref};

  if ( defined $map_name ) {
    $name_clause = "opb_mapping.mapping_name = '$map_name'";
  }
  else {
    $name_clause = "opb_mapping.mapping_name like '";
    $name_clause .= join "\%' or opb_mapping.mapping_name like '", @apps;
    $name_clause .= "\%'";
  }

  # -------------- First we push the lookups onto the mappings struct

  my $sql_cmd = 
    "select distinct opb_mapping.mapping_name, opb_widget_attr.attr_value 
     from opb_mapping, OPB_WIdget_inst, opb_widget_attr
     where ( $name_clause ) and opb_mapping.mapping_id = opb_widget_inst.mapping_id and 
      opb_widget_inst.instance_name like 'lkp\%' and 
      opb_widget_attr.attr_value not like '\%VW' and 
      opb_widget_inst.widget_id = opb_widget_attr.widget_id and 
      opb_widget_attr.attr_id = 2
      order by mapping_name";

  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while ( ( @results ) = $sth->fetchrow_array ) {
    push @{ $lookups{$results[1]} }, $results[0];
    push @{ $mappings{$results[0]}{LKPS} }, $results[1];
  }
  
  $sth->finish;

  # ------------- Next we push the sources onto mappings
  # ------------- and push mappings onto the sources struct

  $sql_cmd = 
    "select opb_mapping.mapping_name, opb_src.source_name
     from opb_mapping, opb_widget_inst, opb_src
     where ( $name_clause ) and opb_mapping.mapping_id = opb_widget_inst.mapping_id
     and opb_widget_inst.widget_type = 1
     and opb_src.src_id = opb_widget_inst.widget_id
     and opb_src.source_name not like '%ETL%'";

  $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while ( ( @results ) = $sth->fetchrow_array ) {
    push @{ $mappings{$results[0]}{SRC} }, $results[1];
    push @{ $sources{$results[1]} }, $results[0];
  }
  $sth->finish;

  # ------------- Next we push the targets onto mappings

  $sql_cmd = 
    "select opb_mapping.mapping_name, opb_targ.target_name
     from opb_mapping, opb_widget_inst, opb_targ
     where ( $name_clause ) and opb_mapping.mapping_id = opb_widget_inst.mapping_id
     and opb_targ.target_id = opb_widget_inst.widget_id
     and opb_targ.target_name not like '%ETL%'
     and opb_widget_inst.widget_type = 2";

  $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while ( ( @results ) = $sth->fetchrow_array ) {
    $sql_cmd = "select count\(\*\) from $results[1]";
    my $sth2 = $dbh->prepare($sql_cmd);
    $sth2->execute;
    while ( ( @r2 ) = $sth2->fetchrow_array ) {
      $mappings{$results[0]}{COUNT} = $r2[0];
    }

    push @{ $mappings{$results[0]}{TGT} }, $results[1];
    push @{ $targets{$results[1]} }, $results[0];
  }
  $sth->finish;

  foreach $mapping ( keys %mappings ) {
    my $srcname = $mappings{$mapping}{SRC}->[-1];
    if ( defined $lookups{$srcname} ) {
      $mappings{$mapping}{USED} = 1;
    }
  }

  return ( \%mappings, \%sources, \%targets, \%lookups );
}
# ---------------------------------- Recurse %depends


=over 3

=item recurse( $mapping, $load_seq, $MS, $SS, $TS );

This function populates the array reference passed as its first
parameter with an ordered list of informatica maps.  The order is 
such that lookups and sources are run before their targets.

The following snippet shows typical usage employing the 
get_mapping_structs function described above.

@{$aref} = qw( HR80 );
( $MS, $SS, $TS, $LS ) = get_mapping_structs( $aref, $dbh );
foreach $mapping ( keys(%{$MS}) ) {
  recurse( $mapping, $load_seq, $MS, $SS, $TS );
}

=back

=cut

sub recurse {
  my ( $mapping, $load_seq, $MS, $SS, $TS ) = @_;
  my ( $lkp, $new_trgt );

  if ( defined $MS->{$mapping}{DONE} ) {
    return;
  }

  if ( ! defined $MS->{$mapping}{LKPS} or ! defined $MS->{$mapping}{LKPS}[0] ) {
    push_onto_load_seq( $MS, $load_seq, $mapping );
    return;
  }

  while ( $new_trgt = pop @{ $MS->{$mapping}{LKPS} } ) {
    if ( defined $TS->{$new_trgt}[0] ) {
      my $new_map = $TS->{$new_trgt}[0];
      recurse( $new_map, $load_seq, $MS, $SS, $TS );
    }
    elsif ( ! defined $MS->{$new_trgt}{DONE} ) {
      $MS->{$new_trgt}{DONE} = 1;
      push_onto_load_seq( $MS, $load_seq, "No mapping: $new_trgt");
    }
  }
  recurse( $mapping, $load_seq, $MS, $SS, $TS );
}
#-----------------------------------
sub push_onto_load_seq {
  my ( $MS, $load_seq, $mapping ) = @_;

  push( @{$load_seq}, $mapping );
  $MS->{$mapping}{DONE} = 1;
  return;
}
