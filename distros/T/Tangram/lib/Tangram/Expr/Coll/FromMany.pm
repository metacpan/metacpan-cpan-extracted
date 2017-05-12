package Tangram::Expr::Coll::FromMany;

use strict;

use vars qw(@ISA);
 @ISA = qw( Tangram::Expr::Coll );

sub includes
{
	my ($self, $item) = @_;
	my ($coll, $memdef) = @$self;

	my $schema = $coll->{storage}{schema};

	my $coll_tid = $coll->root_table;

	my $link_tid = Tangram::Expr::TableAlias->new;
	my $coll_col = $memdef->{coll};
	my $item_col = $memdef->{item};

	my $objects = Set::Object->new
	    (
	     $coll,
	     Tangram::Expr::LinkTable->new($memdef->{table}, $link_tid)
	    );
	my $target;

	if (ref $item) {
	    if ($item->isa('Tangram::Expr::QueryObject'))
		{
		    $target = 't' . $item->object->root_table . '.' . $schema->{sql}{id_col};
		    $objects->insert( $item->object );
		}
	    else
		{
		    $target = $coll->{storage}->export_object($item)
			or die "'$item' is not a persistent object";
		}
	}
	else
	    {
		$target = $item;
	    }

	Tangram::Expr::Filter->new
		(
		 expr => "t$link_tid.$coll_col = t$coll_tid.$schema->{sql}{id_col} AND t$link_tid.$item_col = $target",
		 tight => 100,      
		 objects => $objects,
		 link_tid => $link_tid # for Sequence prefetch
		);
}

sub includes_or {
    my ($self, @items) = @_;
    my ($coll, $memdef) = @$self;

    my $schema = $coll->{storage}{schema};
    my $coll_tid = $coll->root_table;

    my $link_tid = Tangram::Expr::TableAlias->new;
    my $coll_col = $memdef->{coll};
    my $item_col = $memdef->{item};

    my $objects = Set::Object->new
	($coll,
	 Tangram::Expr::LinkTable->new($memdef->{table}, $link_tid)
	);
    my @targets;

    foreach my $item (@items) {
        if (ref $item) {
            if ($item->isa('Tangram::Expr::QueryObject'))
              {
                  push @targets, ('t' . $item->object->root_table.'.'
				  . $schema->{sql}{id_col});
                  $objects->insert( $item->object );
              }
            else
              {
                  push @targets, ($coll->{storage}->export_object($item)
                                  or die "'$item' is not a persistent
object"
                                 );
              }
        }
        else {
            push @targets, $item;
        }
    }

    my $joined_targets = join(',', @targets);
    
        Tangram::Expr::Filter->new
        (
         expr => "t$link_tid.$coll_col = t$coll_tid.$schema->{sql}{id_col} AND t$link_tid.$item_col IN ($joined_targets)",
         tight => 100,      
         objects => $objects,
         link_tid => $link_tid # for Sequence prefetch
        );
}


use overload
    '<' => \&includes,
    fallback => 1;

