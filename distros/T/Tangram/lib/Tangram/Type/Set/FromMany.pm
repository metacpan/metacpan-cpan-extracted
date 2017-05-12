

use strict;

use Tangram::Type::Abstract::Set;

package Tangram::Type::Set::FromMany;

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Abstract::Set );

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
		$def->{coll} ||= 'coll';
		$def->{item} ||= 'item';
	}
   
	return keys %$members;
}

sub defered_save
{
    my ($self, $storage, $obj, $field, $def) = @_;

    return if tied $obj->{$field};

    my $coll_id = $storage->export_object($obj);
    my $table = $def->{table};
    my $coll_col = $def->{coll};
    my $item_col = $def->{item};

    $self->update
	($storage, $obj, $field,
	 sub {
	     if ( $storage->can("t2_insert_hook") ) {
		 # XXX - not tested by test suite
		 $storage->t2_insert_hook( ref($obj), $coll_id, $field, $_[1] );
	     }
	     my $sql = "DELETE FROM $table WHERE $coll_col = $coll_id AND $item_col = $_[0]";
	     $storage->sql_do($sql);
	     $sql = "INSERT INTO $table ($coll_col, $item_col)\n    VALUES ($coll_id, $_[0])";
	     $storage->sql_do($sql);
	 },
	 sub
	 {
	     if ( $storage->can("t2_remove_hook") ) {
		 # XXX - not tested by test suite
		 $storage->t2_remove_hook( ref($obj), $coll_id, $field, $_[1] );
	     }
	     my $sql = "DELETE FROM\n    $table\nWHERE\n    $coll_col = $coll_id  AND\n    $item_col = $_[0]";
	     $storage->sql_do($sql);
	 } );
}

#use Scriptalicious;

sub prefetch
{
	my ($self, $storage, $def, $coll, $class, $member, $filter) = @_;
   
	#my $t0 = start_timer();
	my $ritem = $storage->remote($def->{class});

	my $prefetch = $storage->{PREFETCH}{$class}{$member} ||= {}; # weakref

	#print STDERR "prefetch1: ".show_delta($t0)."\n"; $t0 = start_timer();
	my $ids = $storage->my_select_data( cols => [ $coll->{id} ], filter => $filter );

	while (my ($id) = $ids->fetchrow)
	{
		$prefetch->{$id} = []
	}

	#print STDERR "prefetch2: ".show_delta($t0)."\n"; $t0 = start_timer();
	my $includes = $coll->{$member}->includes($ritem);
	$includes &= $filter if $filter;

	my $cursor = $storage->my_cursor( $ritem, filter => $includes, retrieve => [ $coll->{id} ] );
   
	#print STDERR "prefetch3: ".show_delta($t0)."\n"; $t0 = start_timer();
	while (my $item = $cursor->current)
	{
		my ($coll_id) = $cursor->residue;
		push @{ $prefetch->{$coll_id} }, $item;
		$cursor->next;
	}

	#print STDERR "prefetch4: ".show_delta($t0)."\n";
	return $prefetch;
}

sub demand
{
	my ($self, $def, $storage, $obj, $member, $class) = @_;

	my $set = Set::Object->new;

	if (my $prefetch = $storage->{PREFETCH}{$class}{$member}{$storage->export_object($obj)})
	{
	    print $Tangram::TRACE "getting ".$storage->id($obj)
		.".$member from prefetch\n" if $Tangram::TRACE;
		$set->insert(@$prefetch);
	}
	else
	{
	    print $Tangram::TRACE "demanding ".$storage->id($obj)
		.".$member from storage\n" if $Tangram::TRACE;
		my $cursor = Tangram::Cursor::Coll->new($storage, $def->{class}, $storage->{db});

		my $coll_id = $storage->export_object($obj);
		my $coll_tid = $storage->alloc_table;
		my $table = $def->{table};
		my $item_tid = $cursor->{TARGET}->object->root_table;
		my $coll_col = $def->{coll} || 'coll';
		my $item_col = $def->{item} || 'item';
		$cursor->{-coll_tid} = $coll_tid;
		$cursor->{-coll_from} = "$table t$coll_tid";
		$cursor->{-coll_where} = "t$coll_tid.$coll_col = $coll_id AND t$coll_tid.$item_col = t$item_tid.$storage->{schema}{sql}{id_col}";
	    $cursor->{-no_skip_read} = 1;

		$set->insert($cursor->select);
	}

	$self->remember_state($def, $storage, $obj, $member, $set);

	$set;
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
	  
		if ( $storage->can("t2_remove_hook") ) {
		 # XXX - not tested by test suite
		    $storage->t2_remove_hook
			(
			 ref($obj),
			 $coll_id,
			 $member,
			 (map { $storage->id($_) }
			  $obj->{$member}->members),
			);
		}
		if ($def->{aggreg})
		{
			my @content = $obj->{$member}->members;
			$storage->sql_do($sql);
			$storage->erase( @content ) ;
		}
		else
		{
			$storage->sql_do($sql);
		}
	}
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

$Tangram::Schema::TYPES{set} = Tangram::Type::Set::FromMany->new;

#---------------------------------------------------------------------
#  Tangram::Type::Set::FromMany->coldefs($cols, $members, $schema, $class, $tables)
#
#  Setup column mappings for many to many unordered mappings (link
#  table)
#---------------------------------------------------------------------
sub coldefs
{
    my ($self, $cols, $members, $schema, $class, $tables) = @_;

    foreach my $member (values %$members)
    {
	my $COLS = $tables->{ $member->{table} }{COLS} ||= { };

	$COLS->{$member->{coll}} = $schema->{sql}{id};
	$COLS->{$member->{item}} = $schema->{sql}{id};
    }
}

1;
