package t::Object::PropAliases;
use strict;
use warnings;
use Object::LocalVars;

give_methods our $self;

our $name : Pub;
our $color : Pub;
our $_count : Class;

sub desc : Method {
    return "I'm $name and I'm $color";
};

sub inc_count { ++$_count };
sub get_count {         
    no warnings 'uninitialized';
    return "$name ($color) is one of $_count" 
};


1;
