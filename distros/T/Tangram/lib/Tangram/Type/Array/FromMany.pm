

use strict;

package Tangram::Type::Array::FromMany;

use Tangram::Type::Abstract::Array;
use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Abstract::Array );

use Carp;

sub reschema
{
	my ($self, $members, $class, $schema) = @_;

	foreach my $member (keys %$members)
	{
		my $def = $members->{$member};

		unless (ref($def))
		{
		    # XXX - not reached by test suite
			$def = { class => $def };
			$members->{$member} = $def;
		}

		$def->{table} ||= $schema->{normalize}->($def->{class} . "_$member", 'tablename');
		$def->{coll}  ||= 'coll';
		$def->{item}  ||= 'item';
		$def->{slot}  ||= 'slot';
	}
   
	return keys %$members;
}

sub get_save_closures
{
	my ($self, $storage, $obj, $def, $id) = @_;

	my ($table, $cc, $ic, $sc) = @{ $def }{ qw( table coll item slot ) };

	my $ne = sub { shift() != shift() };
	my $eid = $storage->{export_id}->($id);

	my $modify = sub
	{
		my ($slot, $item) = @_;

		my $item_id = $storage->export_object($item)
			|| croak "element at $slot has no id";
         
		$storage->sql_do(
            "UPDATE\n    $table\nSET\n    $ic = $item_id\nWHERE\n    $cc = $eid   AND\n    $sc = $slot");
	};

	my $add = sub
	{
		my ($slot, $item) = @_;
		my $item_id = $storage->export_object($item);
		$storage->sql_do(
		    "INSERT INTO $table ($cc, $ic, $sc)\n    VALUES ($eid, $item_id, $slot)");
	};

	my $remove = sub
	{
		my ($new_size) = @_;
		$storage->sql_do(
            "DELETE FROM\n    $table\nWHERE\n    $cc = $eid    AND\n    $sc >= $new_size");
	};

	return ($ne, $modify, $add, $remove);
}

sub erase
{
	my ($self, $storage, $obj, $members, $coll_id) = @_;

	$coll_id = $storage->{export_id}->($coll_id);

	foreach my $member (keys %$members)
	{
		my $def = $members->{$member};
      
		my $table = $def->{table} || $def->{class} . "_$member";
		my $coll_col = $def->{coll} || 'coll';
     
		my $sql = "DELETE FROM\n    $table\nWHERE\n    $coll_col = $coll_id";
	  
		if ($def->{aggreg})
		{
			my @content = @{ $obj->{$member} };
			$storage->sql_do($sql);
			$storage->erase( @content ) ;
		}
		else
		{
			$storage->sql_do($sql);
		}
	}
}

sub cursor
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

sub remote_expr
{
	my ($self, $obj, $tid) = @_;
	Tangram::Expr::Coll::FromMany->new($obj, $self);
}

# XXX - not reached by test suite
sub query_expr
{
	my ($self, $obj, $members, $tid) = @_;
	map { Tangram::Expr::Coll::FromMany->new($obj, $_); } values %$members;
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
		$prefetch->{$id} = []
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
		$prefetch->{$coll_id}[$slot] = $item;
		$cursor->next;
	}

	return $prefetch;
}

$Tangram::Schema::TYPES{array} = Tangram::Type::Array::FromMany->new;

#---------------------------------------------------------------------
#  Tangram::Type::Array::FromMany->coldefs($cols, $members, $schema, $class, $tables)
#
#  Setup column mappings for many to many unordered mappings (link
#  table with integer category)
#---------------------------------------------------------------------
sub coldefs
{
    my ($self, $cols, $members, $schema, $class, $tables) = @_;

    foreach my $member (values %$members)
    {
	my $COLS = $tables->{ $member->{table} }{COLS} ||= { };

	$COLS->{$member->{coll}} = $schema->{sql}{id};
	$COLS->{$member->{item}} = $schema->{sql}{id};
	$COLS->{$member->{slot}} = "INT $schema->{sql}{default_null}";
    }
}

1;
