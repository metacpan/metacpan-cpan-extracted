

use strict;

package Tangram::Type::Hash::FromMany;

use Tangram::Type::Abstract::Hash;
use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Abstract::Hash );

use Carp;

sub reschema
{
    my ($self, $members, $class, $schema) = @_;

    foreach my $member (keys %$members)
    {
		my $def = $members->{$member};

		unless (ref($def))
		{
		    # XXX - not tested by test suite
			$def = { class => $def };
			$members->{$member} = $def;
		}

		$def->{table} ||= $schema->{normalize}->($def->{class} . "_$member", 'tablename');
		$def->{coll} ||= 'coll';
		$def->{item} ||= 'item';
		$def->{slot} ||= 'slot';
		$def->{quote} = !exists $def->{key_type} || $def->{key_type} eq 'string' ? "'" : '';
    }
    
    return keys %$members;
}

sub defered_save {
  my ($self, $obj, $field, $storage) = @_;
  
  my $coll_id = $storage->export_object($obj);
  
  my ($table, $coll_col, $item_col, $slot_col) = @{ $self }{ qw( table coll item slot ) };
  my $Q = $self->{quote};
  
  my $coll = $obj->{$field};
  
  my $old_state = $self->get_load_state($storage, $obj, $field) || {};
  
  my %removed = %$old_state;
  delete @removed{ keys %$coll };
  my @free = keys %removed;
  
  my %new_state;
  
  foreach my $slot (keys %$coll)
	{
	  my $item_id = $storage->export_object($coll->{$slot});
	  
	  if (exists $old_state->{$slot})
		{
		  # key already exists
		  # XXX - not reached by test suite
		  if ($item_id != $old_state->{$slot})
			{
			  # val has changed
			  $storage->sql_do
			      ( "UPDATE\n    $table\nSET\n    $item_col = $item_id\nWHERE\n    $coll_col = $coll_id     AND\n    $slot_col = $Q$slot$Q" );
		      }
		}
	  else
		{
		  # key does not exist
		  
		  if (@free)
			{
			  # recycle an existing line
			    # XXX - not reached by test suite
			  my $rslot = shift @free;
			  $storage->sql_do(
					   "UPDATE\n    $table\nSET\n    $slot_col = $Q$slot$Q,\n    $item_col = $item_id\nWHERE\n    $coll_col = $coll_id    AND\n    $slot_col = $Q$rslot$Q" );
			}
		  else
			{
			  # insert a new line
			  $storage->sql_do(
							   "INSERT INTO $table ($coll_col, $item_col, $slot_col)\n     VALUES ($coll_id, $item_id, $Q$slot$Q)" );
			}
		}
	  
	  $new_state{$slot} = $item_id;
	  
	}							# foreach my $slot (keys %$coll)
  
  # remove lines in excess
  
  if (@free)
	{
	    # XXX - not reached by test suite
	  @free = map { "$Q$_$Q" } @free if $Q;
	  $storage->sql_do( "DELETE FROM\n    $table\nWHERE\n    $coll_col = $coll_id     AND\n    $slot_col IN (@free)" );
	}
  
  $self->set_load_state($storage, $obj, $field, \%new_state );	
  $storage->tx_on_rollback( sub { $self->set_load_state($storage, $obj, $field, $old_state) } );
}


sub erase
{
    my ($self, $storage, $obj, $members, $coll_id) = @_;

    foreach my $member (keys %$members)
    {
		my $def = $members->{$member};
	
		my $table = $def->{table} || $def->{class} . "_$member";
		my $coll_col = $def->{coll} || 'coll';
	
		my $sql = "DELETE FROM\n    $table\nWHERE\n    $coll_col = $coll_id";
		$storage->sql_do($sql);
    }
}

sub cursor						# ?? factorize ??
{
    my ($self, $def, $storage, $obj, $member) = @_;

    my $cursor = Tangram::Cursor::Coll->new($storage, $def->{class}, $storage->{db});

    my $coll_id = $storage->export_object($obj);
    my $coll_tid = $storage->alloc_table;
    my $table = $def->{table};
	my $item_tid = $cursor->{TARGET}->object->root_table;
    my $coll_col = $def->{coll};
    my $item_col = $def->{item};
    my $slot_col = $def->{slot};
    $cursor->{-coll_tid} = $coll_tid;
    $cursor->{-coll_cols} = "t$coll_tid.$slot_col";
    $cursor->{-coll_from} = "$table t$coll_tid";
    $cursor->{-coll_where} = "t$coll_tid.$coll_col = $coll_id AND t$coll_tid.$item_col = t$item_tid.$storage->{schema}{sql}{id_col}";
    $cursor->{-no_skip_read} = 1;
    
    return $cursor;
}

# XXX - not reached by test suite
sub query_expr
{
    my ($self, $obj, $members, $tid) = @_;
    map { Tangram::Expr::Coll::FromMany->new($obj, $_); } values %$members;
}

sub remote_expr
{
    my ($self, $obj, $tid) = @_;
    Tangram::Expr::Coll::FromMany->new($obj, $self);
}

sub prefetch
{
	my ($self, $storage, $def, $coll, $class, $member, $filter) = @_;

	my $ritem = $storage->remote($def->{class});

	# first retrieve the collection-side ids of all objects satisfying $filter
	# empty the corresponding prefetch array

	my $ids = $storage->my_select_data( cols => [ $coll->{id} ], filter => $filter );
	my $prefetch = $storage->{PREFETCH}{$class}{$member} ||= {}; # weakref

	while (my ($id) = $ids->fetchrow)
	{
		$prefetch->{$id} = {};
	}

	undef $ids;

	# now fetch the items

	my $cursor = Tangram::Cursor->new($storage, $ritem, $storage->{db});
	my $includes = $coll->{$member}->includes($ritem);

	# also retrieve collection-side id and index of elmt in sequence
	$cursor->retrieve($coll->{id},
        Tangram::Type::Number->expr("t$includes->{link_tid}.$def->{slot}") );

	$cursor->select($filter ? $filter & $includes : $includes);
   
	while (my $item = $cursor->current)
	{
		my ($coll_id, $slot) = $cursor->residue;
		$prefetch->{$coll_id}{$slot} = $item;
		$cursor->next;
	}

	return $prefetch;
}

$Tangram::Schema::TYPES{hash} = Tangram::Type::Hash::FromMany->new;

#---------------------------------------------------------------------
#  Tangram::Type::Hash::FromMany->coldefs($cols, $members, $schema, $class, $tables)
#
#  Setup column mappings for many to many indexed mappings (link
#  table with string category)
#---------------------------------------------------------------------
sub coldefs
{
    my ($self, $cols, $members, $schema, $class, $tables) = @_;

    foreach my $member (values %$members)
    {
	$tables->{ $member->{table} }{COLS} =
	    {
	     $member->{coll} => $schema->{sql}{id},
	     $member->{item} => $schema->{sql}{id},
	     # XXX - hardcoded slot type
	     $member->{slot} => "VARCHAR(255) $schema->{sql}{default_null}"
	    };
    }
}

1;
