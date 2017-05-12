# This is a submodule of the Relations Display module. It's
# used to store info used to generate a Display object.

package Relations::Display::Table;
require Exporter;
require DBI;
require 5.004;
require Relations;

use Relations;

# Copyright 2001 GAF-3 Industries, Inc. All rights reserved.
# Written by George A. Fitch III (aka Gaffer), gaf3@gaf3.com

# This program is free software, you can redistribute it and/or modify it under
# the same terms as Perl istelf

$Relations::Display::Table::VERSION = '0.92';

@ISA = qw(Exporter);

@EXPORT    = ();		

@EXPORT_OK = qw();

%EXPORT_TAGS = ();

# From here on out, be strict and clean.

use strict;



### Create a Relations::Family::Table object. This
### object holds data in a format that is useful to
### Relations::Display

sub new {

  # Get the type we were sent

  my ($type) = shift;

  # Get all the arguments passed

  my ($title,
      $x_label,
      $y_label,
      $legend_label,
      $x_axis_values,
      $legend_values,
      $x_axis_titles,
      $legend_titles,
      $y_axis_values) = rearrange(['TITLE',
                                   'X_LABEL',
                                   'Y_LABEL',
                                   'LEGEND_LABEL',
                                   'X_AXIS_VALUES',
                                   'LEGEND_VALUES',
                                   'X_AXIS_TITLES',
                                   'LEGEND_TITLES',
                                   'Y_AXIS_VALUES'],@_);

  # $title - Label for the table
  # $x_label - Label for the x axis data
  # $y_label - Label for the y axis data
  # $legend_label - Label for the legend data
  # $x_axis_values - Array ref of the actual x axis values,
  #                   what they're stored as.
  # $legend_values - Array ref of the actual legend values
  #                   what they're stored as.
  # $x_axis_titles - Hash ref of the displayed x axis values,
  #                  what's shown on the graph.
  # $legend_titles - Hash ref of the displayed legend values,
  #                  what's shown on the graph.
  # $y_axis_values - 2D Hash ref of the y axis values keyed by 
  #                  x_axis and legend values.

  # Create the hash to hold all the vars
  # for this object.

  my $self = {};

  # Bless it with the type sent (I think this
  # makes it a full fledged object)

  bless $self, $type;

  # Add the info into the self hash

  $self->{title} = $title if $title;
  $self->{x_label} = $x_label if $x_label;
  $self->{y_label} = $y_label if $y_label;
  $self->{legend_label} = $legend_label if $legend_label;

  $self->{x_axis_values} = to_array($x_axis_values) if $x_axis_values;
  $self->{legend_values} = to_array($legend_values) if $legend_values;
  $self->{x_axis_titles} = to_hash($x_axis_titles) if $x_axis_titles;;
  $self->{legend_titles} = to_hash($legend_titles) if $legend_titles;

  # If they sent a $y_axis_values argument, we 
  # have to make sure we clone both dimensions 
  # of the hash.

  if ($y_axis_values) {

    # Clone the first dimension.

    $y_axis_values = to_hash($y_axis_values);

    # Go through all second dimensions.

    foreach my $key (keys %$y_axis_values) {

      # Clone the second dimension.

      $y_axis_values->{$key} = to_hash($y_axis_values->{$key});

    }

    # Set our data to this complete clone.

    $self->{y_axis_values} = $y_axis_values;

  }

  # Return thyself 

  return $self;

}



### Create a copy of this table

sub clone {

  # Know thyself

  my ($self) = shift;

  # Return a new table object

  return new Relations::Display::Table(-title         => $self->{title},
                                       -x_label       => $self->{x_label},
                                       -y_label       => $self->{y_label},
                                       -legend_label  => $self->{legend_label},
                                       -x_axis_values => $self->{x_axis_values},
                                       -legend_values => $self->{legend_values},
                                       -x_axis_titles => $self->{x_axis_titles},
                                       -legend_titles => $self->{legend_titles},
                                       -y_axis_values => $self->{y_axis_values});
}

$Relations::Display::Table::VERSION;