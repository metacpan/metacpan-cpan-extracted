package Mysql::DBLink;

use 5.014002;
use strict;
use warnings;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mysql::DBLink ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.05';

sub new {
    my $class = shift;
    my $dbhandle = shift;
    my $self = bless({ }, $class);
    $self->{db} = $dbhandle;
    return $self;
}


sub bldLinker{
    my $self = shift;
    my ($args) = @_;
    my $db = $self->{db};
    my $verbose = $args->{verbose} || 0;
    print "bldLinker Parms:\n", Dumper($args), "\n" if ($verbose);
    my $ftable = $args->{from_table};
    my $ttable = $args->{to_table};
    my $action = $args->{action};
    my $lnkt = $ftable . '_' . $ttable . '_lnk';
    my $create_ltable = qq{
        CREATE TABLE $lnkt (
            id int(10) unsigned NOT NULL auto_increment,
            frm_id int(10) unsigned NOT NULL,
            to_id int(10) unsigned NOT NULL,
            PRIMARY KEY  (id) ) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
        };

    my @tables = $db->tables();
    if ($action eq 'create'){
        if (!(grep /$lnkt/, @tables)){
            $db->do($create_ltable) or die "could not do $create_ltable - $DBI::errstr";
        }
    } elsif ($action eq 'drop'){
        if ((grep /$lnkt/, @tables)){
            $db->do(qq!drop table $lnkt!) or die "could not do drop of $lnkt table - $DBI::errstr";
        }
    } elsif ($action eq 'get_name'){
        if ((grep /$lnkt/, @tables)){
            return ($lnkt);
        } else {
            return (0);
        }
    }
}


sub handleLinker{
    my $self = shift;
    my ($args) = @_;

    my $verbose = $args->{verbose} || 0;
    print "handleLinker Parms:\n", Dumper($args), "\n" if ($verbose);

    my $db = $self->{db};
    my ($db_action,$return_records);

    my $lnkt = $args->{link_table};

    my ($from_table, $to_table, $tmp) = split /\_/, $lnkt;

    my $action = $args->{action};
    my $from_id = $args->{from_id} || 0;
    my $to_id = $args->{to_id} || 0;
    my $sfield = $args->{sfield} || '';
    my $svalue = $args->{svalue} || '';

    ### sql statements #####

    my $del_link = qq!delete from $lnkt where frm_id = $from_id and to_id = $to_id!;
    my $insert_link = qq!insert into $lnkt values (0, $from_id, $to_id)!;
    my $select_rows = qq! select * from $lnkt where frm_id = $from_id and to_id = $to_id!;
    my $select_from_id = qq! select * from $lnkt where frm_id = $from_id!;
    if ($action eq 'get_lnk_records'){  # get a hash of linked records with from_id -> series of to_id and associated table
        if ($from_id && (!$sfield && !$svalue) ){
            $db_action = $db->prepare($select_from_id);
            $db_action->execute or die "could not do select_from_id: $select_from_id - $DBI::errstr";;
            while (my $rc = $db_action->fetchrow_hashref){
                my $sel = qq! select * from $to_table where id = $rc->{to_id} !;
                my $dba = $db->prepare($sel);
                $dba->execute;
                my $rc1 = $dba->fetchrow_hashref;
                push @{$return_records}, $rc1;
            }
            $db_action->finish;
            return ($return_records);

        }
        if ( $sfield && $svalue && $from_id ){
            $db_action = $db->prepare($select_from_id);
            $db_action->execute or die "could not do select_from_id: $select_from_id - $DBI::errstr";;
            while (my $rc = $db_action->fetchrow_hashref){
                my $sel = qq! select * from $to_table where id = $rc->{to_id}!;
                my $dba = $db->prepare($sel);
                $dba->execute;
                my $rc1 = $dba->fetchrow_hashref;
                if ($rc1->{$sfield} eq $svalue){
                    push @{$return_records}, $rc1;
                }
            }
            $db_action->finish;
            return ($return_records);

        }
    } elsif ($action eq 'islinked'){
        if ( $from_id && $to_id){
            $db_action = $db->prepare($select_rows);
            $db_action->execute or die "could not do select_from_id: $select_from_id - $DBI::errstr";;
            return ($db_action->rows);
        }
    } elsif ($action eq 'add'){   #   add new link records to table
        $db_action = $db->prepare($select_rows);
        $db_action->execute or die "could not do select_from_id: $select_from_id - $DBI::errstr";;
        my $chk_rows = $db_action->rows;
        unless ($chk_rows){
            $db->do($insert_link) or die "could not do $insert_link on $lnkt table - $DBI::errstr";
        }
    } elsif ($action eq 'delete'){  # delete link records from table
        $db_action = $db->prepare($select_rows);
        $db_action->execute or die "could not do select_from_id: $select_from_id - $DBI::errstr";;
        my $chk_rows = $db_action->rows;
        if ($chk_rows){
           $db->do($del_link) or die "could not do $del_link on $lnkt table - $DBI::errstr";
        }
        return 0;
    }
}




sub updateAdd{
    my ($self, $args) = @_;
    my $verbose = $args->{verbose} || 0;
    print "updateAdd Parms:\n", Dumper($args), "\n" if ($verbose);
    if (!$args->{action}){
        print "Need to have an action\n"; 
        return 0;
    }
    if (!$args->{table}){
        print "Need to have a table\n";
        return 0;
    }
    my ($add_id);
    if ($args->{action} eq 'update'){
        $self->update_record($self->{db},$args->{table},$args->{update_id},$args->{values},$verbose,$args->{id_field});
    } else {
        $add_id = $self->add_record($self->{db},$args->{table},$args->{values},$verbose);
    }
    return ($add_id);
}
1;



####################### Internal routines ######################

sub add_record{ 
    my ($self,$db,$table, $h, $verbose) = @_;
    my $fields;
    my $values;
    foreach my $key ( keys %{$h} ){
        next if (!$key);
        next if ($key =~ /^\d/);
        $fields .= "$key,";
        my $v = $db->quote($h->{$key});
        $values .= "$v,";
    }

    $fields =~ s/,$//;
    $values =~ s/,$//;

	my $sql = qq! insert into $table ( $fields ) values ( $values)!;

    print "add_record sql: $sql\n" if ($verbose);
    my $db_action = $db->prepare($sql);
    $db_action->execute or die "could not do $sql - $DBI::errstr";
    $db_action->finish;
    $sql = qq!select last_insert_id()!;
    $db_action = $db->prepare($sql);
    $db_action->execute or die "could not do $sql - $DBI::errstr";
    my $idx = $db_action->fetchrow_array;
    return ($idx);
}


sub update_record{
    my ($self, $db, $table, $id,  $h, $verbose, $id_field) = @_;
    my $set_field = ' set ';
    foreach my $key ( keys %{$h} ){
        next if (!$key);
        next if ($key eq 'id');
        if ($id_field && ($key eq $id_field)){
            next;
        }
        unless ($h->{$key} =~ /\d+/){
            $h->{$key} = '' if (!$h->{$key});
        }
        my $v = $db->quote($h->{$key});
        $set_field .= "$key =  $v,";
    }

    $set_field =~ s/,$//;
    my $idx_field;
    if ($id_field){
        $idx_field = $id_field;
    } else {
        $idx_field = 'id';
    }
	my $sql = qq! update $table $set_field where $idx_field = $id!;
    $sql =~ s/\s+/ /g;
    print "idx_field: $idx_field ***** update_record sql: $sql\n" if ($verbose);
    $db->do($sql) or die "could not do $sql - $DBI::errstr";
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mysql::DBLink 

=head1 SYNOPSIS

  use Mysql::DBLink;


=head1 DESCRIPTION

Allows linking of two tables in a mysql database for one-to-many relationships. 
This module creates the link if it does not exist and then addes to to the link. 
It also allows retrival of data from linked table by key or by field and value.
Please Note:  Accepts database handle of already opened database as a parameter of new.
This Package requires least one key in each table that will be linked with the following configuration:

            id int(10) unsigned NOT NULL auto_increment,
            PRIMARY KEY (`id`)

Also included is a simple routine updateAdd which allows simple add/update to passed table.

=head2 EXPORT

None by default.

=head2 Modules in this package

=over 3

=item 1)

Method: new  - you must provide a valid database handle.


=back

Example:
    use Mysql::DBLinker

    my $dblinker = new Mysql::DBLinker($db);


=over 3

=item 2)

Method: bldLinker

=back

Method: bldLinker - to administer link tables between to tables for one to many relationships

Example:
    
    my $args = {
        from_table => 'from_table_name',
        to_table => 'to_table_name',
        action => 'action to be done'
    };

    $dblinker->bldLinker($args);   # action=>'create' creates frmt_tot_lnk table
    $dblinker->bldLinker($args);   # action=>'drop'  drops frmt_tot_lnk table

    my $name = $dblinker->bldLinker($args);   # action=>'get_name' returns the name of the lnk table

=over 3

=item 3)

Module: handleLinker


=back

Module: handleLinker - allows creation, deletion of linked records in the link table passed to it


  for example:
    my $args = {
        link_table => 'link_table_name',
        from_id => from_id,
        to_id => to_id,
        action => 'action to be done'
    };


  $dbliner->handleLinker(action=>'add',link_table=>$name,from_id=>20,to_id=>35);  
        will add a record with from pointer 20 and to pointer 35
  $dblinker->handleLinker(action=>'delete',link_table=>$name,from_id=>20,to_id=>35); 
        will delete the same record

  NOTE:  on add the code will not allow duplicate entries


   in addition returns an array of hash records from the to table given the from table id


   for example:

   given this link table record

		+----+--------+-------+
		| id | frm_id | to_id |
		+----+--------+-------+
		|  4 |     20 |    35 | 
		+----+--------+-------+
        
        my $args = {
            from_table => 'frmt',
            to_table => 'tot',
            action => 'get_name'
        };

        my $name = $dblinker->admLinker($args);  returns the name of the lnk table

        $args = {
            action => 'get_lnk_records',
            link_table => "$name",
            from_id => 20,
            sfield => 'firstname',
            svalue = 'joseph'
        }

        my $array_ptr = $dblinker->handleLinker($args); 

        the code will go and get all records that have a frm_id = 20 then take the to_id and read all records in the to_table
        with and id of 35, stuff them into an array of hashes and return the pointer to this array
            
        if sfield has a valid field name in the to table the svalue is search for in that field

        then code may be written in the calling script:

        for my $v (@{$array_ptr}){
            print $v->{firstname};     # if firstname is a field in the to table of course
        }



=over 3

=item 4)
updateAdd

=back

Method: updateAdd

Example:
    my $action = 'update' or 'add';
    my $id = the id of record to be updated (pr_id, p_id);
    my $id_field = the field name of the id of record to be updated);
    my $values = $d or pointer to record hash.
    my ($db_record_id) = $dblinker->updateAdd(action=>"$action",table=>"$table", update_id=>"$id",values="$d",id_field=$id_field);





=head1 AUTHOR

Joseph Norris, E<lt>jozefn@sonic.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Joseph Norris

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
