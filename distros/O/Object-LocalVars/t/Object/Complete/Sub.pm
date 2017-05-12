package t::Object::Complete::Sub;
use strict;
use warnings;
use base qw( t::Object::Complete );
use Object::LocalVars;

give_methods our $self;

our $color : Pub; # overrides super class definition -- dangerous
our $shape : Pub;
our $_count : Class;

sub BUILD : Method {
    ++$_count; 
}

sub DEMOLISH : Method {
    --$_count;
}

sub get_subcount : Method { return $_count }

sub desc : Method {
    return "I'm " . $self->name . 
           ", my color is " . $self->color .
           " and my shape is $shape";
};

sub can_roll : Method {
    return $shape eq "circle" ? 1 : 0;
}

1;
