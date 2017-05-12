#!/usr/bin/perl
package Persistent::Hash;

use strict;
use Carp qw(croak);
use Data::Dumper;

use vars qw($VERSION);
$VERSION = '0.5';

use Persistent::Hash::Dumper;

use constant DEBUG_LEVEL => 0;

use constant PROJECT => 'persistent-hash';

use constant INFO_TABLE => 'object_info';

use constant INDEX_TABLE => 'object_index';
use constant INDEX_FIELDS => [];

use constant DATA_TABLE => 'object_data';
use constant DATA_FIELDS => [];

use constant STRICT_FIELDS => 1;
use constant STORAGE_MODULE => 'Persistent::Hash::Storage::MySQL';

use constant STORABLE => 0;
use constant LOAD_ON_DEMAND => 1;
use constant SAVE_ONLY_IF_DIRTY => 0;

sub new
{
	my $classname = shift;
	return $classname->_instanciate(@_);
}

sub _instanciate
{
	my($classname, $args) = @_;

	my $self;
	#Create the untied hash

	#Tie the hash
	tie %$self, $classname;
	bless $self, $classname;

	my $untied_self = tied %$self;
	$untied_self->{_data_dirty} = 1;
	$untied_self->{_index_dirty} = 1;
	
	return $self;
}

sub load
{
	my ($classname, $id) = @_;

	croak "Attempt to call load() using a function call" if not defined $classname;
	croak "No id passed to load()" if not defined $id;
	croak "Argument to load() is not numeric" if not $id =~ /^[0-9]+$/;
	
	my $self = $classname->_instanciate();
	my $untied_self = tied %$self if tied %$self;
	die "Constructor error" if not defined $untied_self;

	my $storage_module = $untied_self->_PreloadStorageModule();

	my $object_info = $storage_module->LoadObjectInfo($classname, $id);
	if(not defined $object_info)
	{
		print STDERR "Could not load object id $id";
		return undef;
	}
	
	$untied_self->{_object_id} = $id;
	$untied_self->{_object_type} = $object_info->{type};
	$untied_self->{_time_created} = $object_info->{time_created};		
	$untied_self->{_time_modified} = $object_info->{time_modified};

	if(not $self->LOAD_ON_DEMAND())
	{
		$untied_self->_Initialize();
	}

	return $self;			
}

sub Id
{
	my $self = shift;
	croak "No self reference!" if not defined $self;

	$self = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $self;

	return $self->{_object_id};
}

sub Type
{
	my $self = shift;
	croak "No self reference!" if not defined $self;

	return $self->PackageToType();	
}

sub TimeCreated
{
	my $self = shift;
	croak "No self reference!" if not defined $self;

	my $untied_self = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $untied_self;

	return $untied_self->{_time_created};
}

sub TimeModified
{
	my $self = shift;
	croak "No self reference!" if not defined $self;

	my $untied_self = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $untied_self;

	return $untied_self->{_time_modified};
}
sub PackageToType
{
	my $self = shift;
	croak "No self reference!" if not defined $self;

	my $type = ref($self) ? ref($self) : $self;
	$type =~ s/::/_/g;

	$type = $self->PROJECT()."/".$type;

	return $type;
}

sub Save
{
	my $self = shift;
	croak "No self reference!" if not defined $self;

	my $untied_self = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $untied_self;

	return undef if !$untied_self->STORABLE();
	return undef if !$untied_self->_IsDirty() && $untied_self->SAVE_ONLY_IF_DIRTY();

	my $storage_module = $untied_self->_PreloadStorageModule();

	if(!defined $untied_self->{_object_id})
	{
		my $object_id = $storage_module->InsertObject($self);	
		croak "Object insertion failed!" if not defined $object_id;

		$untied_self->{_object_id} = $object_id;
		$untied_self->{_data_dirty} = 0;
		$untied_self->{_index_dirty} = 0;

		return $object_id;
	}
	else
	{
		my $object_id = $storage_module->UpdateObject($self);
		croak "Object update failed!" if not defined $object_id;

		$untied_self->{_data_dirty} = 0;
		$untied_self->{_index_dirty} = 0;

		return $object_id;
	}
}

sub Delete
{
	my $self = shift;
	croak "No self reference!" if not defined $self;

	my $untied_self = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $untied_self;

	return undef if not $untied_self->STORABLE();
	return undef if not $untied_self->{_object_id};
	
	my $storage_module = $untied_self->_PreloadStorageModule();

	my $delete_status = $storage_module->DeleteObject($self);
	if($delete_status)
	{
		$untied_self = undef;
		untie %$self;
		return 1;
	}
	else
	{
		die "Object deletion error !";
	}

}

sub DatabaseHandle
{
	my $self = shift;

	croak "\nNo DatabaseHandle() function defined in ".ref($self)."\n";
}


sub InternalData
{
	my $self = shift;
	croak "No self reference!" if not defined $self;
	
	my $untied_self = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $untied_self;

	return $untied_self;
}


sub Freezer 
{
	my $self = shift;
	croak "No self reference!" if not defined $self;
	
	my $untied_self = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $untied_self;

	my $id = $self->Id();

	if(not defined $id)
	{
		my $type = $self->Type();
		warn "Attempted to freeze an unsaved object instance of type $type";
	}

	my $package = ref($self);
	my $str = "do { use $package; scalar(load $package('$id')) }";
	return $str;
}

sub Dump
{
	my $self = shift;
	croak "No self reference!" if not defined $self;
	
	my $untied_self = tied %$self if tied %$self;
	croak "Wrong object side!" if not defined $untied_self;

   local $Data::Dumper::Indent=0;
   local $Data::Dumper::Useqq=1;
   local $Data::Dumper::Terse=1;
   local $Data::Dumper::Freezer = 'Freezer';

	my $d = 'Persistent::Hash::Dumper'->new( [$untied_self->{_data}] );
	my $str = $d->Dump();
	return $str;
}

	
#--#------------------------------------------#
# Internal API
#--#------------------------------------------#

sub _IsInitialized
{
	my $untied_self = shift;
	croak "Attempt to call _IsInitialized() as a function call" if not defined $untied_self;
	croak "Wrong object side!" if tied %$untied_self;

	return 1 if(not $untied_self->LOAD_ON_DEMAND());
	return 1 if(not defined $untied_self->{_object_id});
	return 1 if( defined $untied_self->{_object_id} && defined $untied_self->{_initialized});
	return undef;
}

sub _Initialize
{
	my $untied_self = shift;
	croak "Attempt to call _Initialize() as a function call" if not defined $untied_self;
	croak "Wrong object side!" if tied %$untied_self;

	return undef if not defined $untied_self->{_object_id};	

	my $storage_module = $untied_self->_PreloadStorageModule();

	$untied_self->{_data} = $storage_module->LoadObjectData($untied_self);
	$untied_self->{_index_data} = $storage_module->LoadObjectIndex($untied_self);


	foreach my $key (keys %{$untied_self->{_data}})
	{
		delete $untied_self->{_data}->{$key} if !$untied_self->{_data_fields}->{$key} && $untied_self->STRICT_FIELDS();
		delete $untied_self->{_data}->{$key} if !defined $untied_self->{_data}->{$key};
	}

	foreach my $key (keys %{$untied_self->{_index_data}})
	{
		delete $untied_self->{_index_data}->{$key} if !$untied_self->{_index_fields}->{$key} && $untied_self->STRICT_FIELDS();
		delete $untied_self->{_index_data}->{$key} if !defined $untied_self->{_index_data}->{$key};
	}

	$untied_self->{_initialized} = 1;

	return 1;
}
	
sub _IsDirty
{
	my $untied_self = shift;
	croak "Attempt to call _IsDirty() as a function call" if not defined $untied_self;
	croak "Wrong object side!" if tied %$untied_self;

	#If any key in the hash is a ref to something, we are automatically
	#dirty because we can't track another ref's modifications.
	foreach my $key (keys %{$untied_self->{'_data'}})
	{
		$untied_self->{'_data_dirty'} = 1 if ref( $untied_self->{'_data'}->{$key} );
	}

	return 1 if $untied_self->{_index_dirty} == 1;
	return 1 if $untied_self->{_data_dirty} == 1;
	return undef;
}

sub _FlattenData
{
	my $untied_self = shift;
	croak "No self reference!" if not defined $untied_self;
	croak "Wrong object side!" if tied %$untied_self;	

   local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 0;
   local $Data::Dumper::Useqq = 1;

	my $dump = Dumper($untied_self->{_data});
	$dump =~ s/\$VAR1 =//g;

	return $dump;
}

sub _PreloadStorageModule
{	
	my $untied_self = shift;
	croak "Attempt to call _IsDirty() as a function call" if not defined $untied_self;
	croak "Wrong object side!" if tied %$untied_self;

	return $untied_self->STORAGE_MODULE() if $untied_self->{_storage_module_preloaded};

	my $storage_module = $untied_self->STORAGE_MODULE();
	eval "use $storage_module";
	if($@)
	{
		die "Could not compile $storage_module";
	}
	$untied_self->{_storage_module_preloaded} = 1;
	return $untied_self->STORAGE_MODULE();
}

#--#------------------------------------------#
# Tie Hash implementation
#--#------------------------------------------#

sub TIEHASH
{
	my ($classname, $args) = @_;
	print STDERR "TIEHASH called.\n" if $classname->DEBUG_LEVEL();

	my $type = $classname->PackageToType();

	my $self = 
	{
		_object_id => undef,
		_object_type => $type,
		_data => {},	
		_data_fields => {},
		_data_dirty => 0,
		_index_data => {},
		_index_fields => {},
		_index_dirty => 0,
		_storage_module_preloaded => 0,
	};
	bless $self, $classname;

	return $self->_TieFields();
}

sub _TieFields
{
	my $self = shift;
	$self->{_index_fields} = {};
	$self->{_data_fields} = {};

	foreach my $field (@{$self->INDEX_FIELDS()})
	{
		$self->{_index_fields}->{$field} = 1;
	}

	foreach my $field (@{$self->DATA_FIELDS()})
	{
		$self->{_data_fields}->{$field} = 1;
	}
	return $self;
}
	
sub DELETE
{
	my $untied_self = shift;
	print STDERR "DELETE called.\n" if $untied_self->DEBUG_LEVEL();
	my $key = shift;

	$untied_self->_Initialize() if not $untied_self->_IsInitialized();

	if($untied_self->{_index_fields}->{$key})
	{
		$untied_self->{_index_dirty} = 1;
		return delete $untied_self->{_index_data}->{$key};
	}
	elsif($untied_self->{_data_fields}->{$key})
	{
		$untied_self->{_data_dirty} = 1;
		return delete $untied_self->{_data}->{$key};
	}
	else
	{
		$untied_self->{_data_dirty} = 1;
		return delete $untied_self->{_data}->{$key};
	}
}

sub CLEAR
{
	my $untied_self = shift;
	print STDERR "CLEAR called.\n" if $untied_self->DEBUG_LEVEL();

	$untied_self->_Initialize() if not $untied_self->_IsInitialized();

	$untied_self->{_index_dirty} = 1;
	$untied_self->{_index_data} = {};
	$untied_self->{_data_dirty} = 1;
	return $untied_self->{_data} = {};
}

	
sub STORE
{
	my $untied_self = shift;
	my $key = shift;
	my $value = shift;
	print STDERR "STORE called for $key: $value\n" if $untied_self->DEBUG_LEVEL();

	$untied_self->_Initialize() if not $untied_self->_IsInitialized();

	if($untied_self->{_index_fields}->{$key})
	{
		$untied_self->{_index_dirty} = 1;
		return $untied_self->{_index_data}->{$key} = $value;
	}
	elsif($untied_self->{_data_fields}->{$key})
	{
		$untied_self->{_data_dirty} = 1;
		return $untied_self->{_data}->{$key} = $value;
	}
	elsif($untied_self->STRICT_FIELDS())
	{
		print STDERR "\nKey $key not allowed in a ".ref($untied_self)."\n";
		return undef;
	}
	else
	{
		$untied_self->{_data_dirty} = 1;
		return ($untied_self->{_data}->{$key} = $value);
	}
}

sub FETCH
{
	my $untied_self = shift;
	my $key = shift;
	print STDERR "FETCH called for $key\n" if $untied_self->DEBUG_LEVEL();

	$untied_self->_Initialize() if not $untied_self->_IsInitialized();

	if($untied_self->STRICT_FIELDS())
	{
		if($untied_self->{_index_fields}->{$key})
		{
			return $untied_self->{_index_data}->{$key};
		}
		if($untied_self->{_data_fields}->{$key})
		{
			return $untied_self->{_data}->{$key};
		}
		return undef;
	}
	else
	{
		if($untied_self->{_index_fields}->{$key})
		{
			return $untied_self->{_index_data}->{$key};
		}
		return $untied_self->{_data}->{$key};
	}
		
}

sub EXISTS
{
	my $untied_self = shift;
	print STDERR "EXISTS called.\n" if $untied_self->DEBUG_LEVEL();
	my $key = shift;

	$untied_self->_Initialize() if not $untied_self->_IsInitialized();

	if($untied_self->{_index_fields}->{$key})
	{
		return exists $untied_self->{_index_data}->{$key};
	}
	elsif($untied_self->{_data_fields}->{$key})
	{
		return exists $untied_self->{_data}->{$key};
	}
	else
	{
		return undef;
	}
}

sub NEXTKEY
{
	my $untied_self = shift;
	print STDERR "NEXTKEY called.\n" if $untied_self->DEBUG_LEVEL();

	$untied_self->_Initialize() if not $untied_self->_IsInitialized();
	return pop @{$untied_self->{_keyslist}};
}

sub FIRSTKEY
{
	my $untied_self = shift;
	print STDERR "FIRSTKEY called.\n" if $untied_self->DEBUG_LEVEL();

	$untied_self->_Initialize() if not $untied_self->_IsInitialized();
	$untied_self->{_keyslist} = 
	[ 
		(keys %{$untied_self->{_data}}), 
		(keys %{$untied_self->{_index_data}}) 
	];

	return pop @{$untied_self->{_keyslist}}; 
}

666;
