package t::Object::Complete::Sib;
use strict;
use warnings;
use base qw( t::Object::Complete );
use Object::LocalVars;

give_methods our $self;

our $_count : Class;

sub BUILD : Method {
   ++$_count; 
}

sub DEMOLISH : Method {
    --$_count;
}

sub get_sibcount : Method { return $_count }

1;
