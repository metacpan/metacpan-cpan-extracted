

package Tangram::Type::Date::Manip;

use strict;
use Tangram::Type::Date::Cooked;
use vars qw(@ISA);
@ISA = qw( Tangram::Type::Date::Cooked );
use Date::Manip qw(ParseDate UnixDate);

$Tangram::Schema::TYPES{dmdatetime} = Tangram::Type::Date::Manip->new;

#
# Convert iso8601 format to Date::Manip internal format
#
sub get_importer
{
  my $self = shift;
  my $context = shift;

  $self->SUPER::get_importer($context, sub {ParseDate(shift)});
}

# Convert Date::Manip internal format to iso8601 format
sub get_exporter
{
    my $self = shift;
    my $context = shift;
    $self->SUPER::get_exporter
	($context, sub {
	     UnixDate(shift, "%Y-%m-%dT%H:%M:%S")
	 });
}
1;
