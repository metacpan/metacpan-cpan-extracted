package Tangram::Expr::Coll::FromOne;

use strict;
use Tangram::Expr::Coll;

use vars qw(@ISA);
 @ISA = qw( Tangram::Expr::Coll );

sub includes
{
	my ($self, $item) = @_;
	my ($coll, $memdef) = @$self;
	my $coll_tid = $coll->root_table;
	my $item_class = $memdef->{class};
	my $storage = $coll->{storage};
	my $schema = $storage->{schema};

	my $item_id;

	if (ref($item))
	{
		if ($item->isa('Tangram::Expr::QueryObject'))
		{
			my $item_tid = $item->object->table($item_class);

			return Tangram::Expr::Filter->new
				(
				 expr => "t$item_tid.$memdef->{coll} = t$coll_tid.$schema->{sql}{id_col}",
				 tight => 100,
				 objects => Set::Object->new($coll, $item->object),
				)
			}

		$item_id = $storage->export_object($item);

	}
	else
	{
		$item_id = $storage->{export_id}->($item);
	}

	my $remote = $storage->remote($item_class);
	# FIXME - style inconsistency
	return ($self->includes($remote) & ($remote->{id} == $item_id));
}

sub includes_or
{
	my ($self, @items) = @_;
	my ($coll, $memdef) = @$self;
	my $coll_tid = $coll->root_table;
	my $item_class = $memdef->{class};
	my $item_tid;
	my $storage = $coll->{storage};
	my $schema = $storage->{schema};

	my (@targets_fwd, @targets_rev);
	my $objects = Set::Object->new
	    ($coll,
	    );

	foreach my $item (@items) {
	    if (ref($item))
		{
		    if ($item->isa('Tangram::Expr::QueryObject'))
			{
			    $item_tid = $item->object->table($item_class);
			    push @targets_fwd, ("t".$item_tid.".$memdef->{coll}");
			    $objects->insert($item->object);
			}
		    else
			{
			    # 
			    #push @targets, ($storage->export_object($item));
			    push @targets_rev, ($storage->export_object($item));
			}
		}
	    else
		{
		    push @targets_rev, $storage->{export_id}->($item);
		}
	}

	my $expr;
	if (@targets_fwd) {
	    my  $joined_targets = join(',', @targets_fwd);
	    $expr =
	    Tangram::Expr::Filter->new
		    (
		     expr => "(t$coll_tid.$schema->{sql}{id_col} IN ($joined_targets))",
		     tight => 120,
		     objects => $objects,
		    );
	}
	if (@targets_rev) {

	    my $remote = $storage->remote($item_class);
	    #$objects->insert($remote);
	    my $item_tid = $remote->object->table($item_class);

	    my $joined_targets = join(',', @targets_rev);
	    my $new_expr = 
		Tangram::Expr::Filter->new
			(
			 expr => "(t$item_tid.$schema->{sql}{id_col} in ($joined_targets))",
			 tight => 100,
			 objects => $objects,
			);

	    if ($expr) {
		return ( ( $self->includes($remote) & $new_expr ) | $expr );
	    }

	    return ( $self->includes($remote) & $new_expr );
	}
	return $expr;

}

