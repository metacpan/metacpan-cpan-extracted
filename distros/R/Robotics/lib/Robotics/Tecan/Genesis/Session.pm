
package Robotics::Tecan::Genesis::Session;

# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

#
# Tecan Genesis
# Session layer: configuration handling of the 'attached' hardware
#

use warnings;
use strict;
use Moose::Role;
#extends 'Robotics::Tecan::Genesis';

use YAML::XS;


my $Debug = 1;

=head1 NAME

Robotics::Tecan::Genesis::Session - (Internal module)
Handler for a user session to the physical hardware

=head2 configure

Internal function.  Configures internal data from user file.

Returns 0 on error, status string if OK.

=cut

sub configure {
	# self is Robotics::Tecan
	
	my $self    = shift;
    my $cref    = shift;
    my $section;
    for $section (keys %{$cref}) {
        warn "Configuring $section\n";
        if ($section =~ m/points/i) {
            $self->POINTS( $cref->{$section} );
        }
        elsif ($section =~ m/objects/) { 
            $self->OBJECTS( $cref->{$section} );
        }
    }

    return 1;
}

1;    # End of Robotics::Tecan::Genesis::Session

__END__
