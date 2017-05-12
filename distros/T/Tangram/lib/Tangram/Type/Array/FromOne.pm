

use strict;

package Tangram::Type::Array::FromOne;

use Tangram::Type::Abstract::Array;
use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Abstract::Array );

use Carp;

sub reschema {
    my ($self, $members, $class, $schema) = @_;

    foreach my $member (keys %$members) {
	my $def = $members->{$member};

	unless (ref($def))
	    {
		$def = { class => $def };
		$members->{$member} = $def;
	    }

	$def->{coll} ||= ($schema->{normalize}->($class)
			  . "_$member");
	$def->{slot} ||= ($schema->{normalize}->($class)
			  . "_$member" . "_slot");
   
	$schema->{classes}{$def->{class}}{stateless} = 0;

	if (exists $def->{back}) {
	    my $back = $def->{back} ||= $def->{item};
	    $schema->{classes}{ $def->{class} }{members}{backref}{$back} =
		bless {
		       name => $back,
		       col => $def->{coll},
		       class => $class,
		       field => $member
		      }, 'Tangram::Type::BackRef';
	}
    }

    return keys %$members;
}

sub defered_save
  {
	use integer;
	
	my ($self, $storage, $obj, $field, $def) = @_;
	
	#my $classes = $storage->{schema}{classes};
	#my $old_states = $storage->{scratch}{ref($self)}{$coll_id};
	
	# foreach my $field (keys %$members) {
	
	return if tied $obj->{$field};

	my $coll_id = $storage->export_object($obj);
	
	my $classes = $storage->{schema}{classes};
	my $item_classdef = $classes->{ $def->{class} };
	my $table = $item_classdef->{table} or die;
	my $item_col = $def->{coll};
	my $slot_col = $def->{slot};
	
	my $coll = $obj->{$field};
	my $coll_size = @$coll;
	
	my @new_state = ();
	
	my $old_state = $self->get_load_state($storage, $obj, $field) || [];
	my $old_size = $old_state ? @$old_state : 0;
	# FIXME - where on earth are the undef values coming from ?  :(
	@$old_state = grep { defined } @$old_state;
	
	my %removed;
	@removed{ @$old_state } = () if $old_state;
	
	my $slot = 0;
	
	while ($slot < $coll_size)
	  {
		my $item_id = $storage->id( $coll->[$slot] ) || die;
		my $ex_item_id = $storage->{export_id}->($item_id);
		
		$storage->sql_do
		    ("UPDATE\n    $table\nSET\n    "
		     ."$item_col = $coll_id,\n    "
		     ."$slot_col = $slot\nWHERE\n    "
		     ."$storage->{schema}{sql}{id_col} = $ex_item_id")
		  unless $slot < $old_size && $item_id eq $old_state->[$slot];
		
		push @new_state, $item_id;
		delete $removed{$item_id};
		++$slot;
	  }
	
	if (keys %removed)
	  {
		my $removed = join(', ', map { $storage->{export_id}->($_) } keys %removed);
		$storage->sql_do("UPDATE\n    $table\nSET\n    $item_col = NULL,\n    $slot_col = NULL\nWHERE\n    $storage->{schema}{sql}{id_col} IN ($removed)");
	  }
	
	$self->set_load_state($storage, $obj, $field, \@new_state);	
	
	$storage->tx_on_rollback( sub { $self->set_load_state($storage, $obj, $field, $old_state) } );
  }

sub erase
{
	my ($self, $storage, $obj, $members, $coll_id) = @_;

	$coll_id = $storage->{export_id}->($coll_id);

	foreach my $member (keys %$members)
	{
		my $def = $members->{$member};

		if ($def->{aggreg})
		{
			$storage->erase( @{ $obj->{$member} } );
		}
		else
		{
			my $item_classdef = $storage->{schema}{classes}{$def->{class}};
			my $table = $item_classdef->{table} || $def->{class};
			my $item_col = $def->{coll};
			my $slot_col = $def->{slot};
      
			$storage->sql_do("UPDATE\n    $table\nSET\n    $item_col = NULL,\n    $slot_col = NULL\nWHERE\n    $item_col = $coll_id" );
		}
	}
}

sub cursor
{
	my ($self, $def, $storage, $obj, $member) = @_;

	my $cursor = Tangram::Cursor::Coll->new($storage, $def->{class}, $storage->{db});

	my $item_col = $def->{coll};
	my $slot_col = $def->{slot};

	my $coll_id = $storage->export_object($obj);
	my $tid = $cursor->{TARGET}->object->{table_hash}{$def->{class}};  # $cursor->{TARGET}->object->leaf_table;
	$cursor->{-coll_cols} = "t$tid.$slot_col";
	$cursor->{-coll_where} = "t$tid.$item_col = $coll_id";

	return $cursor;
}

# XXX - not reached by test suite
sub query_expr
{
	my ($self, $obj, $members, $tid) = @_;
	map { Tangram::Expr::Coll::FromOne->new($obj, $_); } values %$members;
}

sub remote_expr
{
	my ($self, $obj, $tid) = @_;
	Tangram::Expr::Coll::FromOne->new($obj, $self);
}

sub prefetch
{
	my ($self, $storage, $def, $coll, $class, $member, $filter) = @_;

	my $ritem = $storage->remote($def->{class});
	my $prefetch = $storage->{PREFETCH}{$class}{$member} ||= {}; # weakref

	my $cursor = Tangram::Cursor->new($storage, $ritem, $storage->{db});
	
	my $includes = $coll->{$member}->includes($ritem);
	$includes &= $filter if $filter;

	# also retrieve collection-side id and index of elmt in sequence
	$cursor->retrieve($coll->{id},
	    $storage->expr(Tangram::Type::Integer->instance,
			"t$ritem->{_object}{table_hash}{$def->{class}}.$def->{slot}") );

	$cursor->select($includes);
   
	while (my $item = $cursor->current)
	{
		my ($coll_id, $slot) = $cursor->residue;
		($prefetch->{$coll_id}||=[])->[$slot] = $item;
		$cursor->next;
	}

	return $prefetch;
}

$Tangram::Schema::TYPES{iarray} = Tangram::Type::Array::FromOne->new;

#---------------------------------------------------------------------
#  Tangram::Type::Array::FromOne->coldefs($cols, $members, $schema, $class,
#                              $tables)
#
#  Setup column mappings for one to many ordered mappings (foreign
#  key with associated integer category/column)
#---------------------------------------------------------------------
sub coldefs
{
    my ($self, $cols, $members, $schema, $class, $tables) = @_;

    foreach my $member (values %$members) {
	my $table =
	    $tables->{ $schema->{classes}{$member->{class}}{table} }
		||= {};
	$table->{COLS}{$member->{coll}}
	    = "$schema->{sql}{id} $schema->{sql}{default_null}";
	$table->{COLS}{$member->{slot}}
	    = "INT $schema->{sql}{default_null}";
    }
}

1;
