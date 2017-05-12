package t::Object::Paranoid::Sub;
use strict;
use warnings;
use base 't::Object::Paranoid';
use Object::LocalVars;

give_methods our $self;

our $color : Pub;

sub PREBUILD {
    my ($super, %input) = @_;
    return exists $input{name} ? (name => $input{name}) : ();
}

sub BUILD : Method {
    my %input = @_;
    $color = $input{color};
}

1;
