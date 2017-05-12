use strict;
package POE::Component::Server::HTTP::Request;

use vars qw(@ISA);
use HTTP::Request;
@ISA = qw(HTTP::Request);

sub new {
    my $package = shift;
    my $self = $package->SUPER::new(@_);
    $self->is_error($self->method eq 'ERROR');
    return $self
}

sub connection {
    return $_[0]->{connection};
}

sub is_error {
    my $self = shift;
    if (@_) {
        if($_[0]) {
            $self->{is_error} = 1;
        } else {
            $self->{is_error} = 0;
        }
    }
    return $self->{is_error};
}

1;
