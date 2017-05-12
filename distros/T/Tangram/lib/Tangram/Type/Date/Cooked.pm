# (c) Sam Vilain, 2004

package Tangram::Type::Date::Cooked;

use strict;
use Tangram::Type::TimeAndDate;
use vars qw(@ISA);
@ISA = qw( Tangram::Type::TimeAndDate );

$Tangram::Schema::TYPES{cookeddatetime} = Tangram::Type::Date::Cooked->new;

sub get_importer
{
  my $self = shift;
  my $context = shift;
  my $closure = shift;
  my $type = shift || "date";
  my $name = $self->{name};

  return sub {
	my ($obj, $row, $context) = @_;
	my $val = shift @$row;

	$val = $context->{storage}->from_dbms($type, $val)
	    if defined $val;
	$val = $closure->($val) if defined $val and $closure;

	$obj->{$name} = $val;
  }
}

sub get_exporter
{
    my $self = shift;
    my $context = shift;
    my $closure = shift;
    my $type = shift || "date";
    my $name = $self->{name};

    return sub {
	my ($obj, $context) = @_;
	my $val = $obj->{$name};

	$val = $closure->($val) if defined $val and $closure;
	$val = $context->{storage}->to_dbms($type, $val)
	    if defined $val;

	return $val;
    }
}
1;
