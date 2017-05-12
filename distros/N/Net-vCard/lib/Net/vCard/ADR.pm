
package Net::vCard::ADR;

use strict;
use warnings;


sub new {
    my $class=shift;
    $class = ref($class) if ref($class);
    my $self=shift || {};

    return bless $self, $class;

}

sub country {
    if (exists $_[1]) {
        $_[0]->{'country'}=$_[1];
    }
    return $_[0]->{'country'};
}

sub poBox {
    if (exists $_[1]) {
        $_[0]->{'poBox'}=$_[1];
    }
    return $_[0]->{'poBox'};
}

sub city {
    if (exists $_[1]) {
        $_[0]->{'city'}=$_[1];
    }
    return $_[0]->{'city'};
}

sub region {
    if (exists $_[1]) {
        $_[0]->{'region'}=$_[1];
    }
    return $_[0]->{'region'};
}

sub address {
    if (exists $_[1]) {
        $_[0]->{'address'}=$_[1];
    }
    return $_[0]->{'address'};
}

sub postalCode {
    if (exists $_[1]) {
        $_[0]->{'postalCode'}=$_[1];
    }
    return $_[0]->{'postalCode'};
}

sub extendedAddress {
    if (exists $_[1]) {
        $_[0]->{'extendedAddress'}=$_[1];
    }
    return $_[0]->{'extendedAddress'};
}


1;
