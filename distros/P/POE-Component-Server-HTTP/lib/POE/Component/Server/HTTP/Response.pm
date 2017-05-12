use strict;
package POE::Component::Server::HTTP::Response;

use vars qw(@ISA);
use HTTP::Response;
@ISA = qw(HTTP::Response);

use POE;

sub streaming {
    my $self = shift;
    if (@_) {
        if ($_[0]) {
            $self->{streaming} = 1;
        }
        else {
            $self->{streaming} = 0;
        }
    }
    return $self->{streaming};
}

sub is_error {
    my $self = shift;
    if (@_) {
        if ($_[0]) {
            $self->{is_error} = 1;
        }
        else {
            $self->{is_error} = 0;
        }
    }
    return $self->{is_error};
}

sub send {
    my $self = shift;
    $self->{connection}->{wheel}->put(@_);
}

sub continue {
    my $self = shift;
    $poe_kernel->post($self->{connection}->{session},
                      'execute' => $self->{connection}->{my_id});
}

sub close {
    my $self = shift;
    $self->{streaming} = 0;
    shift @{$self->{connection}->{handlers}->{Queue}};
}

1;
