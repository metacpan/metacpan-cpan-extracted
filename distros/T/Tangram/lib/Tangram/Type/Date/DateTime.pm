# (c) Sam Vilain, 2004

package Tangram::Type::Date::DateTime;

use strict;
use Tangram::Type::Date::Cooked;
use vars qw(@ISA);
@ISA = qw( Tangram::Type::Date::Cooked );

use DateTime;

use Carp qw(confess);

$Tangram::Schema::TYPES{datetime} = Tangram::Type::Date::DateTime->new;

#
sub get_importer
{
  my $self = shift;
  my $context = shift;
  $self->SUPER::get_importer
      ($context,
       sub { my($iso)=shift;
	     $iso =~ m/^(\d{4})-(\d\d)-(\d\d)T ?(\d?\d):(\d\d):(\d\d)$/
		 or confess "bad ISO format from internal; $iso";
	     return DateTime->new( year => $1,
				   month => $2,
				   day => $3,
				   hour => $4,
				   minute => $5,
				   second => $6 );
	   }
      );
}

sub get_exporter
{
    my $self = shift;
    my $context = shift;
    $self->SUPER::get_exporter($context, sub { (shift)->iso8601 });
}
1;
