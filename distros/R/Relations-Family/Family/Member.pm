# This is a component of a DBI/DBD-MySQL Relational Query Engine module. 

package Relations::Family::Member;
require Exporter;
require DBI;
require 5.004;
require Relations;

use Relations;

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).

# Copyright 2001 GAF-3 Industries, Inc. All rights reserved.
# Written by George A. Fitch III (aka Gaffer), gaf3@gaf3.com

# This program is free software, you can redistribute it and/or modify it under
# the same terms as Perl istelf

$Relations::Family::Member::VERSION = '0.93';

@ISA = qw(Exporter);

@EXPORT    = ();		

@EXPORT_OK = qw(new);

%EXPORT_TAGS = ();

# From here on out, be strict and clean.

use strict;



### Create a Relations::Family::Member object. This
### object is a list of values to select from.

sub new {

  # Get the type we were sent

  my ($type) = shift;

  # Get all the arguments passed

  my ($name,
      $label,
      $database,
      $table,
      $id_field,
      $query,
      $alias) = rearrange(['NAME',
                           'LABEL',
                           'DATABASE',
                           'TABLE',
                           'ID_FIELD',
                           'QUERY',
                           'ALIAS'],@_);

  # Create the hash to hold all the vars
  # for this object.

  my $self = {};

  # Bless it with the type sent (I think this
  # makes it a full fledged object)

  bless $self, $type;

  # Add the info into the hash

  $self->{name} = $name;
  $self->{label} = $label;
  $self->{database} = $database;
  $self->{table} = $table;
  $self->{id_field} = $id_field;
  $self->{query} = $query;
  $self->{alias} = $alias ? $alias : "$self->{table}";

  # Intialize relationships

  $self->{parents} = to_array();
  $self->{children} = to_array();
  $self->{brothers} = to_array();
  $self->{sisters} = to_array();

  # Initialize chosen ids and labels

  $self->{chosen_count} = 0;
  $self->{chosen_ids_string} = '';
  $self->{chosen_ids_array} = to_array();
  $self->{chosen_ids_select} = to_array();

  $self->{chosen_labels_string} = '';
  $self->{chosen_labels_array} = to_array();
  $self->{chosen_labels_hash} = to_hash();
  $self->{chosen_labels_select} = to_hash();

  # Initialize available ids and labels

  $self->{available_count} = 0;
  $self->{available_ids_array} = to_array();
  $self->{available_ids_select} = to_array();

  $self->{available_labels_array} = to_array();
  $self->{available_labels_hash} = to_hash();
  $self->{available_labels_select} = to_hash();

  # Initialize all selection settings 

  $self->{filter} = '';
  $self->{match} = 0;
  $self->{group} = 0;
  $self->{limit} = '';
  $self->{ignore} = 0;

  # Give thyself

  return $self;

}



### Returns text info about the Relations::Family::Member 
### object. Useful for debugging and export purposes.

sub to_text {

  # Know thyself

  my ($self) = shift;

  # Get the indenting string and current
  # indenting amount.

  my ($string,$current) = @_;

  # Calculate the ident amount so we don't 
  # do it a bazillion times.

  my $indent = ($string x $current);
  my $subindent = ($string x ($current + 1));

  # Create a text string to hold everything

  my $text = '';

  # 411

  $text .= $indent . "Relations::Family::Member: $self\n\n";
  $text .= $indent . "Name: $self->{name}\n";
  $text .= $indent . "Label: $self->{label}\n";
  $text .= $indent . "Database: $self->{database}\n";
  $text .= $indent . "Table: $self->{table}\n";
  $text .= $indent . "Alias: $self->{alias}\n";
  $text .= $indent . "ID Field: $self->{id_field}\n";
  $text .= $indent . "Query:\n";

  $text .= $self->{query}->to_text($string,$current + 1);

  $text .= $indent . "Chosen Count: $self->{chosen_count}\n";
  $text .= $indent . "Chosen IDs and Labels: \n";

  foreach my $id (@{$self->{chosen_ids_array}}) {

    $text .= $subindent . "ID: $id ";
    $text .= $subindent . "Label: $self->{chosen_labels_hash}->{$id}\n";

  }

  $text .= $indent . "Filter:  $self->{filter}\n";
  $text .= $indent . "Match:  $self->{match}\n";
  $text .= $indent . "Group:  $self->{group}\n";
  $text .= $indent . "Limit:  $self->{limit}\n";
  $text .= $indent . "Ignore:  $self->{ignore}\n";

  $text .= $indent . "Available IDs and Labels: \n";

  foreach my $id (@{$self->{available_ids_array}}) {

    $text .= $subindent . "ID: $id ";
    $text .= $subindent . "Label: $self->{available_labels_hash}->{$id}\n";

  }

  $text .= $indent . "Parents: \n";

  foreach my $member (@{$self->{parents}}) {

    $text .= $subindent . "Label: $member->{label} ";
    $text .= $subindent . "Name: $member->{name} ";
    $text .= $subindent . "Member: $member\n";

  }

  $text .= $indent . "Children: \n";

  foreach my $member (@{$self->{children}}) {

    $text .= $subindent . "Label: $member->{label} ";
    $text .= $subindent . "Name: $member->{name} ";
    $text .= $subindent . "Member: $member\n";

  }

  $text .= $indent . "Brothers: \n";

  foreach my $member (@{$self->{brothers}}) {

    $text .= $subindent . "Label: $member->{label} ";
    $text .= $subindent . "Name: $member->{name} ";
    $text .= $subindent . "Member: $member\n";

  }

  $text .= $indent . "Sisters: \n";

  foreach my $member (@{$self->{sisters}}) {

    $text .= $subindent . "Label: $member->{label} ";
    $text .= $subindent . "Name: $member->{name} ";
    $text .= $subindent . "Member: $member\n";

  }

  $text .= "\n";

  # Return the text

  return $text;

}

$Relations::Family::Member::VERSION;