package Panotools::Script::Line::Output;

use strict;
use warnings;
use Panotools::Script::Line::Image;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line::Image/;

=head1 NAME

Panotools::Script::Line::Output - Panotools output image

=head1 SYNOPSIS

A single output image is described by an 'o' line

=head1 DESCRIPTION

Basically similar to an 'i' line.

=cut

sub Identifier
{
    my $self = shift;
    return "o";
}

1;

