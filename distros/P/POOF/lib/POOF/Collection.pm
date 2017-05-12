package POOF::Collection;

use 5.007;
use strict;
use warnings;

use base qw(POOF);

use B::Deparse;
use Attribute::Handlers;
use Scalar::Util qw(blessed refaddr);
use Carp qw(croak confess);

use POOF::Properties::Array;
use POOF::DataType;

our $VERSION = '1.2';
our $TRACE = 1;
our $RAISE_EXCEPTION = 'trap';

#-------------------------------------------------------------------------------
use constant PROPERTIES      => { };
use constant PROPERTYINDEX   => { };
use constant METHODS         => { };
use constant GROUPS          => { };
use constant PROPBACKREF     => { };
use constant PROPBACKDOOR    => { };
use constant CLASSES         => { };
use constant METHODDISPATCH  => { };
use constant ENCFQCLASSNAMES => { };
use constant PROCESSEDFILES  => { };
use constant PARENT          => { };

#-------------------------------------------------------------------------------
# access levels
use constant ACCESSLEVEL =>
{
    'Private'   => 0,
    'Protected' => 1,
    'Public'    => 2,
};

#-------------------------------------------------------------------------------
sub new
{
    my $class = shift;
    my %args = @_;
    
    confess "This class cannot be instantiated as a stand along object, it must be inherited instead"
        if $class eq 'POOF';
    
    my $def =
    {
        'class'     => $class,
        'name'      => $args{'name'},
        'access'    => $args{'access'},
        'otype'     => $args{'otype'},
        'maxsize'   => $args{'maxsize'},
        'data'      => $args{'data'},
        'container' => $args{'container'},
        'args'      => $args{'args'} || {},
        'RaiseException' => $args{'RaiseException'},
    };

    my $obj;
    tie @{$obj}, 'POOF::Properties::Array', $def, $class, \&POOF::pErrors, \+PROPBACKREF;
    bless $obj,$class;
    +PROPBACKREF->{ $class }->RefObj($obj);
    
    
    $RAISE_EXCEPTION = $args{'RaiseException'}
        if exists $args{'RaiseException'};
    
    $obj->_init( @_ );
    return $obj;
}

sub _init
{
    my $obj = shift;
    my %args = @_;
    $obj->pParent($args{'container'});
    return (@_);
}

sub pPropertyDefinition
{
    my ($obj) = @_;
    return +PROPBACKREF->{ ref($obj) }->Definition;
}

sub pOID { refaddr( $_[0] ) }

sub pParent
{
    my $obj = shift;
    return
        @_
            ? +PARENT->{ $obj->pOID } = shift
            : +PARENT->{ $obj->pOID };
}    

1;
__END__

=head1 NAME

POOF::Collection - Perl extension that provides stronger typing, encapsulation
and inheritance but unlike POOF it has an array as the core structure.

=head1 SYNOPSIS

    package MyClass;
    use base qw(POOF::Collection);
  
=head1 DESCRIPTION

A collection is like a list but it allows for methods that manipulate its own
contents.  It also enforces the type of its elements.  Most of the information
on POOF applies to POOF::Collections except thing that relate to properties and
groups since the collection class does not have properties or groups only collection
elements.

=head1 SEE ALSO

POOF man page.

=head1 AUTHOR

Benny Millares <bmillares@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Benny Millares

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


