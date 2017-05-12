

package Tangram::Type::Ref::FromMany;
use strict;

use Tangram::Lazy::Ref;

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Scalar );

$Tangram::Schema::TYPES{ref} = Tangram::Type::Ref::FromMany->new;

sub field_reschema
  {
	my ($self, $field, $def, $schema) = @_;
	$self->SUPER::field_reschema($field, $def, $schema);
	die unless $field;
	$def->{type_col} = $schema->{normalize}->("${field}_type", "colname")
	    unless defined $def->{type_col};
  }

sub get_export_cols
{
    my ($self, $context) = @_;
	return ($context->{layout1} ||! $self->{type_col}) ? ( $self->{col} ) : ( $self->{col}, $self->{type_col} );
}

sub get_import_cols
{
    my ($self, $context) = @_;
	return ($context->{layout1} ||! $self->{type_col}) ? ( $self->{col} ) : ( $self->{col}, $self->{type_col} );
}

sub get_exporter
  {
	my ($self, $context) = @_;

	my $field = $self->{name};
	my $table = $context->{class}{table};
	my $deep_update = $self->{deep_update};
	
	if ($context->{layout1}) {
	    # XXX - layout1
	  return sub {
		my ($obj, $context) = @_;
		
		return undef unless exists $obj->{$field};
		
		my $storage = $context->{storage};
		my $schema = $storage->{schema};
		
		my $tied = tied($obj->{$field});
		if ( $tied and $tied->can("storage")
		     and $tied->storage != $storage ) {
		    $tied = undef;
		}

		return $tied->id if $tied;
		
		my $ref = $obj->{$field};
		return undef unless $ref;
		
		my $id = $storage->id($obj);
		
		if ($context->{SAVING}->includes($ref)) {
		  $storage->defer( sub
						   {
							 my $storage = shift;
							 
							 # now that the object has been saved, we have an id for it
							 my $refid = $storage->id($ref);
							 # patch the column in the referant
							 $storage->sql_do( "UPDATE $table SET $self->{col} = $refid WHERE $schema->{sql}{id_col} = $id" );
						   } );
		  
		  return undef;
		}
		
		$storage->_save($ref, $context->{SAVING})
		  if $deep_update;
		
		return $storage->id($ref) || $storage->_insert($ref, $context->{SAVING});
	  }
	}
	
	my $sub = sub {
	  
	  my ($obj, $context) = @_;
	  
	  return (undef, undef) unless exists $obj->{$field};
	  
	  my $storage = $context->{storage};
	  
	  my $tied = tied($obj->{$field});
	  if ( $tied and $tied->can("storage")
	       and $tied->storage != $storage ) {
	      $tied = undef;
	  }
	  return $storage->split_id($tied->id) if $tied;
	  
	  my $ref = $obj->{$field};
	  return (undef, undef) unless $ref;
	  
	  my $exp_id = $storage->export_object($obj);
	  
	  if ($context->{SAVING}->includes($ref)) {
		$storage->defer( sub
						 {
						   my $storage = shift;
						   my $schema = $storage->{schema};

						   # now that the object has been saved, we have an id for it
						   my $ref_id = $storage->export_object($ref);
						   my $type_id = $storage->class_id(ref($ref));
						   
						   # patch the column in the referant
						   $storage->sql_do( "UPDATE $table SET $self->{col} = $ref_id, $self->{type_col} = $type_id WHERE $schema->{sql}{id_col} = $exp_id" );
						 } );
		
		return (undef, undef);
	  }
	  
	  $storage->_save($ref, $context->{SAVING})
		if $deep_update;

	  return $storage->split_id($storage->id($ref) || $storage->_insert($ref, $context->{SAVING}));
	};
	if ( $self->{type_col} ) {
	    return $sub;
	} else {
	    # XXX - not reached by test suite
	    return sub {
		my ($id, $type) = $sub->(@_);
		return $id;
	    };
	}
  }

sub get_importer
{
  my ($self, $context) = @_;
  my $field = $self->{name};

  return sub {
	my ($obj, $row, $context) = @_;
	
	my $storage = $context->{storage};
	my $rid = shift @$row;
	my $cid = shift @$row unless $context->{layout1} or !$self->{type_col};
	if ($rid and !defined $cid) {
	    $cid = $context->{storage}->class_id($self->{class});
	}

	if ($rid) {
	  tie $obj->{$field}, 'Tangram::Lazy::Ref', $storage, $context->{id}, $field, $storage->combine_ids($rid, $cid);
	} else {
	  $obj->{$field} = undef;
	}
  }
}

# XXX - not reached by test suite
sub query_expr
{
   my ($self, $obj, $memdefs, $tid, $storage) = @_;
   return map { $self->expr("t$tid.$memdefs->{$_}{col}", $obj) } keys %$memdefs;
}

sub remote_expr
{
   my ($self, $obj, $tid, $storage) = @_;
   $self->expr("t$tid.$self->{col}", $obj);
}

# XXX - not reached by test suite
sub refid
{
   my ($storage, $obj, $member) = @_;
   
   Carp::carp "Tangram::Type::Ref::FromMany::refid( \$storage, \$obj, \$member )" unless !$^W
      && eval { $storage->isa('Tangram::Storage') }
      && eval { $obj->isa('UNIVERSAL') }
      && !ref($member);

   my $tied = tied($obj->{$member});

   if ( $tied and $tied->can("storage")
	and $tied->storage != $storage ) {
       $tied = undef;
   }
   
   return $storage->id( $obj->{$member} ) unless $tied;

   my ($storage_, $id_, $member_, $refid) = @$tied;
   return $refid;
}

sub erase
{
	my ($self, $storage, $obj, $members) = @_;

	foreach my $member (keys %$members)
	{
		$storage->erase( $obj->{$member} )
			if $members->{$member}{aggreg} && $obj->{$member};
	}
}

sub coldefs
{
    my ($self, $cols, $members, $schema) = @_;

    for my $def (values %$members) {
	  my $nullable = !exists($def->{null}) || $def->{null} ? " $schema->{sql}{default_null}" : '';
	  $cols->{ $def->{col} } = $schema->{sql}{id} . $nullable;
	  $cols->{ $def->{type_col} or die } = $schema->{sql}{cid} . $nullable;
    }
}

sub DESTROY { }

1;

