package Sash::CommandHash;

use strict;
use warnings;

use base qw( Class::Accessor );
use Carp;

Sash::CommandHash->mk_accessors( qw( base ) );

sub new {
    my $class = shift;
    my $base = shift;

    my $self = bless { base => $base }, ref $class || $class;

    return $self;
}


# Save ourselves some typing when creating new methods.

sub build {
    my $self = shift;
    my $args = shift; #hashref
    
    # Validate we were invoked correctly.
    croak __PACKAGE__ . '->get - Not a class method' unless ref $self;
    croak __PACKAGE__ . '->get - hashref required' unless ref $args eq 'HASH'; 
    croak __PACKAGE__ . '->get - argument use must be defined' unless defined $args->{use};
    
    my $use = $args->{use};
    my $proc = $args->{proc} || 'proc'; 
    my $base = $self->base || 'Sash'; 
    
    my @methods = (  'desc', 'doc', $proc );
    push @methods, 'args' if ( $use =~ /^help|history$/ );

    # Its maptastic! Create the anonymous hash for our command of the form
    # {
    #     desc => \&Base::Class::clear_desc,
    #     doc => \&Base::Class::clear_doc,
    #     proc => \&Base::Class::clear_proc,
    # }
    return { map { my $method_name = $self->base . "::${use}_$_"; $_ => \&$method_name } @methods };
}


1;
