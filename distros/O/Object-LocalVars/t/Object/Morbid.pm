package t::Object::Morbid;
use strict;
use warnings;
use Carp;

use Object::LocalVars;

give_methods our $self;

sub do_die : Method {
    die "Died";
};

sub do_croak : Method {
    croak "Croaked";
};

sub do_confess : Method {
    confess "Confessed";
};

sub do_croak_removed : Method {
    $self->do_croak;
}

sub BUILD : Method {
    my ($inherit_test_flag) = @_;
    # helps us trap inherited BUILD
    return if ! $inherit_test_flag;
    die "BUILD shouldn't be called via inheritance" 
        if ref($self) ne __PACKAGE__ ;
}

sub PREBUILD {
    my ($superclass, @args) = @_;
    # helps us trap inherited PREBUILD -- this shouldn't be called at all
    die "PREBUILD shouldn't be called with when no superclasses exist";
}

my $demolish_count = 0;
sub DEMOLISH {
    # helps us trap inherited DEMOLISH
    $demolish_count++;
    die "DEMOLISH shouldn't be called via inheritance" if $demolish_count > 1;
}

1;
