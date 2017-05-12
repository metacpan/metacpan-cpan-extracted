use strict;
use warnings;
#use feature qw( say );

package 
   Games::Sudoku::Trainer::Found_info;

use version; our $VERSION = qv('0.03');    # PBP

# This package manages a FIFO buffer for scalars. Incoming scalars
# are added to the buffer, the oldest scalar is returned on request.
# If the buffer is empty, "undef" is returned. So "undef" shouldn't
# be presented for addition (this is currently not checked).
# In spite of its name, Found_info doesn't know anything about the
# managed scalars.

my @pending;    # all Found_info objects waiting for processing

# constructor for Found_info objects
#   the new object is added to @pending
#
sub new {
    my $class     = shift;
    my $found_ref = shift;

    #TODO: future enhancement: replace array by named properties
    #    my @props_values = @_;   # property values

    #    my %props;
    #    @props{qw/stratname action clues results/} = (@props_values);
    #say "props ", %props;
    #    my $self = \%props;
    my $self = $found_ref;
    bless $self, $class;

    push @pending, $self;
    return;
}

# getter for Found_info objects
#   return the oldest pending Found_info object for processing
#
sub oldest {

    return shift @pending;
}

1;
