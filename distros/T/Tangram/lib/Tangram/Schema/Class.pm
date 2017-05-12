
package Tangram::Schema::Class;

use strict;

use Tangram::Schema::Node;
use vars qw(@ISA);
 @ISA = qw( Tangram::Schema::Node );

# XXX - not reached by test suite
sub members
{
   my ($self, $type) = @_;
   return @{$self->{$type}};
}

sub is_root
  {
	!@{ shift->{BASES} }
  }

sub get_direct_fields
  {
	map { values %$_ } values %{ shift->{fields} }
  }

# XXX - not reached by test suite
sub get_table { shift->{table} }

*direct_fields = \&get_direct_fields;

sub get_import_cols {
  my ($self, $context) = @_;
  my $table = $self->{table};
  map { map { [ $table, $_ ] } $_->get_import_cols($context) } $self->get_direct_fields()
}

sub get_export_cols {
  my ($self, $context) = @_;
  my $table = $self->{table};
  map { map { [ $table, $_ ] } $_->get_export_cols($context) } $self->get_direct_fields()
}

