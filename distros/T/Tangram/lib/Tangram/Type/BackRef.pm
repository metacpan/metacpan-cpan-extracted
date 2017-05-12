
package Tangram::Type::BackRef;

use Tangram::Lazy::BackRef;
use strict;

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Scalar );

$Tangram::Schema::TYPES{backref} = __PACKAGE__->new;

sub get_export_cols
  {
	()
  }

sub get_exporter
  {
  }

sub get_importer
{
  my ($self, $context) = @_;
  my $field = $self->{name};

  return sub {
	my ($obj, $row, $context) = @_;

	my $rid = shift @$row;

	if ($rid) {
	  tie $obj->{$field}, 'Tangram::Lazy::BackRef', $context->{storage}, $context->{id}, $self->{name}, $rid, $self->{class}, $self->{field};
	} else {
	  $obj->{$field} = undef;
	}
  }
}

#---------------------------------------------------------------------
#  Tangram::Type::BackRef->coldefs(...)
#
#  BackRefs do not set up any columns by default.
#---------------------------------------------------------------------
sub coldefs
{
    return ();
}

1;
