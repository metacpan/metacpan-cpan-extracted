package Tangram::Type;

use strict;
use Carp;

my %instances;

sub instance
{
	my $pkg = shift;
	return $instances{$pkg} ||= bless { }, $pkg;
}

sub new {
    my $inv = shift;
    return $inv->instance(@_);
}

# XXX - not reached.  possible refactor point
sub reschema
{
}

# XXX - not reached.  possible refactor point
sub members
{
   my ($self, $members) = @_;
   keys %$members;
}

# XXX - not reached.  possible refactor point
sub query_expr
{
}

# XXX - not reached.  possible refactor point
sub remote_expr
{
}

sub erase
{
}

sub read_data
{
	my ($self, $row) = @_;
	shift @$row;
}

# XXX - not reached.  possible refactor point
sub read
{
   my ($self, $row, $obj, $members) = @_;
	
	foreach my $key (keys %$members)
	{
		$obj->{$key} = $self->read_data($row)
	}
}

# XXX - not reached.  possible refactor point
sub prefetch
{
}

sub expr
{
	return Tangram::Expr->new( @_ );
}

# XXX - not reached.  possible refactor point
sub get_exporters
  {
	my ($self, $fields, $context) = @_;
	return map { $fields->{$_}->get_exporter($context) } keys %$fields;
  }

# XXX - not reached.  possible refactor point
sub get_importer
  {
	my $type = ref shift();
	die "$type does not implement new get_importer method";
  }

# XXX - not reached.  possible refactor point
sub get_exporter
  {
	my $type = ref shift();
	die "$type does not implement new get_exporter method";
  }

sub get_export_cols
  {
	()
  }

# XXX - not reached.  possible refactor point
sub get_intrusions {
}


1;
