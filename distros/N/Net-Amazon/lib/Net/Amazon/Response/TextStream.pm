######################################################################
package Net::Amazon::Response::TextStream;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Response);

use Net::Amazon::Property;
use Log::Log4perl qw(:easy get_logger);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

##################################################
sub is_page_available {
##################################################
    my($self, $ref, $new_items) = @_;
    DEBUG("TextStream does not allow the fetching of more than one page");
    return 0;
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    return $self->SUPER::list_as_string($self->properties);
}

1;
