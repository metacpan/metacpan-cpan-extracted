
package Tangram::Type::Scalar;

use strict;
use Tangram::Type;

use vars qw(@ISA);
BEGIN { @ISA = qw( Tangram::Type ); }

use Tangram::Type::Real;
use Tangram::Type::Integer;
use Tangram::Type::Number;
use Tangram::Type::String;

sub reschema
{
    my ($self, $members, $class, $schema) = @_;

    if (ref($members) eq 'ARRAY')
    {
	# XXX - not tested by test suite
		# short form
		# transform into hash: { fieldname => { col => fieldname }, ... }
		$members = $_[1] = map { $_ => { col => $schema->{normalize}->($_, 'colname') } } @$members;
    }
    
    for my $field (keys %$members)
    {
		my $def = $members->{$field};

		unless (ref($def))
		{
			# not a reference: field => field
			$def = $members->{$field} = { col => $schema->{normalize}->(($def || $field), 'fieldname') };
		}

		$self->field_reschema($field, $def, $schema);
    }

    return keys %$members;
}

sub field_reschema
  {
	my ($self, $field, $def, $schema) = @_;
	$def->{col} ||= $schema->{normalize}->($field, 'colname');
  }

sub query_expr
{
    my ($self, $obj, $memdefs, $tid, $storage) = @_;
    return map { $storage->expr($self, "t$tid.$memdefs->{$_}{col}", $obj) } keys %$memdefs;
}

sub remote_expr
{
    my ($self, $obj, $tid, $storage) = @_;
    $storage->expr($self, "t$tid.$self->{col}", $obj);
}

sub get_exporter
  {
	my ($self) = @_;
	return if $self->{automatic};
	my $field = $self->{name};
	return "exists \$obj->{q{$field}} ? \$obj->{q{$field}} : undef";
  }

sub get_importer
  {
	my ($self) = @_;
	return "\$obj->{q{$self->{name}}} = shift \@\$row";
  }

sub get_export_cols
{
  return shift->{col};
}

sub get_import_cols
{
    my ($self, $context) = @_;
	return $self->{col};
}

sub literal
{
    my ($self, $lit) = @_;
    return $lit;
}

sub content
{
    shift;
    shift;
}

#---------------------------------------------------------------------
#  Tangram::Type::Scalar->_coldefs($cols, $members, $sql, $schema)
#
# Adds entries to the current table mapping for the columns for a
# single class of a given type.  Inheritance is not in the picture
# yet.
#
# $cols is the columns definition for the current table mapping
# $members is the `members' property of the current class (ie, the
#          members for a particular data type, eg string => $members)
# $sql is the SQL type to default columns to
# $schema is the Tangram::Schema object
#---------------------------------------------------------------------
sub _coldefs
{
    my ($self, $cols, $members, $sql, $schema) = @_;

    for my $def (values %$members)
	{
	    $cols->{ $def->{col} } =
		(
		 $def->{sql} ||
		 "$sql " . ($schema->{sql}{default_null} || "")
		);
	}
}

1;
