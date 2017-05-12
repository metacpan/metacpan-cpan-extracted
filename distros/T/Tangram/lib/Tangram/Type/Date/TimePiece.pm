# (c) Sam Vilain, 2004

package Tangram::Type::Date::TimePiece;

use strict;
use Tangram::Type::Date::Cooked;
use vars qw(@ISA);
@ISA = qw( Tangram::Type::Date::Cooked );

use Time::Piece;

$Tangram::Schema::TYPES{timepiece} = Tangram::Type::Date::TimePiece->new;

#
# Convert SQL DATETIME format to Date::Manip internal format; assume
# that "ParseDate" will magically do The Right Thing(tm)
#
sub get_importer
{
  my $self = shift;
  my $context = shift;
  $self->SUPER::get_importer
      ($context, sub {
	   Time::Piece->strptime(shift, "%Y-%m-%dT%H:%M:%S" );
	   });
}

#
# Convert Date::Manip internal format (ISO-8601) to format that should
# work with most databases (read: I've only tested with MySQL but the
# value is sensible)
#
# Of course, some databases don't like to try and guess date formats,
# even when they're in nice forms.  So, allow a hook for reformatting
# dates.
#
sub get_exporter
{
    my $self = shift;
    my $context = shift;
    $self->SUPER::get_exporter($context, sub { shift->datetime });
}
1;
