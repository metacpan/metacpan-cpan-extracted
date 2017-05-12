# used in Tangram::Storage methods cursor_object and query_objects
package Tangram::Expr::RDBObject;

use strict;
use Tangram::Expr::CursorObject;

use vars qw(@ISA);
 @ISA = qw( Tangram::Expr::CursorObject );

sub where
{
	return join ' AND ', &where unless wantarray;

	my ($self) = @_;
   
	my $storage = $self->{storage};
	my $schema = $storage->{schema};
	my $classes = $schema->{classes};
	my $tables = $self->{tables};
	my $root = $tables->[0][1];
	my $class = $self->{class};

	my @where_class_id;

	if (0 and $classes->{$class}{stateless})
	{
		my @class_ids;

		push @class_ids, $storage->class_id($class)
		    unless $classes->{$class}{abstract};

		$schema->for_each_spec
		    ($class,
		     sub {
			 # XXX - not reached by test suite
			 my $spec = shift;
			 push @class_ids, $storage->class_id($spec)
			     unless $classes->{$spec}{abstract};
		     } );

	}

	@where_class_id = "t$root.$storage->{class_col} IN ("
	    . join(', ', $storage->_kind_class_ids($class) ) . ')';

	my $id = $schema->{sql}{id_col};
	return (@where_class_id, map { "t@{$_}[1].$id = t$root.$id" } @$tables[1..$#$tables]);
}

1;
