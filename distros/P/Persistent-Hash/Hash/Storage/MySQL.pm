#!/usr/bin/perl
package Persistent::Hash::Storage::MySQL;

use strict;
use Carp qw(croak);

use DBI;
use Data::Dumper;

use vars qw($VERSION);

$VERSION = '0.1';

sub LoadObjectInfo
{
	my $classname = shift;
	my $object_package = shift;
	my $id = shift;

	croak "Attempt to call LoadObjectInfo() as a function call" if not defined $classname;
	croak "No type passed to LoadObjectInfo()" if not defined $object_package;
	croak "No id passed to LoadObjectInfo()" if not defined $id;

	my $dbh = $object_package->DatabaseHandle();
	croak "Could not obtain a database handle!" if not defined $dbh;

	my $info_table = $object_package->INFO_TABLE();

	#Load the object informations
	my $load_info_query = "SELECT 
					type,
					time_created,
					time_modified
				FROM
					$info_table
				WHERE
					id = ?";
	my $load_info_sth = $dbh->prepare_cached($load_info_query) || die "Could not prepare $load_info_query: $DBI::errstr";
	$load_info_sth->execute($id) || die "Could not execute $load_info_query: $DBI::errstr";
	
	my ($type,$time_created,$time_modified) = $load_info_sth->fetchrow_array();
	$load_info_sth->finish();

	my $object_info = undef;

	if(defined $type)
	{
		$object_info = {};
		$object_info->{type} = $type,
		$object_info->{time_created} = $time_created;
		$object_info->{time_modified} = $time_modified;
	}
	
	return $object_info;
}
		
sub LoadObjectData
{
	my $classname = shift;
	croak "Attempt to call LoadObjectData() as a function call" if not defined $classname;

	my $object = shift;
	croak "No object passed to LoadObjectData()" if not defined $object;
	croak "Wrong object side!" if tied %$object; 

	return undef if not defined $object->{_object_id};

	my $data_table = $object->DATA_TABLE();

	my $dbh = $object->DatabaseHandle;
	croak "Could not obtain database handle!" if not defined $dbh;

	#Load the object data
	my $load_data_query = "SELECT 	
					data
				FROM
					$data_table
				WHERE
					id = ?";
	my $load_data_sth = $dbh->prepare_cached($load_data_query) || die "Could not prepare $load_data_query: $DBI::errstr";
	$load_data_sth->execute($object->{_object_id}) || die "Could not execute $load_data_query: $DBI::errstr";
	my $data = $load_data_sth->fetchrow();
	$load_data_sth->finish();


	$data = eval "+"."$data";


	return $data;
}		

sub LoadObjectIndex
{
	my $classname = shift;
	croak "Attempt to call LoadObjectIndex() as a function call" if not defined $classname;

	my $object = shift;
	croak "No object passed to LoadObjectIndex()" if not defined $object;
	croak "Wrong object side!" if tied %$object;

	my $dbh = $object->DatabaseHandle();
	croak "Could not obtain database handle" if not defined $dbh;

	my $index_table = $object->INDEX_TABLE();
	my $index_fields = $object->INDEX_FIELDS();

	my $loaded_fields = {};

	if(@$index_fields)
	{
		my $load_index_query = "SELECT
					".(join ',', @$index_fields)."
				FROM
					$index_table
				WHERE
					id = ?";
		my $load_index_sth = $dbh->prepare_cached($load_index_query) || die "Could not prepare $load_index_query: $DBI::errstr";
		$load_index_sth->execute($object->{_object_id}) || die "Could not execute $load_index_query: $DBI::errstr";
		$loaded_fields = $load_index_sth->fetchrow_hashref();
		$load_index_sth->finish();
	}

	return $loaded_fields;
}	

sub DeleteObject
{
	my $classname = shift;
	my $self = shift;
	
	my $object = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $object;

	croak "Attempt to call DeleteObject() as a function call." if not defined $classname;
	croak "No object passed to DeleteObject()" if not defined $object;

	return undef if not $self->Id();

	my $dbh = $self->DatabaseHandle();
	croak "Could not obtain a database handle!" if not defined $dbh;


	my $info_table = $object->INFO_TABLE();
	my $data_table = $object->DATA_TABLE();
	my $index_table = $object->INDEX_TABLE();
	my $hash_id = $object->{_object_id};

	my $time = time();

	my $delete_info_query = "DELETE FROM $info_table WHERE id = ?";	
	my $delete_info_sth = $dbh->prepare_cached($delete_info_query) || die "Could not prepare $delete_info_query: $DBI::errstr";
	$delete_info_sth->execute($hash_id) || die "Could not execute $delete_info_query: $DBI::errstr";

	my $delete_data_query = "DELETE FROM $data_table WHERE id = ?";
	my $delete_data_sth = $dbh->prepare_cached($delete_data_query) || die "Could not prepare $delete_data_query: $DBI::errstr";
	$delete_data_sth->execute($hash_id) || die "Could not execute $delete_info_query: $DBI::errstr";

	my $delete_index_query = "DELETE FROM $index_table WHERE id = ?";
	my $delete_index_sth = $dbh->prepare_cached($delete_index_query) || die "Could not prepare $delete_index_query: $DBI::errstr";
	$delete_index_sth->execute($hash_id) || die "Could not execute $delete_index_query: $DBI::errstr";
	
	return 1;
}

sub InsertObject
{
	my $classname = shift;
	my $self = shift;
	
	my $object = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $object;

	croak "Attempt to call InsertObject() as a function call." if not defined $classname;
	croak "No object passed to InsertObject()" if not defined $object;

	my $dbh = $self->DatabaseHandle();
	croak "Could not obtain a database handle!" if not defined $dbh;

	my $info_table = $self->INFO_TABLE();
	my $data_table = $self->DATA_TABLE();
	my $index_table = $self->INDEX_TABLE();
	my $time = time();

	my $object_data = $object->{_data};
	my $object_index_data = $object->{_index_data};
	my $index_fields = $object->INDEX_FIELDS();

	#Insert the info record
	my $insert_info_query = "INSERT INTO 
						$info_table(type,time_created,time_modified)
						values(?,?,?)";
	my $insert_info_sth = $dbh->prepare_cached($insert_info_query) || die "Could not prepare $insert_info_query: $DBI::errstr";
	$insert_info_sth->execute($self->Type(), $time,$time) || die "Could not execute $insert_info_query: $DBI::errstr";
	my $object_id = $insert_info_sth->{'mysql_insertid'};
	$insert_info_sth->finish();


	#Insert the data record
	if($object_data)
	{
		my $insert_data_query = "INSERT INTO
						$data_table(id,data)
						values(?,?)";
		my $insert_data_sth = $dbh->prepare_cached($insert_data_query) || die "Could not prepare $insert_data_query: $DBI::errstr";
		$insert_data_sth->execute(
					$object_id,
					$object->_FlattenData($object_data)||"{}") || die "Could not execute $insert_data_query: $DBI::errstr";
		$insert_data_sth->finish();
	}

	#Insert the index record
	if(keys %$object_index_data)
	{
		my $index_values = [(map $object->{_index_data}->{$_}, @$index_fields)];

		my $insert_index_query = "INSERT INTO
						$index_table(id,".(join ',', @$index_fields).")
						values(?,".(join ',', map('?', @$index_fields)).")";
		my $insert_index_sth = $dbh->prepare($insert_index_query) || die "Could not prepare $insert_index_query: $DBI::errstr";
		$insert_index_sth->execute(
					$object_id, 
					@$index_values) || die "Could not execute $insert_index_query: $DBI::errstr";
		$insert_index_sth->finish();
	}

	return $object_id;
}
	
sub UpdateObject
{
	my $classname = shift;
	my $self = shift;

	my $object = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $object; 

	croak "Attempt to call UpdateObject() as a function call." if not defined $classname;
	croak "No object passed to UpdateObject()" if not defined $object;

	my $dbh = $self->DatabaseHandle();
	croak "Could not obtain a database handle!" if not defined $dbh;

	my $info_table = $object->INFO_TABLE();
	my $data_table = $object->DATA_TABLE();
	my $index_table = $object->INDEX_TABLE();
	my $time = time();

	my $object_data = $object->{_data};
	my $object_index_data = $object->{_index_data};
	my $index_fields = $object->INDEX_FIELDS();

	#Update the info record.
	my $update_info_query = "UPDATE $info_table
					SET
						type = ?,
						time_created = ?,
						time_modified = ?
					WHERE 
						id = ?";


	my $update_info_sth = $dbh->prepare_cached($update_info_query) || die "Could not prepare $update_info_query: $DBI::errstr";

	$update_info_sth->execute(
				$self->Type(), 
				$self->TimeCreated(),
				$time,
				$object->{_object_id},
				) || die "Could not execute $update_info_query: $DBI::errstr";
	$update_info_sth->finish();

	#update the data record			

	if($object_data && $object->{_data_dirty})
	{
		my $update_data_query = "UPDATE $data_table
					SET
						data = ?
					WHERE	
						id = ?";


		my $update_data_sth = $dbh->prepare_cached($update_data_query) || die "Could not prepare $update_data_query: $DBI::errstr";
		$update_data_sth->execute(
				$object->_FlattenData($object_data), 
				$object->{_object_id}) || die "Could not execute $update_data_query: $DBI::errstr";

		$update_data_sth->finish();
	}

	#update the index record
	if($object_index_data && $object->{_index_dirty})
	{
		my $index_values = [(map $object->{_index_data}->{$_}, @$index_fields)];
		my $update_index_query = "UPDATE $index_table
					SET
						".(join ',', map("$_ = ?", (@$index_fields)))."
					WHERE id = ?";
		my $update_index_sth = $dbh->prepare($update_index_query) || die "Could not prepare $update_index_query: $DBI::errstr";
		$update_index_sth->execute(
					@$index_values, 
					$object->{_object_id}) || die "Could not execute $update_index_query: $DBI::errstr";
		$update_index_sth->finish();
	}

	return $object->{_object_id};
}	

666;
