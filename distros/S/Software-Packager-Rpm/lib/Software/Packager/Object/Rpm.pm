################################################################################
# Name:		Software::Packager::Object::Rpm.pm
# Description:	This module is used by Packager for holding data for a each item
#

package		Software::Packager::Object::Rpm;

####################
# Standard Modules
use strict;
#use File::Basename;
# Custom modules
use Software::Packager::Object;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Software::Packager::Object );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.01;

####################
# Functions

################################################################################
# Function:	kind()

=head2 B<kind()>

This method returns the kind for this object.

=cut
sub kind
{
	my $self = shift;
	return $self->get_value('KIND');
}

1;
__END__
