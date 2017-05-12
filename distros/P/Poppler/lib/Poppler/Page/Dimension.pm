package Poppler::Page::Dimension;

#----------------------------------------------------------------------------#
# This class is provided purely for the purpose of backward compatibility with
# versions of Poppler earlier than 1.01.
#----------------------------------------------------------------------------#

use strict;
use warnings;
use Carp;

sub new {

    my ($class, $w, $h) = @_;

    my $self = bless {}, $class;
    $self->{w} = $w;
    $self->{h} = $h;

    return $self;

}

sub get_width {

    my ($self) = @_;
    return $self->{w};

}

sub get_height {

    my ($self) = @_;
    return $self->{w};

}

1;
