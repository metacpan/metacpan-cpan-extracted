package t::Object::Paranoid;
use strict;
use warnings;
use Object::LocalVars;

give_methods our $self;

our $name : Pub;
our $_count : Class;

sub BUILD : Method {
    my %init = @_;
    my @badargs = grep { $_ ne 'name' } keys %init;
    die "Bad values in new():" . join(" ", @badargs) if @badargs;
    ++$_count;
    $name = $init{"name"};
}

sub get_count : Method { return $_count };

1;
