package MojoX::Moose::Controller;

our $VERSION = '0.02';

use Moose;
use MooseX::NonMoose;
extends 'Mojolicious::Controller';

#-------------------------------------------------------------------------------

sub BUILDARGS {
    my $class = shift;
    my $self = Mojo::Base->new(@_);

    return $self;
}

#-------------------------------------------------------------------------------

1;

=head1 NAME
 
MooseX::Mojolicious::Controller - A Moose based Mojolicious controller

=head1 SYNOPSIS

    package MooseX::Mojolicious::Controller;

    use Moose;
    extends 'MooseX::Mojolicious::Controller';


=head1 DESCRIPTION

Abstract base for Moose based Mojolicious controllers.

=cut
