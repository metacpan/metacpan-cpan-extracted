package Object::WithParams;

use warnings;
use strict;
use Carp qw/ croak /;

=pod

=head1 NAME

Object::WithParams - An Object With Params

=head1 VERSION

Version 0.3

=cut

our $VERSION = '0.3';

=head1 SYNOPSIS

    use Object::WithParams;

    my $thingy = Object::WithParams->new();

    # set a param
    $thingy->param(veggie => 'tomato');
    
    # get a param
    my $veggie = $thingy->param('veggie'); # $veggie eq 'tomato'
    
    # get all params
    my @params = $thingy->param(); # @params == ('veggie')
    
    # clone a Object::WithParams
    my $doodad = $thingy->clone; # $doodad->param('veggie') == 'tomato'

    # delete a param
    $thingy->delete('veggie');
    
    # delete all params
    $thingy->clear();
    
=head1 DESCRIPTION

Use this module to create objects that do nothing except contain parameters 
defined by you which you can get and set as you wish.  Many modules such as 
L<Data::FormValidator> have methods that accept an object with a param()
method and this object should be compatible with all of them.

This module really ought to be a role but there is no standardized way to 
do that in Perl 5.  (Not everyone uses L<Moose>.)

=head1 METHODS

=head2 new

Creates a new, empty L<Object::WithParams>.

my $thingy = Object::WithParams->new;

=cut

sub new {
    my ($class) = @_;

    my $self = {};

    return bless $self, $class;
}

=head2 clear

Deletes all the extent parameters.  Does not return anything.

$thingy->clear();

=cut

sub clear {
    my ($self) = @_;

    foreach my $param ( keys %{$self} ) {
        delete $self->{$param};
    }

    return;
}

=head2 clone

Returns a new L<Object::WithParams> with the same set of parameters as the
old one.

my $doodad = $thingy->clone();
    
=cut

sub clone {
    my ($self) = @_;

    my $clone = Object::WithParams->new();

    foreach my $param ( $self->param() ) {
        $clone->param( $param => $self->param($param) );
    }

    return $clone;
}

=head2 delete

Delete the named parameter.

$thingy->delete('veggie');

=cut

sub delete {    ## no critic 'Subroutines::ProhibitBuiltinHomonyms'
    my ( $self, $param ) = @_;

    if ( defined $param && exists $self->{$param} ) {
        delete $self->{$param};
    }

    return;
}

=head2 param

The C<param> method can be called in three ways.

=over 4

=item with no arguments.

Returns a list of the parameters contained in the object.

my @params = $thingy->param();
    
=item with a single scalar argument.

The value of the parameter with the name of the argument will be returned.

my $color = $thingy->param('color');

=item with named arguments

A parameter is created for one or more sets of  keys and values. 

$thingy->param(filename => 'logo.jpg', height => 50, width => 100);

You could also use a hashref.

my $arg_ref = { filename => 'logo.jpg', height => 50, width => 100 };
$thingy->param($arg_ref);

The value of a parameter need not be a scalar, it could be any any sort of
reference even a coderef.

$thingy->param(number => &pick_a_random_number);

Does not return anything.

=back

=cut

sub param {
    my ( $self, @args ) = @_;

    my $num_args = scalar @args;
    if ($num_args) {
        if ( ref $args[0] eq 'HASH' ) {    # a hashref
            %{$self} = ( %{$self}, %{ $args[0] } );
        }
        elsif ( $num_args % 2 == 0 ) {     # a hash
            %{$self} = ( %{$self}, @args );
        }
        elsif ( $num_args == 1 ) {         # a scalar
            return $self->{ $args[0] };
        }
        else {
            croak('Odd number of arguments passed to param().');
        }
    }
    else {
        return keys %{$self};
    }
    return;
}

=head1 BUGS

Not all possible param handling functionality is supported.  Should it be?

Please report any bugs or feature requests to 
C<bug-object-withparams at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-WithParams>.  I will 
be notified, and then you'll automatically be notified of progress on your 
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Object::WithParams


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-WithParams>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-WithParams>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-WithParams>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-WithParams/>

=back

=head1 AUTHOR

Jaldhar H. Vyas, E<lt>jaldhar at braincells.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010,  Consolidated Braincells Inc. All Rights Reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version, or

b) the Artistic License version 2.0.

The full text of the license can be found in the LICENSE file included
with this distribution.

=cut

1;

