package t::Object::Complete::Diamond;
use strict;
use warnings;
use base qw( t::Object::Complete::Sub t::Object::Complete::Sib );
use Object::LocalVars;

give_methods our $self;

our $_count : Class;

sub BUILD : Method {
   ++$_count; 
}

sub DEMOLISH : Method {
    --$_count;
}

sub get_diamondcount : Method { return $_count }

sub report_counts : Method {
    return { 
        grandparent => $self->get_count,
        leftparent  => $self->get_subcount,
        rightparent => $self->get_sibcount,
        diamond     => $self->get_diamondcount,
    };
};

1;
