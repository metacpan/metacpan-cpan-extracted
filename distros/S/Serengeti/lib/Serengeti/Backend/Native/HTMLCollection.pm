package Serengeti::Backend::Native::HTMLCollection;

use strict;
use warnings;

sub new {
    my ($pkg, @elements) = @_;
    my $self = bless \@elements, $pkg;
    return $self;
}

sub get_property {
    my ($self, $property) = @_;
    
    if ($property eq "length") {
        return scalar @$self;
    }
    
    if ($property =~ /^\d+$/) {
        return $self->[$property];
    }
    
    my $name = lc $property;
    for (@$self) {
        my $form_name = $_->attr("name");
        next unless defined $form_name;
        return $_ if lc $form_name eq $name;
    }
    
    return;
}

1;