# This is a DBI/DBD-MySQL Relational Query Engine module. 

package Relations::Family;
require Exporter;
require DBI;
require 5.004;
require Relations;
require Relations::Query;
require Relations::Abstract;

use Relations;
use Relations::Query;
use Relations::Abstract;
use Relations::Family::Member;
use Relations::Family::Lineage;
use Relations::Family::Rivalry;
use Relations::Family::Value;

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).

# Copyright 2001 GAF-3 Industries, Inc. All rights reserved.
# Written by George A. Fitch III (aka Gaffer), gaf3@gaf3.com

# This program is free software, you can redistribute it and/or modify it under
# the same terms as Perl istelf

$Relations::Family::VERSION = '0.94';

@ISA = qw(Exporter);

@EXPORT    = ();		

@EXPORT_OK = qw(new);

%EXPORT_TAGS = ();

# From here on out, be strict and clean.

use strict;



### Create a Relations::Family object.

sub new {

  # Get the type we were sent

  my ($type) = shift;

  # Get the argument passed

  my ($abstract) = shift;

  # $abstract - Relations::Abstract module for dbh stuff

  # Create the hash to hold all the vars
  # for this object.

  my $self = {};  

  # Bless it with the type sent (I think this
  # makes it a full fledged object)

  bless $self, $type;

  # Die if they didn't send an abstract

  die "Relations::Family requires a Relations::Abstract object!" unless ($abstract);

  # Add the info into the hash.

  $self->{abstract} = $abstract;

  # Create an array and a hash of members, a 
  # a hash lookup by name of members, a hash
  # lookup by label of members, and a hash 
  # lookup by name of values. Store the 
  # references into the object

  $self->{members} = to_array();
  $self->{names} = to_hash();
  $self->{labels} = to_hash();
  $self->{'values'} = to_hash();

  # Give thyself

  return $self;

}



### Adds a member to this family. 

sub add_member {

  # Know thyself

  my ($self) = shift;

  # Get all the arguments passed

  my ($name,
      $label,
      $database,
      $table,
      $id_field,
      $query,
      $alias,
      $member) = rearrange(['NAME',
                            'LABEL',
                            'DATABASE',
                            'TABLE',
                            'ID_FIELD',
                            'QUERY',
                            'ALIAS',
                            'MEMBER'],@_);


  # $name - Member name
  # $label - The label to display for the member
  # $database - The member's database
  # $table - The member's table 
  # $id_field - The name of the member's id field
  # $query - The member's query object, or hash
  # $alias - The alias for the member's table
  # $member - The member to add

  # Double check to make sure we don't already have
  # a member with the same name.

  return $self->{abstract}->report_error("add_member failed: Dupe name: $name\n") 
    if $self->{names}->{$name};

  # Double check to make sure we don't already have
  # a member with the same label.

  return $self->{abstract}->report_error("add_member failed: Dupe label: $label\n") 
    if $self->{labels}->{$label};

  # If they didn't send a member, then they should 
  # have sent a query. 

  if (!$member) {

    # Give the user an error message if they didn't
    # send a query argument.

    return $self->{abstract}->report_error("add_member failed: No query or member sent\n") 
      unless $query;

    # If the query's a hash. 

    if (ref($query) eq 'HASH') {

      # Convert it to a Relations::Query object. 

      $query = new Relations::Query($query);

    } else {

      # Assume it's a Relations::Query object and
      # clone it so we don't mess with the original. 

      $query = $query->clone();

    }

  }

  # Unless the word distinct is the first part of the
  # select clause of the query, make it so.

  $query->{'select'} = 'distinct ' . $query->{'select'} unless $query->{'select'} =~ /^distinct/;
  
  # Unless they sent an already created member, create
  # one using what they did send.

  unless ($member) {

    $member = new Relations::Family::Member(-name     => $name,
                                            -label    => $label,
                                            -database => $database,
                                            -table    => $table,
                                            -id_field => $id_field,
                                            -alias    => $alias,
                                            -query    => $query);

  }

  # Add the member to the array of lists, the names 
  # hash, and the labels hash, so we can look it up 
  # when we need to.

  push @{$self->{members}}, $member;
  $self->{names}->{$member->{name}} = $member;
  $self->{labels}->{$member->{label}} = $member;

  # Return the member so they know everything worked.

  return $member;

}



### Establishes a one to many relationship between
### two members. 

sub add_lineage {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($parent_name,
      $parent_field,
      $child_name,
      $child_field,
      $parent_member,
      $parent_label,
      $child_member,
      $child_label,
      $lineage) = rearrange(['PARENT_NAME',
                             'PARENT_FIELD',
                             'CHILD_NAME',
                             'CHILD_FIELD',
                             'PARENT_MEMBER',
                             'PARENT_LABEL',
                             'CHILD_MEMBER',
                             'CHILD_LABEL',
                             'LINEAGE'],@_);


  # $parent_name - The name of the one member
  # $parent_field - The connecting field of the one member
  # $child_name - The name of the many member
  # $child_field - The connecting field of the many member
  # $parent_member - The one member
  # $parent_label - The label of the one member
  # $child_member - The many member
  # $child_label - The label of the many member

  # If the parent label was sent but isn't found, 
  # something went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("add_lineage failed: parent label '$parent_label' not found\n")
    if ($parent_label && !$self->{labels}->{$parent_label});

  # If the parent name was sent but isn't found, something 
  # went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("add_lineage failed: parent name '$parent_name' not found\n")
    if ($parent_name && !$self->{names}->{$parent_name});

  # Unless they sent a parent name or parent member or 
  # lineage, get the parent name using the parent label. 
  # Then unless they sent a parent member or lineage, get 
  # the parent member using the parent name.

  $parent_name = $self->{labels}->{$parent_label}->{name} 
    unless ($parent_name || $parent_member || $lineage);

  $parent_member = $self->{names}->{$parent_name} 
    unless ($parent_member || $lineage);

  # If the child label was sent but isn't found, 
  # something went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("add_lineage failed: child label '$child_label' not found\n")
    if ($child_label && !$self->{labels}->{$child_label});

  # If the child name was sent but isn't found, something 
  # went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("add_lineage failed: child name '$child_name' not found\n")
    if ($child_name && !$self->{names}->{$child_name});

  # Unless they sent a child name or child member or 
  # lineage, get the child name using the child label. 
  # Then unless they sent a child member or lineage, get 
  # the child member using the child name.

  $child_name = $self->{labels}->{$child_label}->{name} 
    unless ($child_name || $child_member || $lineage);

  $child_member = $self->{names}->{$child_name} 
    unless ($child_member || $lineage);

  # Unless they sent a lineage, create one if they did
  # send bits.

  unless ($lineage) {

    # If the parent field name isn't defined, something went
    # wrong. Let the user know what's up.

    return $self->{abstract}->report_error("add_lineage failed: parent field not sent\n")
      unless defined $parent_field;

    # If the child field name isn't defined, something went
    # wrong. Let the user know what's up.

    return $self->{abstract}->report_error("add_lineage failed: child field not sent\n")
      unless defined $child_field;

    # Create the new lineage object using the info sent.

    $lineage = new Relations::Family::Lineage(-parent_member => $parent_member,
                                              -parent_field  => $parent_field,
                                              -child_member  => $child_member,
                                              -child_field   => $child_field);

  }

  # Ok, everything checks out. Add the lineage to both
  # the parent and child so they know that they're related 
  # and how.

  push @{$lineage->{child_member}->{parents}}, $lineage;
  push @{$lineage->{parent_member}->{children}}, $lineage;

  # Return the lineage because everything worked out.

  return $lineage;

}



### Establishes a one to one relationship between
### two members. 

sub add_rivalry {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($brother_name,
      $brother_field,
      $sister_name,
      $sister_field,
      $brother_member,
      $brother_label,
      $sister_member,
      $sister_label,
      $rivalry) = rearrange(['BROTHER_NAME',
                             'BROTHER_FIELD',
                             'SISTER_NAME',
                             'SISTER_FIELD',
                             'BROTHER_MEMBER',
                             'BROTHER_LABEL',
                             'SISTER_MEMBER',
                             'SISTER_LABEL',
                             'RIVALRY'],@_);


  # $brother_name - The name of the one member
  # $brother_field - The connecting field of the one member
  # $sister_name - The name of the other member
  # $sister_field - The connecting field of the other member
  # $brother_member - The one member
  # $brother_label - The label of the one member
  # $sister_member - The other member
  # $sister_label - The label of the other member

  # If the brother label was sent but isn't found, 
  # something went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("add_rivalry failed: brother label '$brother_label' not found\n")
    if ($brother_label && !$self->{labels}->{$brother_label});

  # If the brother name was sent but isn't found, something 
  # went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("add_rivalry failed: brother name '$brother_name' not found\n")
    if ($brother_name && !$self->{names}->{$brother_name});

  # Unless they sent a brother name or brother member or 
  # rivalry, get the brother name using the brother label. 
  # Then unless they sent a brother member or rivalry, get 
  # the brother member using the brother name.

  $brother_name = $self->{labels}->{$brother_label}->{name} 
    unless ($brother_name || $brother_member || $rivalry);

  $brother_member = $self->{names}->{$brother_name} 
    unless ($brother_member || $rivalry);

  # If the sister label was sent but isn't found, 
  # something went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("add_rivalry failed: sister label '$sister_label' not found\n")
    if ($sister_label && !$self->{labels}->{$sister_label});

  # If the sister name was sent but isn't found, something 
  # went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("add_rivalry failed: sister name '$sister_name' not found\n")
    if ($sister_name && !$self->{names}->{$sister_name});

  # Unless they sent a sister name or sister member or 
  # rivalry, get the sister name using the sister label. 
  # Then unless they sent a sister member or rivalry, get 
  # the sister member using the sister name.

  $sister_name = $self->{labels}->{$sister_label}->{name} 
    unless ($sister_name || $sister_member || $rivalry);

  $sister_member = $self->{names}->{$sister_name} 
    unless ($sister_member || $rivalry);

  # Unless they sent a rivalry, create one if they did
  # send bits.

  unless ($rivalry) {

    # If the brother field name isn't defined, something went
    # wrong. Let the user know what's up.

    return $self->{abstract}->report_error("add_rivalry failed: brother field not sent\n")
      unless defined $brother_field;

    # If the sister field name isn't defined, something went
    # wrong. Let the user know what's up.

    return $self->{abstract}->report_error("add_rivalry failed: sister field not sent\n")
      unless defined $sister_field;

    # Create the new rivalry object using the info sent.

    $rivalry = new Relations::Family::Rivalry(-brother_member => $brother_member,
                                              -brother_field  => $brother_field,
                                              -sister_member  => $sister_member,
                                              -sister_field   => $sister_field);

  }

  # Ok, everything checks out. Add the rivalry to both
  # the brother and sister so they know that they're related 
  # and how.

  push @{$rivalry->{sister_member}->{brothers}}, $rivalry;
  push @{$rivalry->{brother_member}->{sisters}}, $rivalry;

  # Return the rivlary because everything worked out.

  return $rivalry;

}



### Adds a value held by one or more members. 

sub add_value {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($name,
      $sql,
      $member_names,
      $member_labels,
      $members,
      $value) = rearrange(['NAME',
                           'SQL',
                           'MEMBER_NAMES',
                           'MEMBER_LABELS',
                           'MEMBERS',
                           'VALUE'],@_);


  # $name - The name of the value
  # $sql - The SQL field/equation of the value
  # $members_names - The names of the members that hold this value
  # $member_labels - The labels of the members that hold this value
  # $members - The members that hold this value
  # $value - The value object already created

  # Unless they sent names or members or a value, get the 
  # names using the labels. 

  unless ($member_names || $members || $value) {

    # Declare an array ref to hold the new names

    $member_names = to_array();

    # Make sure the labels are in array format

    $member_labels = to_array($member_labels);

    # Go through each label

    foreach my $member_label (@$member_labels) {

      # If this label isn't part of the family, let 
      # the user know something's wrong.

      return $self->{abstract}->report_error("add_value failed: label, $member_label, not found\n")
        unless $self->{labels}->{$member_label};

      # This label's legit. Add its member's name 
      # to the names array.

      push @$member_names, $self->{labels}->{$member_label}->{name};

    }

  }

  # Unless they sent members or a value, get the members 
  # using the names.

  unless ($members || $value) {

    # Declare and array to hold the new members

    $members = to_array();

    # Make sure the names are in array format

    $member_names = to_array($member_names);

    # Go through each name

    foreach my $member_name (@$member_names) {

      # If this name isn't part of the family, let 
      # the user know something's wrong.

      return $self->{abstract}->report_error("add_value failed: name, $member_name, not found\n")
        unless $self->{names}->{$member_name};

      # This name's legit. Add its member to the 
      # members array.

      push @$members, $self->{names}->{$member_name};

    }

  }

  # Unless they sent a value, create one.

  unless ($value) {

    # If the value name isn't defined, something went
    # wrong. Let the user know what's up.

    return $self->{abstract}->report_error("add_value failed: value name not sent\n")
      unless defined $name;

    # If the sql name isn't defined, something went
    # wrong. Let the user know what's up.

    return $self->{abstract}->report_error("add_value failed: value sql not sent\n")
      unless defined $sql;

    # If the value members aren't defined, something went
    # wrong. Let the user know what's up.

    return $self->{abstract}->report_error("add_value failed: members not sent\n")
      unless defined $members;

    # Create the new value with the info sent.

    $value = new Relations::Family::Value(-name    => $name,
                                          -sql     => $sql,
                                          -members => $members);

  }

  # Double check to make sure we don't already have
  # a value with the same name.

  return $self->{abstract}->report_error("add_value failed: Dupe name: $value->{name}\n") 
    if $self->{'values'}->{$value->{name}};

  # Ok, everything checks out. Add the value to 
  # this family.

  $self->{'values'}->{$value->{name}} = $value;

  # Return the value because everything's alright.

  return $value;

}



### Gets the chosen items of a member. 

sub get_chosen {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($name,
      $member,
      $label) = rearrange(['NAME',
                           'MEMBER',
                           'LABEL'],@_);


  # $name - The name of the member
  # $member - The member
  # $label - The label of the member

  # If the label was sent but isn't found, something 
  # went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("get_chosen failed: member label '$label' not found\n")
    if ($label && !$self->{labels}->{$label});

  # If the name was sent but isn't found, something 
  # went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("get_chosen failed: member name '$name' not found\n")
    if ($name && !$self->{names}->{$name});

  # Unless they sent a name or member, get the member name 
  # using the label. Then unless they sent a member, get 
  # the member using the name.

  $name = $self->{labels}->{$label}->{name} unless ($name || $member);
  $member = $self->{names}->{$name} unless ($member);

  # Create a hash ref to hold all the values.

  my $chosen_hash = to_hash();

  # Fill that hash

  $chosen_hash->{count} = $member->{chosen_count};
  $chosen_hash->{ids_string} = $member->{chosen_ids_string};
  $chosen_hash->{ids_array} = $member->{chosen_ids_array};
  $chosen_hash->{ids_select} = $member->{chosen_ids_select};

  $chosen_hash->{labels_string} = $member->{chosen_labels_string};
  $chosen_hash->{labels_array} = $member->{chosen_labels_array};
  $chosen_hash->{labels_hash} = $member->{chosen_labels_hash};
  $chosen_hash->{labels_select} = $member->{chosen_labels_select};

  $chosen_hash->{filter} = $member->{filter};
  $chosen_hash->{match} = $member->{match};
  $chosen_hash->{group} = $member->{group};
  $chosen_hash->{limit} = $member->{limit};
  $chosen_hash->{ignore} = $member->{ignore};

  # Return the hash ref

  return $chosen_hash;

}



### Sets the chosen items of a member. 

sub set_chosen {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($name,
      $ids,
      $labels,
      $match,
      $group,
      $filter,
      $limit,
      $ignore,
      $selects,
      $label,
      $member) = rearrange(['NAME',
                            'IDS',
                            'LABELS',
                            'MATCH',
                            'GROUP',
                            'FILTER',
                            'LIMIT',
                            'IGNORE',
                            'SELECTS',
                            'LABEL',
                            'MEMBER'],@_);
 
  # $name - The name of the member
  # $ids - The selected ids
  # $labels - The selected labels
  # $match - Mathcing any of all selections
  # $group - Group inclusively or exclusively
  # $filter - The filter for the labels
  # $limit - Limit settings
  # $ignore - Whether or not we're ignoring this member
  # $selects - The select ids from a HTML select list
  # $label - The label of the member
  # $member - The member

  # If the label was sent but isn't found, something 
  # went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("set_chosen failed: member label '$label' not found\n")
    if ($label && !$self->{labels}->{$label});

  # If the name was sent but isn't found, something 
  # went wrong. Let the user know what's up.

  return $self->{abstract}->report_error("set_chosen failed: member name '$name' not found\n")
    if ($name && !$self->{names}->{$name});

  # Unless they sent a name or member, get the member name 
  # using the label. Then unless they sent a member, get 
  # the member using the name.

  $name = $self->{labels}->{$label}->{name} unless ($name || $member);
  $member = $self->{names}->{$name} unless ($member);

  # If the selects array was sent, then use that. A selects
  # array is an array of "$id\t$label" values. This is done
  # so we can see both the selected ids and labels return 
  # from HTML select list.

  if ($selects) {

    # Set the count based on the number of selects, and
    # and set the ids for the selects to what was sent.

    $member->{chosen_count} = scalar @$selects;
    $member->{chosen_ids_select} = $selects;

    # Empty out the ids array, the labels array,
    # the labels hash, and the labels select hash
    # because we're going to fill them.

    $member->{chosen_ids_array} = to_array();
    $member->{chosen_labels_array} = to_array();
    $member->{chosen_labels_hash} = to_hash();
    $member->{chosen_labels_select} = to_hash();

    # Go through all the selects and fill the other
    # storage forms.

    foreach my $select (@$selects) {

      my ($id,$label) = split /\t/, $select;

      push @{$member->{chosen_ids_array}}, $id;
      push @{$member->{chosen_labels_array}}, $label;
      $member->{chosen_labels_hash}->{$id} = $label;
      $member->{chosen_labels_select}->{$select} = $label;

    }

  }

  # If the ids were set as an array and the labels were
  # sent as a hash.

  elsif ((ref($ids) eq 'ARRAY') && (ref($labels) eq 'HASH')) {

    # Set the count based on the number of ids, and
    # and set the array for the ids and the hashref
    # of the labels to what was sent.

    $member->{chosen_count} = scalar @$ids;
    $member->{chosen_ids_array} = $ids;
    $member->{chosen_labels_hash} = $labels;

    # Empty out the ids select array, the labels array,
    # the labels select hash because we're going to 
    # fill them.

    $member->{chosen_ids_select} = to_array();
    $member->{chosen_labels_array} = to_array();
    $member->{chosen_labels_select} = to_hash();

    # Go through all the ids and fill the other
    # storage forms.

    foreach my $id (@$ids) {

      push @{$member->{chosen_ids_select}}, "$id\t$labels->{$id}";
      push @{$member->{chosen_labels_array}}, $labels->{$id};
      $member->{chosen_labels_select}->{"$id\t$labels->{$id}"} = $labels->{$id};

    }

  }

  # Else $ids and $labels are arrays or strings

  else {

    # Make sure $ids and $labels are array refs.

    $ids = to_array($ids);
    
    # Split $labels by tabs, not commas.

    unless (ref($labels)) {
    
      my @labels = split /\t/, $labels;
      $labels = \@labels;

    }

    # Set the count based on the number of ids, and
    # and set the array for the ids and the hashref
    # of the labels to what was sent.

    $member->{chosen_count} = scalar @$ids;
    $member->{chosen_ids_array} = $ids;
    $member->{chosen_labels_array} = $labels;

    # Empty out the ids select array, the labels hash,
    # the labels select hash.

    $member->{chosen_ids_select} = to_array();
    $member->{chosen_labels_hash} = to_hash();
    $member->{chosen_labels_select} = to_hash();

    # Go through all the ids and fill the other
    # storage forms.

    for (my $i = 0; $i < scalar @$ids; $i++) {

      push @{$member->{chosen_ids_select}}, "$ids->[$i]\t$labels->[$i]";
      $member->{chosen_labels_hash}->{$ids->[$i]} = $labels->[$i];
      $member->{chosen_labels_select}->{"$ids->[$i]\t$labels->[$i]"} = $labels->[$i];

    }

  }

  # Set the strings accordingly.

  $member->{chosen_ids_string} = join ',', @{$member->{chosen_ids_array}};
  $member->{chosen_labels_string} = join "\t", @{$member->{chosen_labels_array}};

  # Grab the other settings if sent.

  $member->{filter} = $filter;
  $member->{match} = $match;
  $member->{group} = $group;
  $member->{limit} = $limit;
  $member->{ignore} = $ignore;

  # Return the whole shabang set.

  return $self->get_chosen(-member => $member);

}



### Gets whether a member needs to be involved in 
### a query. 

sub get_needs {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($member,
      $needs,
      $needed,
      $skip) = (@_);

  # $member - The member being evaluated
  # $needs - Hash ref of members needs by name
  # $needed - Hash ref of members evaluated by name
  # $skip - Skip this members needs

  # If we've got stuff selected, and we're not to be 
  # ignored, then we need to be in a query.

  my $need = ($member->{chosen_count} > 0) && !$member->{ignore} && !$skip;

  # Add ourselves to the hash, showing that we've been
  # evaluated for a need to be in a query.

  $needed->{$member->{name}} = 1;

  # Go thorugh all our relatives, and || their need with 
  # ours, unless they've already been evaluated for 
  # need. We || them because if they need to be in a query, 
  # and they haven't been checked yet, then we need to be in 
  # a query to connect them to the original member that needs 
  # a query.

  # Parents

  foreach my $lineage (@{$member->{parents}}) {

    next if $needed->{$lineage->{parent_member}->{name}};

    $need = $self->get_needs($lineage->{parent_member},$needs,$needed) || $need;

  }

  # Children

  foreach my $lineage (@{$member->{children}}) {

    next if $needed->{$lineage->{child_member}->{name}};

    $need = $self->get_needs($lineage->{child_member},$needs,$needed) || $need;

  }

  # Brothers

  foreach my $rivalry (@{$member->{brothers}}) {

    next if $needed->{$rivalry->{brother_member}->{name}};

    $need = $self->get_needs($rivalry->{brother_member},$needs,$needed) || $need;

  }

  # Sisters

  foreach my $rivalry (@{$member->{sisters}}) {

    next if $needed->{$rivalry->{sister_member}->{name}};

    $need = $self->get_needs($rivalry->{sister_member},$needs,$needed) || $need;

  }

  # Return whether we're needed, and set the
  # needs hash.

  $needs->{$member->{name}} = $need;

}



### Gets a member's chosen id values based on what's
### been selected and what its match value is.

sub get_ids {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($member,
      $ids,
      $ided,
      $no_all,
      $skip) = (@_);

  # $member - The member
  # $ids - Array of hashes of id values
  # $ided - Hash ref of lists already id'ed
  # $no_all - Whether or not we can match all
  # $skip - Skip the member being currently checked.

  # If we've got stuff selected, we're not to be ignored, 
  # and we're not being skipped then we need to be ided.

  if (($member->{chosen_count} > 0) && !$member->{ignore} && !$skip) {

    # Unless we're set to match all, and we're allowed to
    # match all ids.

    unless ($member->{match} && !$no_all) {

      # Then we're just going to add our ids to the 
      # values array of hashes.

      # Go through each row of ids

      foreach my $row (@$ids) {

        # Put our ids in keyed by our name

        $row->{$member->{name}} = $member->{chosen_ids_string};

      }

    # If we're to match all, then we need to increase the
    # rows of values X times, where X is the number of our 
    # selected ids.

    } else {

      # Declare a new array for the array of hashes of 
      # ids.

      my $new_ids = to_array();

      # Go through each row in the values

      foreach my $row (@$ids) {

        # Go through each of our ids

        foreach my $id (@{$member->{chosen_ids_array}}) {

          # Create a new row from the current ids row,
          # assign our current id to it, and add it to the
          # new array of hashes of ids

          my %row = %$row;

          $row{$member->{name}} = $id;

          push @$new_ids, \%row;

        }

      }

      # Point the old ids to our new ids.

      $ids = $new_ids;

    }

  }

  # Add ourselves to the hash, showing that we've
  # added our ids, and are thus ided.

  $ided->{$member->{name}} = 1;

  # Go through all our relatives, add add their ids to
  # ids, unless they've already been id'ed. 

  # Parents

  foreach my $lineage (@{$member->{parents}}) {

    next if $ided->{$lineage->{parent_member}->{name}};

    $ids = $self->get_ids($lineage->{parent_member},$ids,$ided);

  }

  # Children

  foreach my $lineage (@{$member->{children}}) {

    next if $ided->{$lineage->{child_member}->{name}};

    $ids = $self->get_ids($lineage->{child_member},$ids,$ided,$no_all);

  }

  # Brothers

  foreach my $rivalry (@{$member->{brothers}}) {

    next if $ided->{$rivalry->{brother_member}->{name}};

    $ids = $self->get_ids($rivalry->{brother_member},$ids,$ided,$no_all);

  }

  # Sisters

  foreach my $rivalry (@{$member->{sisters}}) {

    next if $ided->{$rivalry->{sister_member}->{name}};

    $ids = $self->get_ids($rivalry->{sister_member},$ids,$ided,$no_all);

  }

  # Return the collection of ids we have. 

  return $ids;

}



### Gets a member's contribution to the query. 

sub get_query {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($member,
      $query,
      $row,
      $needs,
      $queried) = (@_);

  # $member - The member
  # $query - The query to build
  # $row - The current $ids row to use
  # $needs - Hash of who needs to be in the query
  # $queried - Hash of members that have added to the query

  # Our table is needed in the query.

  $query->add(-from => {$member->{alias} => "$member->{database}.$member->{table}"});

  # If we have stuff chosen, then our chosen ids 
  # need to be in the query. Make sure we exclude
  # our chosen values if we're supposed to.

  if ($row->{$member->{name}}) {

    my $group = $member->{group} ? ' not' : '';

    my $member_id = "$member->{alias}." . 
                    "$member->{id_field}";

    $query->add(-where => "$member_id$group in ($row->{$member->{name}})");

  }

  # Add ourselves to the hash, showing that we've
  # added to the query.

  $queried->{$member->{name}} = 1;

  # Go thorugh all our relatives, add add their query bits to
  # the query, unless they've already done that or they just 
  # don't need to.

  # Parents

  foreach my $lineage (@{$member->{parents}}) {

    next if ($queried->{$lineage->{parent_member}->{name}} || 
              !$needs->{$lineage->{parent_member}->{name}});

    my $parent_field = "$lineage->{parent_member}->{alias}." .
                       "$lineage->{parent_field}";

    my $child_field = "$lineage->{child_member}->{alias}." .
                      "$lineage->{child_field}";

    $query->add(-where => "$child_field=$parent_field");

    $self->get_query($lineage->{parent_member},$query,$row,$needs,$queried);

  }

  # Children

  foreach my $lineage (@{$member->{children}}) {

    next if ($queried->{$lineage->{child_member}->{name}} || 
              !$needs->{$lineage->{child_member}->{name}});

    my $parent_field = "$lineage->{parent_member}->{alias}." .
                       "$lineage->{parent_field}";

    my $child_field = "$lineage->{child_member}->{alias}." .
                      "$lineage->{child_field}";

    $query->add(-where => "$parent_field=$child_field");

    $self->get_query($lineage->{child_member},$query,$row,$needs,$queried);

  }

  # Brothers

  foreach my $rivalry (@{$member->{brothers}}) {

    next if ($queried->{$rivalry->{brother_member}->{name}} || 
              !$needs->{$rivalry->{brother_member}->{name}});

    my $brother_field = "$rivalry->{brother_member}->{alias}." .
                        "$rivalry->{brother_field}";

    my $sister_field = "$rivalry->{sister_member}->{alias}." .
                       "$rivalry->{sister_field}";

    $query->add(-where => "$sister_field=$brother_field");

    $self->get_query($rivalry->{brother_member},$query,$row,$needs,$queried);

  }

  # Sisters

  foreach my $rivalry (@{$member->{sisters}}) {

    next if ($queried->{$rivalry->{sister_member}->{name}} || 
              !$needs->{$rivalry->{sister_member}->{name}});

    my $brother_field = "$rivalry->{brother_member}->{alias}." .
                        "$rivalry->{brother_field}";

    my $sister_field = "$rivalry->{sister_member}->{alias}." .
                       "$rivalry->{sister_field}";

    $query->add(-where => "$brother_field=$sister_field");

    $self->get_query($rivalry->{sister_member},$query,$row,$needs,$queried);

  }

}



### Gets the available records for a member 
### based on other members selections.

sub get_available {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($name,
      $member,
      $label,
      $focus) = rearrange(['NAME',
                           'MEMBER',
                           'LABEL',
                           'FOCUS'],@_);
 
  # $name - The name of the member
  # $member - The member
  # $label - The label of the member
  # $focus - Whether to use one's own chosen ids

  # If the label isn't found, something went
  # wrong. Let the user know what's up.

  return $self->{abstract}->report_error("get_available failed: member label '$label' not found\n")
    if ($label && !$self->{labels}->{$label});

  # If the name isn't found, something went
  # wrong. Let the user know what's up.

  return $self->{abstract}->report_error("get_available failed: member name '$name' not found\n")
    if ($name && !$self->{names}->{$name});

  # Unless they sent a name or member, get the member name 
  # using the label. Then unless they sent a member, get 
  # the member using the name.

  $name = $self->{labels}->{$label}->{name} unless ($name || $member);
  $member = $self->{names}->{$name} unless ($member);

  # Create a query to hold the avaiable items. Base it off
  # of what was specified at the creation of the current 
  # member and what's been selected.

  my $available_query = $member->{query}->clone();

  # If we have a filter, put it in.

  if ($member->{filter}) {

    $available_query->add(-having => "label like '%$member->{filter}%'");

  }
  
  # If we have a limit, put it in.

  if ($member->{limit}) {

    $available_query->add(-limit => $member->{limit});

  }
  
  # Now we need to see if any of the other need to add to
  # the query, starting at this member. So create the hashes 
  # to hold the needs. The needs is just a hashref keyed
  # by the member name and set to whether the member needs
  # to be queried, 1.
  
  my $needs = to_hash();
  my $needed = to_hash();

  # Now call the recursive get_needs, starting at the 
  # current member. Make sure the first member's skipped 
  # too, since we're not going build a query of avaiable 
  # records if the only selections are from this member.

  my $need = $self->get_needs($member,$needs,$needed,1);

  # If there's a need to have other members contribute to 
  # the query.

  if ($need) {

    # Create an empty ids set. A ids set is an array ref
    # of hashrefs of selected ids, keyed by the member name. To
    # create an empty ids set, we need an empty hash's 
    # reference in the first member of the array ref. 

    my $ids = to_array();
    push @$ids, to_hash();

    # Like get_needs, we also need a hash for keeping track 
    # of which members we've ided. 

    my $ided = to_hash();

    # Call the recursive gets ids. Skip the current member
    # and don't allow match all's on the member and all their
    # connected members except parents.

    $ids = $self->get_ids($member,$ids,$ided,1,1 && !$focus);

    # Go through all the ids sets found and create a 
    # temporary table for each set. Start the set 
    # suffixes at 0.

    my $set = 0;

    my $id_field = "$member->{database}.$member->{table}.$member->{id_field}";

    foreach my $row (@$ids) {

      # Now we have to make a hash to hold who's been queried
      # and who hasn't. 

      my $queried = to_hash();

      # Create a query object for this values set, adding our
      # id to the select clause.

      my $row_query = new Relations::Query(-select => {'id_field' => $id_field});

      # Add distinct to the first part of the query
      # to make sure we only get one of each id.

      $row_query->{'select'} = 'distinct ' . $row_query->{'select'};
      
      # Run the recursive get query. 

      $self->get_query($member,$row_query,$row,$needs,$queried);

      # Now create a temporary table with the query

      my $table = $member->{name} . '_query_' . $set;
      my $create = "create temporary table $table ";
      my $condition = "$member->{alias}.$member->{id_field}=$table.id_field";
      my $row_string = $create . $row_query->get();

      # If we can't drop the table, something went
      # wrong. Let the user know what's up.

      return $self->{abstract}->report_error("get_available failed: couldn't drop table\n")
        unless $self->{abstract}->run_query("drop table if exists $table");

      # If we can't drop the table, something went
      # wrong. Let the user know what's up.

      return $self->{abstract}->report_error("get_available failed: couldn't query row: $row_string\n")
        unless $self->{abstract}->run_query($row_string);

      # Add this temp table and requirement to the 
      # avaiable query, and increase the set var.

      $available_query->add(-from  => $table,
                            -where => $condition);

      $set++;

    }

  }

  # Prepare and execute the main query

  my $available_string = $available_query->get();

  my $sth = $self->{abstract}->{dbh}->prepare($available_string);

  # If we can't query available, something went
  # wrong. Let the user know what's up.

  return $self->{abstract}->report_error("get_available failed: couldn't query available: $available_string\n")
    unless $sth->execute();

  # Clear out the member's available stuff.

  $member->{available_count} = 0;
  $member->{available_ids_array} = to_array();
  $member->{available_ids_select} = to_array();

  $member->{available_labels_array} = to_array();
  $member->{available_labels_hash} = to_hash();
  $member->{available_labels_select} = to_hash();

  # Populate all members

  while (my $hash_ref = $sth->fetchrow_hashref) {

    push @{$member->{available_ids_array}}, $hash_ref->{id};
    push @{$member->{available_ids_select}}, "$hash_ref->{id}\t$hash_ref->{label}";

    push @{$member->{available_labels_array}}, $hash_ref->{label};
    $member->{available_labels_hash}->{$hash_ref->{id}} = $hash_ref->{label};
    $member->{available_labels_select}->{"$hash_ref->{id}\t$hash_ref->{label}"} = $hash_ref->{label};

  }

  # Grab the count 

  $member->{available_count} = scalar @{$member->{available_ids_array}};

  $sth->finish();

  # Create the info hash to return and fill it

  my $available = to_hash();

  $available->{filter} = $member->{filter};
  $available->{match} = $member->{match};
  $available->{group} = $member->{group};
  $available->{limit} = $member->{limit};
  $available->{ignore} = $member->{ignore};
  $available->{count} = $member->{available_count};
  $available->{ids_array} = $member->{available_ids_array};
  $available->{ids_select} = $member->{available_ids_select};
  $available->{labels_array} = $member->{available_labels_array};
  $available->{labels_hash} = $member->{available_labels_hash};
  $available->{labels_select} = $member->{available_labels_select};

  return $available;

}



### Sets chosen items from available items, using the
### members current chosen ids, as well as other members
### chosen ids.

sub choose_available {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($name,
      $member,
      $label) = rearrange(['NAME',
                           'MEMBER',
                           'LABEL'],@_);
 
  # $name - The name of the member
  # $member - The member
  # $label - The label of the member

  # If the label isn't found, something went
  # wrong. Let the user know what's up.

  return $self->{abstract}->report_error("choose_available failed: member label '$label' not found\n")
    if ($label && !$self->{labels}->{$label}->{name});

  # If the name isn't found, something went
  # wrong. Let the user know what's up.

  return $self->{abstract}->report_error("choose_available failed: member name '$name' not found\n")
    if ($name && !$self->{names}->{$name});

  # Unless they sent a name or member, get the member name 
  # using the label. Then unless they sent a member, get 
  # the member using the name.

  $name = $self->{labels}->{$label}->{name} unless ($name || $member);
  $member = $self->{names}->{$name} unless ($member);

  # Get the available members ids, including using the 
  # member's own ids in the query.

  my $available = $self->get_available(-member => $member, -focus => 1);

  # Return the result from setting the chosen ids to
  # the available ids and labels.

  return $self->set_chosen(-member => $member,
                           -ids    => $available->{ids_array},
                           -labels => $available->{labels_hash},
                           -filter => $member->{filter},
                           -match  => $member->{match},
                           -group  => $member->{group},
                           -limit  => $member->{limit},
                           -ignore => $member->{ignore});

}



### Gets who'll be attending a reunion

sub get_visits {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($member,
      $visits,
      $visited,
      $ids,
      $valued) = (@_);

  # $member - The member
  # $visits - Hash of who'll visit
  # $visited - Hash ref of who's been checked
  # $ids - IDs to use in the reunion
  # $valued - Hash ref of reunion values' members

  # If we're valued or our ids are playing a role 

  my $visit = $valued->{$member->{name}} || defined $ids->{$member->{name}};

  # Add ourselves to the hash, showing that we've been
  # evaluated for a visit to the reunion

  $visited->{$member->{name}} = 1;

  # Go through all our relatives, and || their visit with 
  # ours, unless they've already been evaluated for a
  # visit. We || them because if they need to be part of 
  # the reunion, and they haven't been checked yet, then we 
  # need to connect them to the central member of the
  # reunion.

  # Parents

  foreach my $lineage (@{$member->{parents}}) {

    next if $visited->{$lineage->{parent_member}->{name}};

    $visit = $self->get_visits($lineage->{parent_member},$visits,$visited,$ids,$valued) || $visit;

  }

  # Children

  foreach my $lineage (@{$member->{children}}) {

    next if $visited->{$lineage->{child_member}->{name}};

    $visit = $self->get_visits($lineage->{child_member},$visits,$visited,$ids,$valued) || $visit;

  }

  # Brothers

  foreach my $rivalry (@{$member->{brothers}}) {

    next if $visited->{$rivalry->{brother_member}->{name}};

    $visit = $self->get_visits($rivalry->{brother_member},$visits,$visited,$ids,$valued) || $visit;

  }

  # Sisters

  foreach my $rivalry (@{$member->{sisters}}) {

    next if $visited->{$rivalry->{sister_member}->{name}};

    $visit = $self->get_visits($rivalry->{sister_member},$visits,$visited,$ids,$valued) || $visit;

  }

  # Return whether we're to visit, and set the
  # visits hash.

  $visits->{$member->{name}} = $visit;

}



### Gets the reunion for the family.

sub get_reunion {

  # Get the type we were sent

  my ($self) = shift;

  # Get all the arguments passed

  my ($data,
      $use_names,
      $group_by,
      $order_by,
      $start_name,
      $query,
      $use_labels,
      $use_members,
      $use_name_ids,
      $use_label_ids,
      $start_label,
      $start_member) = rearrange(['DATA',
                                  'USE_NAMES',
                                  'GROUP_BY',
                                  'ORDER_BY',
                                  'START_NAME',
                                  'QUERY',
                                  'USE_LABELS',
                                  'USE_MEMBERS',
                                  'USE_NAME_IDS',
                                  'USE_LABEL_IDS',
                                  'START_LABEL',
                                  'START_MEMBER'],@_);
                             
  # $data - The values of the data
  # $use_names -  Use IDs from these members (by name)
  # $group_by - Group by values
  # $order_by -Group by values
  # $start_name - Name of member to start from
  # $query - Query to start out with
  # $use_labels -  Use IDs from these members (by label)
  # $use_members -  Use IDs from these members
  # $use_name_ids -  Use these IDs from members keyed by name
  # $use_label_ids -  Use these IDs from members keyed by label
  # $start_label - Label of member to start from
  # $start_member - Member to start from

  # Create an empty hash of ids to hold the ids
  # to use in the reunion. 

  my $ids = to_hash();

  # Unless the use_ids variables were sent

  unless ($use_name_ids || $use_label_ids) {

    # Look up use labels from use members unless use labels 
    # or use names is set, or they didn't send use members

    unless ($use_labels || $use_names || !$use_members) {

      # Set use labels to an empty array.

      $use_labels = to_array();

      # Go through each use member

      foreach my $use_member (@$use_members) {

        # If this use member isn't set, something went
        # wrong. Let the user know what's up.

        return $self->{abstract}->report_error("get_reunion failed: use member '$use_member' not set\n")
          unless $use_member;

        # Add this member's label to use_labels

        push @$use_labels, $use_member->{label};

      }

    }
   
    # Look up use names from use labels unless use names 
    # is set or they didn't send use labels

    unless ($use_names || !$use_labels) {

      # Convert use labels to an array, and 
      # set use names to an empty array.

      $use_labels = to_array($use_labels);
      $use_names = to_array();

      # Go through each use label

      foreach my $use_label (@$use_labels) {

        # If this use label isn't found, something went
        # wrong. Let the user know what's up.

        return $self->{abstract}->report_error("get_reunion failed: use member label '$use_label' not found\n")
          unless $self->{labels}->{$use_label}->{name};

        # Add this member's name to use_names

        push @$use_names, $self->{labels}->{$use_label}->{name};

      }

    }
   
    # Look up ids from use names if they sent use 
    # names, and key them by name.

    if ($use_names) {

      foreach my $use_name (@$use_names) {

        # If this member has stuff set and its not
        # to be ignored, use its selected ids.

        $ids->{$use_name} = $self->{names}->{$use_name}->{chosen_ids_string} 
          if (($self->{names}->{$use_name}->{chosen_count} > 0) && !$self->{names}->{$use_name}->{ignore});

      }

    }

  } else {
   
    # Look up use name ids from use label ids unless use name
    # ids is set, or they didn't send use label ids.

    unless ($use_name_ids || !$use_label_ids) {

      # Create the hash to hold the ids keyed by name

      $use_name_ids = to_hash();

      # Go through each use label

      foreach my $use_label (keys %$use_label_ids) {

        # If this use label isn't found, something went
        # wrong. Let the user know what's up.

        return $self->{abstract}->report_error("get_reunion failed: use member label '$use_label' not found\n")
          unless $self->{labels}->{$use_label}->{name};

        # Add this member's ids to use_name_ids keyed by name

        $use_name_ids->{$self->{labels}->{$use_label}->{name}} = $use_label_ids->{$use_label};

      }

    }
   
    # Set ids to use_name_ids

    $ids = $use_name_ids;

  }
  
  # If the start label isn't found, something went
  # wrong. Let the user know what's up.

  return $self->{abstract}->report_error("get_reunion failed: start member label '$start_label' not found\n")
    if ($start_label && !$self->{labels}->{$start_label}->{name});

  # If the start name isn't found, something went
  # wrong. Let the user know what's up.

  return $self->{abstract}->report_error("get_reunion failed: start member name '$start_name' not found\n")
    if ($start_name && !$self->{names}->{$start_name});

  # Unless they sent a name or member, get the member name 
  # using the label. Then unless they sent a member, get 
  # the member using the name.

  $start_name = $self->{labels}->{$start_label}->{name} unless ($start_name || $start_member);
  $start_member = $self->{names}->{$start_name} unless ($start_member);

  # Make sure all values are in array form
  
  $data = to_array($data);
  $group_by = to_array($group_by);
  $order_by = to_array($order_by);

  # Create a query if they didn't send one

  $query = new Relations::Query() unless $query;

  # Create a hash for all the values needed

  my $values = to_hash();

  # Create a hash to hold all the members 
  # that have a needed value, also create
  # the select part of the query as well 
  # as arrays to hold the quoted values
  # for the group by and order by clause

  my $valued = to_hash();
  my $select = to_hash();
  my $quoted_group_by = to_array();
  my $quoted_order_by = to_array();

  # Go through all the group by field values.

  foreach my $value (@$group_by) {

    # Go through each of this values members

    foreach my $member (@{$self->{'values'}->{$value}->{members}}) {

      # This member is valued since we need it
      # to calculate this value. 

      $valued->{$member->{name}} = 1;
      
      # Add this value to the select hash, with 
      # the key being the name with quotes around 
      # in case it has spaces in it, and the value
      # being the sql part of the value. 

      $select->{$self->{abstract}->{dbh}->quote($self->{'values'}->{$value}->{name})} = $self->{'values'}->{$value}->{sql}; 

    }

    # Add this value, with quotes, to the quoted
    # group by array.

    push @$quoted_group_by, $self->{abstract}->{dbh}->quote($self->{'values'}->{$value}->{name}); 

  }

  # Go through all the order by field values.

  foreach my $value (@$order_by) {

    # There might be a desc or asc in the order by
    # value. Let's pop it out for now and add it 
    # later.

    my $order = ($value =~ s/( desc| asc)//g) ? $1 : '';

    # Go through each of this values members

    foreach my $member (@{$self->{'values'}->{$value}->{members}}) {

      # This member is valued since we need it
      # to calculate this value. 

      $valued->{$member->{name}} = 1; 

      # Add this value to the select hash, with 
      # the key being the name with quotes around 
      # in case it has spaces in it, and the value
      # being the sql part of the value. 

      $select->{$self->{abstract}->{dbh}->quote($self->{'values'}->{$value}->{name})} = $self->{'values'}->{$value}->{sql}; 

    }

    # Add this value, with quotes, to the quoted
    # order by array, complete with the sort 
    # direction.

    push @$quoted_order_by, $self->{abstract}->{dbh}->quote($self->{'values'}->{$value}->{name}) . $order; 

    # Add the sort direction back to the original
    # value as well cuz we don't want to change
    # what the user sent.

    $value .= $order;

  }

  # Go through all the data field values.

  foreach my $value (@$data) {

    # Go through each of this values members

    foreach my $member (@{$self->{'values'}->{$value}->{members}}) {

      # This member is valued since we need it
      # to calculate this value. 

      $valued->{$member->{name}} = 1; 

      # Add this value to the select hash, with 
      # the key being the name with quotes around 
      # in case it has spaces in it, and the value
      # being the sql part of the value. 

      $select->{$self->{abstract}->{dbh}->quote($self->{'values'}->{$value}->{name})} = $self->{'values'}->{$value}->{sql}; 

    }

  }

  # If we value nothing, something went wrong
  # with the reunion.

  return $self->{abstract}->report_error("get_reunion failed: nothing valued\n")
    unless scalar %$valued;
 
  # Unless we were able to lookup a start member,
  # use the first valued member for the reunion.
  
  $start_member = $self->{names}->{(keys %$valued)[0]} unless ($start_member);

  # Get all the members that are visting the 
  # reunion.

  my $visits = to_hash();
  my $visited = to_hash();

  $self->get_visits($start_member,$visits,$visited,$ids,$valued);

  # Now we have to make a hash to hold who's been queried
  # and who hasn't. 

  my $queried = to_hash();

  # Wipe that have empty arrays

  $select = '' unless scalar %$select;
  $quoted_group_by = '' unless scalar @$quoted_group_by;
  $quoted_order_by = '' unless scalar @$quoted_order_by;

  # Add to the query object for this values set.

  $query->add(-select   => $select,
              -group_by => $quoted_group_by,
              -order_by => $quoted_order_by);

  # Run the recursive get query and return it

  $self->get_query($start_member,$query,$ids,$visits,$queried);

  return $query;

}



### Returns text info about the Relations::Family 
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

  # Create a text string to hold everything

  my $text = '';

  # 411

  $text .= $indent . "Relations::Family: $self\n\n";
  $text .= $indent . "Members:\n";

  foreach my $member (@{$self->{members}}) {

    $text .= $member->to_text($string,$current + 1);

  }

  $text .= $indent . "Values:\n";

  foreach my $value (sort keys %{$self->{values}}) {

    $text .= $self->{values}->{$value}->to_text($string,$current + 1);

  }

  $text .= "\n";

  # Return the text

  return $text;

}

$Relations::Family::VERSION;

__END__

=head1 NAME

Relations::Family - DBI/DBD::mysql Relational Query Engine module. 

=head1 SYNOPSIS

  # DBI, Relations::Family Script that creates some queries.

  #!/usr/bin/perl

  use DBI;
  use Relations::Family;

  $dsn = "DBI:mysql:finder";

  $username = "root";
  $password = '';

  $dbh = DBI->connect($dsn,$username,$password,{PrintError => 1, RaiseError => 0});

  $abstract = new Relations::Abstract($dbh);

  $family = new Relations::Family($abstract);

  $family->add_member(-name     => 'account',
                      -label    => 'Cust. Account',
                      -database => 'finder',
                      -table    => 'account',
                      -id_field => 'acc_id',
                      -query    => {-select   => {'id'    => 'acc_id',
                                                  'label' => "concat(cust_name,' - ',balance)"},
                                    -from     => ['account','customer'],
                                    -where    => "customer.cust_id=account.cust_id",
                                    -order_by => "cust_name"});

  $family->add_member(-name     => 'customer',
                      -label    => 'Customer',
                      -database => 'finder',
                      -table    => 'customer',
                      -id_field => 'cust_id',
                      -query    => {-select   => {'id'    => 'cust_id',
                                                  'label' => 'cust_name'},
                                    -from     => 'customer',
                                    -order_by => "cust_name"});

  $family->add_member(-name     => 'purchase',
                      -label    => 'Purchase',
                      -database => 'finder',
                      -table    => 'purchase',
                      -id_field => 'pur_id',
                      -query    => {-select   => {'id'    => 'pur_id',
                                                  'label' => "concat(
                                                               cust_name,
                                                               ' - ',
                                                               date_format(date, '%M %D, %Y')
                                                             )"},
                                    -from     => ['purchase',
                                                  'customer'],
                                    -where    => 'customer.cust_id=purchase.cust_id',
                                    -order_by => ['date desc',
                                                  'cust_name']});

  $family->add_lineage(-parent_name  => 'customer',
                       -parent_field => 'cust_id',
                       -child_name   => 'purchase',
                       -child_field  => 'cust_id');

  $family->add_rivalry(-brother_name  => 'customer',
                       -brother_field => 'cust_id',
                       -sister_name   => 'account',
                       -sister_field  => 'cust_id');

  $family->set_chosen(-label  => 'Customer',
                      -ids    => '2,4');

  $available = $family->get_available(-label  => 'Purchase');

  print "Found $available->{count} Purchases:\n";

  foreach $id (@{$available->{ids_array}}) {

    print "Id: $id Label: $available->{labels_hash}->{$id}\n";

  }

  $family->add_value(-name         => 'Cust. Account',
                     -sql          => "concat(cust_name,' - ',balance)",
                     -member_names => 'customer,account');

  $family->add_value(-name         => 'Paid',
                     -sql          => "if(balance > 0,'NO','YES')",
                     -member_names => 'account');

  $family->add_value(-name         => 'Customer',
                     -sql          => 'cust_name',
                     -member_names => 'customer');

  $family->add_value(-name         => 'Purchase',
                     -sql          => "concat(
                                         cust_name,
                                         ' - ',
                                         date_format(date, '%M %D, %Y')
                                       )",
                     -member_names => 'purchase,customer');

  $reunion = $family->get_reunion(-data       => 'Paid,Purchase',
                                  -use_labels => 'Customer',
                                  -order_by   => 'Customer,Purchase');

  $matrix = $abstract->select_matrix(-query => $reunion);

  print "Found " . scalar @$matrix . " Values:\n";

  foreach $row (@$matrix) {

    print "Customer: $row->{'Customer'}\n";
    print "Purchase: $row->{'Purchase'}\n";
    print "Paid: $row->{'Paid'}\n\n";

  }

  $dbh->disconnect();

=head1 ABSTRACT

This perl module uses perl5 objects to simplify searching through
and reporting on large, complex MySQL databases, especially those 
with foreign keys. It uses an object orientated interface, complete 
with functions to create and manipulate the relational family.

The current version of Relations::Family is available at

  http://www.gaf3.com

=head1 DESCRIPTION

=head2 WHAT IT DOES

With Relations::Family you can create a 'family' of members for querying 
records. A member could be a table, or it could be a query on a table, like
all the different months from a table's date field. Once the members are
created, you can specify how those members are related, who's using who
as a foreign key lookup, and what values in members you might be interested 
in reporting on, like whether a customer has paid their bill.

Once the 'family' is complete, you can select records from one member, and
the query all the matching records from another member. For example, say you 
a product table being used as a lookup for a order items tables, and you want
to find all the order items for a certain product. You can select that 
product's record from the product member, and then view the order item 
records to find all the order items for that product.

You can also build a large query for report purposes using the selections 
from various members as well as values you might be interested in. For 
example, say you want to know which customer are paid up and how much 
business they've generated in the past. You can specify which members'
selections you want to use to narrow down the report and which values
you'd like in the report and then use the query returned to see who's
paid and for how much.

=head2 CALLING RELATIONS::FAMILY ROUTINES

Most standard Relations::Family routines use both an ordered, named and
hashed argument calling style. (All except for to_text()) This is because 
some routines have as many as eight arguments, and the code is easier to 
understand given a named or hashed argument style, but since some people, 
however, prefer the ordered argument style because its smaller, I'm glad 
to do that too. 

If you use the ordered argument calling style, such as

  $family->add_lineage('customer','cust_id','purchase','cust_id');

the order matters, and you should consult the function defintions 
later in this document to determine the order to use.

If you use the named argument calling style, such as

  $family->add_lineage(-parent_name  => 'customer',
                       -parent_field => 'cust_id',
                       -child_name   => 'purchase',
                       -child_field  => 'cust_id');

the order does not matter, but the names, and minus signs preceeding them, do.
You should consult the function defintions later in this document to determine 
the names to use.

In the named arugment style, each argument name is preceded by a dash.  
Neither case nor order matters in the argument list.  -name, -Name, and 
-NAME are all acceptable.  In fact, only the first argument needs to begin with 
a dash.  If a dash is present in the first argument, Relations::Family assumes
dashes for the subsequent ones.

If you use the hashed argument calling style, such as

  $family->add_lineage({parent_name  => 'customer',
                        parent_field => 'cust_id',
                        child_name   => 'purchase',
                        child_field  => 'cust_id'});

or

  $family->add_lineage({-parent_name  => 'customer',
                        -parent_field => 'cust_id',
                        -child_name   => 'purchase',
                        -child_field  => 'cust_id'});

the order does not matter, but the names, and curly braces do, (minus signs are
optional). You should consult the function defintions later in this document to 
determine the names to use.

In the hashed arugment style, no dashes are needed, but they won't cause problems
if you put them in. Neither case nor order matters in the argument list. 
parent_name, Parent_Name, PARENT_NAME are all acceptable. If a hash is the first 
argument, Relations::Family assumes that is the only argument that matters, and 
ignores any other arguments after the {}'s.

=head2 QUERY ARGUMENTS

Some of the Relations functions recognize an argument named query. This
argument can either be a hash or a Relations::Query object. 

The following calls are all equivalent for $object->function($query).

  $object->function({select => 'nothing',
                     from   => 'void'});

  $object->function(Relations::Query->new(-select => 'nothing',
                                          -from   => 'void'));


=head1 LIST OF RELATIONS::FAMILY FUNCTIONS

An example of each function is provided in either 'test.pl' and 'demo.pl'.

=head2 new

  $family = new Relations::Family($abstract);

  $family = new Relations::Family(-abstract => $abstract);

Creates creates a new Relations::Family object using a Relations::Abstract
object.

=head2 add_member

  $family->add_member($name,
                      $label,
                      $database,
                      $table,
                      $id_field,
                      $query,
                      $alias);

  $family->add_member(-name     => $name,
                      -label    => $label,
                      -database => $database,
                      -table    => $table,
                      -id_field => $id_field,
                      -query    => $query,
                      -alias    => $alias);

Creates and adds a member to a family. There's three basic groups of 
arguments in an add_member call. The first group sets how to name 
the member. The second sets how to configure the member. The third 
group explains how to create the query to display the member's records 
for selection. 

B<$name> and B<$label> - 
In the first group, $name and $label set the internal and external
identity, so both must be unique to the family. Typically, $name 
is a short string used for quickly specifying a member when coding
with a family, while $label is a longer string used to display the 
identity of a member to user using the program. $label can have 
spaces within it, $name cannot.

B<$database>, B<$table>, B<$alias> and B<$id_field> - 
In the second group, $database, $table and $id_field set the MySQL
properties. The $database and $table variables are the database 
and table used by the member, while $id_field is the member's 
table's primary key field. Relations::Family uses this info when
connecting members to each other during a query.

Two or more members might use the same table in a database, or 
they might use the same table name in two different databases. 
Under either of these circumstances, if just the table name was 
used when building queries, MySQL would get confused. Enter 
$alias. This value is used to alias the table of the member. If
no alias is sent, this value is set to the table name of the
member.

B<$query> - 
This is the query used to populate a member's selection list. The
query must select two fields, 1) the id of the member, labeled 
'id', and 2) the label of the member, labeled 'label'. The id
field is what identifies one record from another in a way that is
understandable to the database. The id field is usually the primary 
key. The label field is used to distinguish one record from another 
in a way that is understandable to the user. If a Relations::Query
object is sent (see Query Arguments above), the object is cloned
so the orginal is not modified.

=head2 add_lineage

  $family->add_lineage($parent_name,
                       $parent_field,
                       $child_name,
                       $child_field);

  $family->add_lineage(-parent_name  => $parent_name,
                       -parent_field => $parent_field,
                       -child_name   => $child_name,
                       -child_field  => $child_field);

  $family->add_lineage(-parent_label => $parent_label,
                       -parent_field => $parent_field,
                       -child_label  => $child_label,
                       -child_field  => $child_field);

Adds a one-to-many relationship to a family. This is used when a 
member, the child, is using another member, the parent, as a 
lookup. 

B<$parent_name> or B<$parent_label> - 
Specifies the parent member by name or label. 

B<$parent_field> - 
Specifies the field in the parent member that holds the values 
used by the child member's child_field, usually the parent 
member's primary key.

B<$child_name> or B<$child_label> - 
Specifies the child member by name or label. 

B<$child_field> - 
Specifies the field in the child member that stores the values 
of the parent member's field.

=head2 add_rivalry

  $family->add_rivalry($brother_name,
                       $brother_field,
                       $sister_name,
                       $sister_field);

  $family->add_rivalry(-brother_name  => $brother_name,
                       -brother_field => $brother_field,
                       -sister_name   => $sister_name,
                       -sister_field  => $sister_field);

  $family->add_rivalry(-brother_label => $brother_label,
                       -brother_field => $brother_field,
                       -sister_label  => $sister_label,
                       -sister_field  => $sister_field);

Adds a one-to-one relationship to a family. This is used when a 
member, the sister, is using another member, the parent, as a 
lookup, and there is no more than one sister record for a given
brother record. 

B<$brother_name> or B<$brother_label> - 
Specifies the brother member by name or label. 

B<$brother_field> - 
Specifies the field in the brother member that holds the values 
used by the sister member's sister_field.

B<$sister_name> or B<$sister_label> - 
Specifies the sister member by name or label. 

B<$sister_field> - 
Specifies the field in the sister member that stores the values 
of the brother member's field.

=head2 add_value

  $family->add_value($name,
                     $sql,
                     $member_names);

  $family->add_value(-name         => $name,
                     -sql          => $sql,
                     -member_names => $member_names);

  $family->add_value(-name          => $name,
                     -sql           => $sql,
                     -member_labels => $member_labels);

Adds a value to a family object. Values are used when creating
a report query from a family object using the get_reunion
function. Each value object is a column in the report query. 

B<$name> - 
The name of the column in the report query from get_reunion.

B<$sql> - 
The sql code for a value. When the report query is created, all 
the values appear in the form "select $sql as $name". When 
referencing a member's table in the $sql of a value, make sure 
you use the alias from a member, if the alias is any different
from the table name,

B<$member_names> or B<$member_labels> - 
Specifies the members needed, by name or label, by this value
to build its $sql field. Either can be a comma delimitted 
string or array reference. 

=head2 get_chosen

  $chosen = $family->get_chosen($name);

  $chosen = $family->get_chosen(-name => $name);

  $chosen = $family->get_chosen(-label => $label);

Returns a member's selected records in a couple different forms,
as well as the other goodies to control the selection process.

B<$name> or B<$label> - 
Specifies the member by name or label. 

B<$chosen> - 
A hash reference of all returned values.

B<$chosen-E<gt>{count}> - 
The number of selected records.

B<$chosen-E<gt>{ids_string}> - 
A comma delimtted string of the ids of the selected records.

B<$chosen-E<gt>{ids_array}> - 
An array reference of the ids of the selected records.

B<$chosen-E<gt>{ids_select}> - 
An array reference of the ids and labels separated by tabs: "$id\t$label"
This is used to populate the <OPTION> values of an HTML <SELECT> list so
that the list selections returned from the CGI module contain both the id 
and label of each selected record.

B<$chosen-E<gt>{labels_string}> - 
A tab delimtted string of the labels of the selected records.
If labels were not set with set_chosen, this is not available.

B<$chosen-E<gt>{labels_array}> - 
An array reference of the labels of the selected records. If labels 
were not set with set_chosen, this is not available.

B<$chosen-E<gt>{labels_hash}> - 
A hash reference of the labels of the selected records, keyed 
by the selected ids. If labels were not set with set_chosen, this is not 
available.

B<$chosen-E<gt>{labels_select}> - 
A hash reference of the labels of the selected records, keyed by ids 
and labels separated by tabs: "$id\t$label". This is used to populate 
the <OPTION> display of an HTML <SELECT> list while using the CGI
module. If labels were not set with set_chosen, this is not available.

B<$chosen-E<gt>{match}> - 
The match argument set with set_chosen().

B<$chosen-E<gt>{group}> - 
The group argument set with set_chosen().

B<$chosen-E<gt>{filter}> - 
The filter argument set with set_chosen().

B<$chosen-E<gt>{limit}> - 
The limit argument set with set_chosen().

B<$chosen-E<gt>{ignore}> - 
The ignore argument set with set_chosen().

=head2 set_chosen

  $family->set_chosen($name,
                      $ids,
                      $labels,
                      $match,
                      $group,
                      $filter,
                      $limit,
                      $ignore);

  $family->set_chosen(-name   => $name,
                      -ids    => $ids,
                      -labels => $labels,
                      -match  => $match,
                      -group  => $group,
                      -filter => $filter,
                      -limit  => $limit,
                      -ignore => $ignore);

  $family->set_chosen(-label  => $label,
                      -ids    => $ids,
                      -labels => $labels,
                      -match  => $match,
                      -group  => $group,
                      -filter => $filter,
                      -limit  => $limit,
                      -ignore => $ignore);

  $family->set_chosen(-label   => $label,
                      -selects => $selects,
                      -match   => $match,
                      -group   => $group,
                      -filter  => $filter,
                      -limit   => $limit,
                      -ignore  => $ignore);

Sets the member's records selected by a user, as well as 
some other goodies to control the selection process.

B<$name> or B<$label> - 
Specifies the member by name or label. 

B<$ids> -
The ids selected. Can be a comma delimitted string, an array.

B<$labels> -
The labels selected. Can be a tab delimitted string, an
array, or a hash keyed by $ids. It is isn't necessary to 
send these, unless you want the selected labels returned 
by get_chosen. 

B<$selects> -
An array of selected ids and labels. Each array member is a
string of the id and label value separated by a tab: "$id\t$label".
This when you used the ids_select and labels_select from 
get_available() to populate a <SELECT> list using the CGI module.

B<$match> -
Match any or all. Null or 0 for any, 1 for all. This deals with
multiple selections from a member and how that affects matching
records from another member. If a member is set to match any, 
calling get_available() for another member will return records 
from the second member that are connected to any of the 
first member's selections. If a member is set to match all, calling 
get_available() on another member will return records from the 
second member that are connected to all of the first member's
selections.

B<$group> -
Group include or exclude. Null or 0 for include, 1 for exclude. 
This deals with whether to return matching records or non 
matching records. If a member is set to group include, calling 
get_available() for another member will return records from the 
second member that are connected to the first member's selections. 
If a member is set to group exclude, calling get_available() on 
another member will return records from the second member that 
are not connected to the first member's selections.

B<$filter> -
Filter labels. In order to simplify the selection process, you 
can specify a filter to only show a select group of records 
from a member for selecting. The filter argument accepts a string,
$filter, and places it in the clause "having label like 
'%$filter%'".

B<$limit> -
Limit returned records. In order to simplify the selection 
process, you can specify a limit clause to only show a certain 
number of records from a member for selecting. The limit argument 
accepts a string, $limit, and places it in the clause "limit 
$limit", so it can be a single number, or two numbers separated
by a comma. 

B<$ignore> -
Ignore or not. Null or 0 for don't ignore, 1 for ignore. If a 
member is set to don't ignore, calling get_available() for another 
member will return records from the second member that are related
in some way (depending on match and group) to the first member's 
selections.  If a member is set to ignore, calling get_available() 
on another member will return records from the second member while 
completely ignoring the first member's selections.

=head2 get_available

  $available = $family->get_available($name);

  $available = $family->get_available(-name => $name);

  $available = $family->get_available(-label => $label);

Returns a member's available records, records related in some way 
to the currently selected records in other members, which are not
being ignored.

B<$name> or B<$label> - 
Specifies the member by name or label. 

B<$available> - 
A hash reference of all returned values.

B<$available-E<gt>{count}> - 
The number of available records.

B<$available-E<gt>{ids_array}> - 
An array reference of the ids of the available records.

B<$available-E<gt>{ids_select}> - 
An array reference of ids and labels. Each array member is a 
record's id and label separated by a tab: "$id\t$label". This is
used to populate a <SELECT> list using the CGI module so that 
you can see both the ids and labels selected by a user.

B<$available-E<gt>{labels_array}> - 
An array reference of the labels of the available records. 

B<$available-E<gt>{labels_hash}> - 
A hash reference of the labels of the available records, keyed 
by the available ids.

B<$available-E<gt>{labels_select}> - 
A hash reference of the labels of the available records, keyed 
by a record's id and label separated by a tab: "$id\t$label". This 
is used to populate a <SELECT> list using the CGI module so that 
you can see both the ids and labels selected by a user.

=head2 choose_available

  $chosen = $family->choose_available($name);

  $chosen = $family->choose_available(-name => $name);

  $chosen = $family->choose_available(-label => $label);

Narrows down a member's chosen records using the available 
records to that member. So if five records are selected in a 
member, but only three of those records are now available
(as if called with get_available()), this function will cause
the member to only have those three records chosen.

B<$name> or B<$label> - 
Specifies the member by name or label. 

B<$chosen> - 
A hash reference of all returned values. See the get_chosen()
function for all values within the hash.

=head2 get_reunion

  $reunion = $family->get_reunion($data,
                                  $use_names,
                                  $group_by,
                                  $order_by);

  $reunion = $family->get_reunion(-data        => $data,
                                  -use_names   => $use_names,
                                  -group_by    => $group_by,
                                  -order_by    => $order_by);

  $reunion = $family->get_reunion(-data        => $data,
                                  -use_labels  => $use_labels,
                                  -group_by    => $group_by,
                                  -order_by    => $order_by);

  $reunion = $family->get_reunion(-data         => $data,
                                  -use_name_ids => $use_name_ids,
                                  -group_by     => $group_by,
                                  -order_by     => $order_by);

  $reunion = $family->get_reunion(-data           => $data,
                                  -use_label_ids  => $use_label_ids,
                                  -group_by       => $group_by,
                                  -order_by       => $order_by);

Returns a report query of the values specified by $data, 
grouped and ordered by the values specified by $group_by and 
$order_by, using the chosen ids of members specified by
$use_names or $use_labels, or the ids specified by 
$use_name_ids or $use_label_ids.

B<$data> - 
Specifies the values by name to be selected in the reunion. 

B<$use_names> or B<$use_labels> - 
Specifies by name or label which members' chosen ids to use 
in narrowing down the report query. Either can be a comma 
delimitted string or array reference. 

B<$use_name_ids> or B<$use_label_ids> - 
Specifies by name or label which ids to use in narrowing down the 
report query. Must be a hash ref of strings of comma delimitted id 
values, keyed by name or label. 

B<$group_by> and B<$order_by> - 
Specifies the values by name to use in the group by and order 
by clause of the report query. Either can be a comma 
delimitted string or array reference. 

B<$reunion> - 
The report query in the form of a Relations::Query object. 

=head2 to_text

  $text = $family->to_text($string,$current);

Returns a text representation of a family. Useful for debugging purposes. 

B<$string> - 
String to use for indenting.  

B<$current> - 
Current number of indents.

B<$text> - 
Textual representation of the family object.

=head1 LIST OF RELATIONS::FAMILY PROPERTIES

=head2 abstract

The Relations::Abstract object a family uses to query and such.

=head2 members

An array reference of the members in a family.

=head2 names

A hash reference of the members in a family, keyed by members' names.

=head2 labels

A hash reference of the members in a family, keyed by members' labels.

=head2 values

A hash reference of the values in a family, keyed by values' names.

=head1 RELATIONS::FAMILY DEMO - FINDER

=head2 Setup

Included with this distribution is demo.pl, which demonstrates all the listed
functionality of Relations::Family. You must have MySQL, Perl, DBI, DBD-MySQL, 
Relations, Relations::Query, Relations::Abstract, and Relations::Family 
installed. 

After installing everything, run demo.pl by typing 

  perl demo.pl

while in the Relations-Family installation directory.

=head2 Overview

This demo revolves around the finder database. This database is for a made up 
company that sells three different types of products - Toiletry: Soap, Towels,
etc., Dining: Plates Cups, etc. and Office: Phones, Faxes, etc. The demo is an
app that allows you to search through that database

=head2 Structure

                    |---------|
                    |  item   |        |------------|
                    |---------|        |  product   |        |-----------|
                    | item_id |        |------------|        |   type    |
                /-M-|  pur_id |    /-1-|  prod_id   |        |-----------|
                |   | prod_id |-M-/    |  prod_name |    /-1-|  type_id  |
                |   |   qty   |        |  type_id   |-M-/    | type_name |
                |   |---------|        |------------|        |-----------|
                |
                |   |---------|         |--------------|
                |   | pur_sp  |         | sales_person |
                |   |---------|         |--------------|        
                |   |  ps_id  |     /-1-|    sp_id     |      |----------|  
                |-M-| pur_id  |    /    |    f_name    |      |  region  |
|-----------|   |   |  sp_id  |-M-/     |    l_name    |      |----------|
| purchase  |   |   |---------|         |    reg_id    |-M--1-|  reg_id  |
|-----------|   |                       |--------------|      | reg_name |
|  pur_id   |-1-/                                             |----------|
| cust_id   |-M-\      |--------------|          
|   date    |    \     |   customer   |          |--------------|
|-----------|     \    |--------------|          |   account    |
                   \-1-|   cust_id    |-1--\     |--------------|
                       |  cust_name   |     \    |    acc_id    |
                       |    phone     |      \-1-|   cust_id    |
                       |--------------|          |   balance    |
                                                 |--------------|      

There's a type table for the different types of products, and a product table 
for the different products. There's also a one-to-many relationship between type 
to product, because each product is of a specific type.

A similar relationship exists between the sales_person table, which holds all 
the different sales people, and the region table, which holds the regions for
the sales peoples. Each sales person belongs to a particular region, so there's
a one-to-many relationship from the region table to the sales_person table.

If there's sellers, there's buyers. This is the function of the customer 
table. There is also an account table, for the accounts for each customer.
Since each customer has only one account, there is merely a one-to-one
relationship between customer and account.

With sellers and buyers, there must be purchases. Enter the purchase table,
which holds all the purchases. Since only one customer makes a certain 
purchase, but one customer could make many purchases, there is a one-to-many 
relationship from the customer table to the purchase table.

Each purchase contains some number of products at various quantities. This is 
the role of the item table. One purchase can have multiple items, so there is
a one-to-many relationship from the purchase table to the item table. 

A product is the item purchased at different quantities, and a product can be
in multiple purchases. Thus, there is a one-to-many relationship from the 
product table to the item table.

Finally, zero or more sales people can get credit for a purchase, so there 
is many-to-many relationship between the sales_person and purchase tables.
This relationship is handled by the pur_sp table, so there is a one-to-many
relationship from the purchase table to the pur_sp table and a one-to-many 
relationship from the sales_person table to the pur_sp table.

=head2 Role of Family

Family's role in this is true to it's name sake: It brings all of this into
one place, and allows tables to connect to one another. A member in the finder 
family is created for each table in the finder database, and a lineage (for
one-to-many's) or a rivalry (for one-to-one's) for each relationship.

With Family, you can select records from one member and find all the 
connecting records in other members. For example, to see all the products
made by a purchase, you'd go to the purchase member, and select the purchase
in question, and then go to the product's member. The avaiable records
in product would be all the product on that purchase.

=head2 Usage

To run the demo, make sure you've followed the setup instructions, and go
to the directory in which you've placed demo.pl and finder.pm. Run demo.pl
like a regular perl script.

The demo starts with a numbered listing of all the members of the finder 
family. To view available records from a member and/or make selections, type
in the member's number and hit return. 

The first thing you'll be asked is if you want to choose available. This 
narrows down the current selected members of a list by the available 
records for a list. Enter 'Y' for yes, and 'N' for no. It defaults to 'N' so 
a blank is the same as no.

You'll then get two questions regarding the presentation of a member's 
records. I'll go into both here.

Limit is for displaying only a certain number of avaiable records at a time.
It's fed into a MySQL limit clause so it can be one number, or two separated
by a comma. To just see X number of rows from the begining, just enter X. To
see X number of rows starting at Y, enter Y,X. 

Filter is for filtering available records for display. It takes a string, and
only returns member's available records that have the entered string in their
label. Just enter the text to filter by.

You'll then get a numbered listing of all the available records for that member, 
as well as the match, group, ignore, limit and filter settings for that member. 

Next, you'll get some questions regarding which records are to be selectecd,
and how those selections are to be used (or not used!). I'll go into them here.

Selections are the records you want to choose. To choose records, type each 
number in, separating with commas. 

Match is whether you want other lists to match any of your multiple selections 
from this member or all of them. 0 for many, 1 for all.

Group is whether you want to include what was selected in this member, or 
exclude was selected, in matching other member's records. 0 for include,
1 for exclude.

Finally, you'll be asked if you want to do this again. 'Y' for yes, 'N' for
no. It defaults to 'Y', so just type return for yes. If you choose yes, 
you'll get a list of members, go through the selection/viewing process again.

If you press 'N', demo.pl will ask if you want to create a reunion. A reunion
is like a final report query. It defaults to 'N', so just type return for no. 
If you choose no, the program will exit. 

If you choose yes, you'll get a list of all the values in finder. At the Data
prompt, type in all values (by number) you'd like to see in the report query,
separating each with a comma. At the Group By prompt, type in all values (by 
number) you'd like to group by in the report query, separating each with a 
comma. At the Order By prompt, well, I bet you can figure it out. 

After filling out the value information, a list of all members will be 
displayed. You'll be asked which members chosen values should be used in the 
query. Enter the numbers of the members to use for this.

After that's all set, you'll get the customized results of your report query. 

=head2 Examples

All together, this system can be used to figure out a bunch of stuff. Here's
some ways to query certain records. With each example, it's best to restart 
demo.pl for scratch (exit and rerun).

B<Limit and Filter> - 
There are 17 Sales Persons in the database. Though this isn't terribly many, 
you can lower the number sales people displayed at one time with Family two 
different ways, by limitting or by filtering. Here's examples for both. 

First, let's look at all the sales people
- From the members list, select 7 for Sales Person.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 17 available records:

   (2)  Mimi Butterfield
   (12) Jennie Dryden
   (6)  Dave Gropenhiemer
   (14) Karen Harner
   (1)  John Lockland
   (4)  Frank Macena
   (13) Mike Nicerby
   (5)  Joyce Parkhurst
   (17) Calvin Peterson
   (8)  Fred Pirozzi
   (16) Mya Protaste
   (9)  Sally Rogers
   (15) Jose Salina
   (3)  Sheryl Saunders
   (11) Ravi Svenka
   (10) Jane Wadsworth
   (7)  Hank Wishings

These are all the sales people.
- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

Now, let's just look at the first 5 sales peoeple.
- From the members list, select 7 for Sales Person.
- Don't choose available. (or just hit return)
- Set limit to 5. 
- No filter. (or just hit return)
- There should be 5 available records: 

   (2)  Mimi Butterfield
   (12) Jennie Dryden
   (6)  Dave Gropenhiemer
   (14) Karen Harner
   (1)  John Lockland

These are the first 5 sales people
- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

How 'bout the last 5 sales people.
- From the members list, select 7 for Sales Person.
- Don't choose available. (or just hit return)
- Set limit to 12,5. 
- No filter. (or just hit return)
- There should be 5 available records:

   (15) Jose Salina
   (3)  Sheryl Saunders
   (11) Ravi Svenka
   (10) Jane Wadsworth
   (7)  Hank Wishings

These are the last 5 sales people. Limit started at the 12th record,
and allowed the next 5 records.
- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

Finaly, let's find all the sales people that have the letter 'y' in
the first or last name.
- From the members list, select 7 for Sales Person.
- Don't choose available, and no limit.  (or just hit return)
- Set filter to y. 
- There should be 6 available records: 

   (12) Jennie Dryden
   (13) Mike Nicerby
   (5)  Joyce Parkhurst
   (16) Mya Protaste
   (9)  Sally Rogers
   (3)  Sheryl Saunders

These are all the people with the letter 'y' in their first or last name.
- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply N, to 'Again?' (to go to reunion)
- Reply N, to 'Create Reunion?' (to quit)

B<The Selections Effect> - A purchase contains one or more products, and you can
see which product were purchased on a purchased order by selected a record
from the purchase member, and viewing the avaiable records of the product 
member. Varney solutions made a purchase on jan 4th, 2001, and we'd like to 
see what they bought.

First, let's see all the products.
- From the members list, select 3 for Product.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 13 available records:

   (6)  Answer Machine
   (13) Bowls
   (9)  Copy Machine
   (12) Cups
   (10) Dishes
   (8)  Fax
   (7)  Phone
   (11) Silverware
   (4)  Soap
   (3)  Soap Dispenser
   (5)  Toilet Paper
   (1)  Towel Dispenser
   (2)  Towels

These are all the products.
- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

Let's pick a purchase to view the products from.
- From the members list, select 5 for Purchase.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 8 available records:

   (6)  Last Night Diner - May 9th, 2001
   (3)  Harry's Garage - April 21st, 2001
   (7)  Teskaday Print Shop - April 7th, 2001
   (4)  Simply Flowers - March 10th, 2001
   (2)  Harry's Garage - February 8th, 2001
   (8)  Varney Solutions - January 4th, 2001
   (1)  Harry's Garage - December 7th, 2000
   (5)  Last Night Diner - November 3rd, 2000

- From the available records, select 8 for Varney Solutions' Purchase.
- Match = 0, Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

Now, we'll check out all the products on that purchase.
- From the members list, select 3 for Product.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 4 available records:

   (6)  Answer Machine
   (9)  Copy Machine
   (8)  Fax
   (7)  Phone

These are the products purchased by Varney in January.
- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply N, to 'Again?' (to go to reunion)
- Reply N, to 'Create Reunion?' (to quit)

B<Matching Multiple> - You can also lookup purchases by products. 
Furthermore you can look purcahses up by selecting many products, 
and finding purchases that have any of the selected products. You
can even find purchases that contain all the selected products. 

First, let's see all the purchases.
- From the members list, select 5 for Purchase.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 8 available records:

   (6)  Last Night Diner - May 9th, 2001
   (3)  Harry's Garage - April 21st, 2001
   (7)  Teskaday Print Shop - April 7th, 2001
   (4)  Simply Flowers - March 10th, 2001
   (2)  Harry's Garage - February 8th, 2001
   (8)  Varney Solutions - January 4th, 2001
   (1)  Harry's Garage - December 7th, 2000
   (5)  Last Night Diner - November 3rd, 2000

- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

Now, we'll check out all the products, select a few, and set matching to
any so we can purchases that have any (Soap or Soap Dispenser).
- From the members list, select 3 for Product.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 13 available records:

   (6)  Answer Machine
   (13) Bowls
   (9)  Copy Machine
   (12) Cups
   (10) Dishes
   (8)  Fax
   (7)  Phone
   (11) Silverware
   (4)  Soap
   (3)  Soap Dispenser
   (5)  Toilet Paper
   (1)  Towel Dispenser
   (2)  Towels

These are all the products.
- From the available records, select 4,3 for Soap, and Soap Dispenser
- Match = 0, Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

Now, we'll see which purchases contain either Soap or Soap Dispenser.
- From the members list, select 5 for Purchase.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 3 available records:

   (3)  Harry's Garage - April 21st, 2001
   (2)  Harry's Garage - February 8th, 2001
   (1)  Harry's Garage - December 7th, 2000

- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

Now, we'll check out all the products, select a few, and set matching to
all so we can purchases that have all (Soap and Soap Dispenser).
- From the members list, select 3 for Product.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 13 available records, Soap and Soap Dispenser *'ed,

   (6)  Answer Machine
   (13) Bowls
   (9)  Copy Machine
   (12) Cups
   (10) Dishes
   (8)  Fax
   (7)  Phone
   (11) Silverware
 * (4)  Soap
 * (3)  Soap Dispenser
   (5)  Toilet Paper
   (1)  Towel Dispenser
   (2)  Towels

These are all the products, with Soap and Soap Dispenser already selected.
- From the available records, select 4,3 for Soap, and Soap Dispenser
- Match = 1 (means 'all')
- Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

Now, we'll see which purchase contain both Soap and Soap Dispenser.
- From the members list, select 5 for Purchase.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 1 available record:

   (1)  Harry's Garage - December 7th, 2000

This is the only purchase that contains both Soap and Soap Dispenser. 
- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply N, to 'Again?' (to go to reunion)
- Reply N, to 'Create Reunion?' (to quit)

B<Group Inclusion/Exclusion> - Sometimes you'd like to find all records
the records not connected to your selections from a particular member.
Say you wanted to check up on all the orders from customers, except the
Harry's Garage, who would have already let you know if there was a 
problem.

First, let's see all the purchases.
- From the members list, select 5 for Purchase.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 8 available records:

   (6)  Last Night Diner - May 9th, 2001
   (3)  Harry's Garage - April 21st, 2001
   (7)  Teskaday Print Shop - April 7th, 2001
   (4)  Simply Flowers - March 10th, 2001
   (2)  Harry's Garage - February 8th, 2001
   (8)  Varney Solutions - January 4th, 2001
   (1)  Harry's Garage - December 7th, 2000
   (5)  Last Night Diner - November 3rd, 2000

- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply Y, to 'Again?' (to select another member)

Let's pick a customer to not view the purchases from.
- From the members list, select 1 for Customer.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 5 available records:

   (1)  Harry's Garage
   (4)  Last Night Diner
   (3)  Simply Flowers
   (5)  Teskaday Print Shop
   (2)  Varney Solutions

- From the available records, select 1 for Harry's Garage.
- Match = 0 (or just hit return)
- Group = 1 (means 'exclude')
- Reply Y, to 'Again?' (to select another member)

Now, we'll check out all the purchases not from Harry's Garage.
- From the members list, select 5 for Purchase.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 5 available records:

   (6)  Last Night Diner - May 9th, 2001
   (7)  Teskaday Print Shop - April 7th, 2001
   (4)  Simply Flowers - March 10th, 2001
   (8)  Varney Solutions - January 4th, 2001
   (5)  Last Night Diner - November 3rd, 2000

- No Selections (or just hit return)
- Match = 0, Group = 0 (or just hit return)
- Reply N, to 'Again?' (to go to reunion)
- Reply N, to 'Create Reunion?' (to quit)

B<Basic Reunion> - Let's first check out which customers 
owe us money, except for Varney Solutions of course, since
we owe them a favor. 

First, let's see all the customers.
- From the members list, select 1 for Customer.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 8 available records:

   (1)  Harry's Garage
   (4)  Last Night Diner
   (3)  Simply Flowers
   (5)  Teskaday Print Shop
   (2)  Varney Solutions

- From the available records, select 2 for Varney Solutions
- Match = 0 (or just hit return)
- Group = 1 (means 'exclude')
- Reply N, to 'Again?' (to go to reunion)
- Reply Y, to 'Create Reunion?' (to create a report)

Next, we have to decide which values we want in out report. After 
selecting create reunion, you should get a list of all values. 
- Data = select 0,1,2 for Customer, their Account and whether or 
not they've paid, Paid.
- Group By = (just hit return)
- Order By = 1, to order by customer.

Finally, we have to decide which members we're going to use to 
narrow down the query. A list will be displayed of all members
in finder.
- From the members list, select 1 for Customer.
- You should get 4 results, each with 3 fields:

  Customer: Harry's Garage
  Cust. Account: Harry's Garage - 134.87
  Paid: NO

  Customer: Last Night Diner
  Cust. Account: Last Night Diner - 54.65
  Paid: NO

  Customer: Simply Flowers
  Cust. Account: Simply Flowers - 0.00
  Paid: YES

  Customer: Teskaday Print Shop
  Cust. Account: Teskaday Print Shop - 357.72
  Paid: NO

B<Advanced Reunion> - Let's see how many each each Office
product we sold and sort from least to most of numbers
sold.

First, let's see all the product types.
- From the members list, select 8 for Type.
- Don't choose available, no limit, and no filter. (or just hit return)
- There should be 8 available records:

   (3)  Dining
   (2)  Office
   (1)  Toiletry

- From the available records, select 2 for Office
- Match = 0 (or just hit return)
- Group = 0 (or just hit return)
- Reply N, to 'Again?' (to go to reunion)
- Reply Y, to 'Create Reunion?' (to create a report)

Next, we have to decide which values we want in out report.  
- Data = select 3,9 for Product and Sold
- Group By = select 3 for Product
- Order By = select 9 for Sold

Finally, we have to decide which members we're going to use to 
narrow down the query. A list will be displayed of all members
in finder.
- From the members list, type 8 for Type.
- You should get 4 results, each with 2 fields:

  Sold: 2
  Product: Answer Machine

  Sold: 2
  Product: Fax

  Sold: 7
  Product: Phone

  Sold: 15
  Product: Copy Machine

=head1 CHANGE LOG

=head2 Relations-Family-0.94

B<Setting Get Reunion IDs>

Added functionality to get_reunion to accept an alternative set of 
member' ids to use in the reunion query. This was done for the 
Relations::Report module's Iteration module.

=head2 Relations-Family-0.93

B<Add Member Query Cloning>

If a Relations::Query object is sent to the add_member() function 
through $query, that query is now cloned so Relations-Family won't
muck with the original. 

B<Query Argument Functionality>

Originally, the help files said that any function requiring a $query
argument could take a Relations::Query argument, a hash, or a string.
This isn't true (even before the above changes). The functions 
require a hash of query pieces (keyed with select, from, etc.) or a
Relations::Query object. This is because Relations::Family builds on 
the query and needs the pieces separated to do this.

=head1 TODO LIST

B<Local Listing>

Add functionality to the Member module so that a member can function
as lookup values for a certain field. This would allow enum fields to 
be tied to a member, and allow user to select enum field values to 
narrow down a query. 

B<Names and Labels of Values>

Add a name and label property to the Value modules. This is so Family
will be more XML compatible since the Value module's current name 
property can contain spaces and would be ill suited for an ID value 
since it can contain spaces. Value will then be like Member will a 
lowercase no spaces name for internals and a anything goes label for
display purposes.

B<XML Functionality>

Add functionality so that a Family module (and all its kids) can 
import and export their configuration to XML. This will be useful when 
the PHP and Java versions of Relations::Family come about. People
will be able to port from one language to another with little effort.

=head1 OTHER RELATED WORK

=head2 Relations (Perl)

Contains functions for dealing with databases. It's mainly used as 
the foundation for the other Relations modules. It may be useful for 
people that deal with databases as well.

=head2 Relations-Query (Perl)

An object oriented form of a SQL select query. Takes hashes.
arrays, or strings for different clauses (select,where,limit)
and creates a string for each clause. Also allows users to add to
existing clauses. Returns a string which can then be sent to a 
database. 

=head2 Relations-Abstract (Perl)

Meant to save development time and code space. It takes the most common 
(in my experience) collection of calls to a MySQL database, and changes 
them to one liner calls to an object.

=head2 Relations-Admin (PHP)

Some generalized objects for creating Web interfaces to relational 
databases. Allows users to insert, select, update, and delete records from 
different tables. It has functionality to use tables as lookup values 
for records in other tables.

=head2 Relations-Family (Perl)

Query engine for relational databases.  It queries members from 
any table in a relational database using members selected from any 
other tables in the relational database. This is especially useful with 
complex databases: databases with many tables and many connections 
between tables.

=head2 Relations-Display (Perl)

Module creating graphs from database queries. It takes in a query through a 
Relations-Query object, along with information pertaining to which field 
values from the query results are to be used in creating the graph title, 
x axis label and titles, legend label (not used on the graph) and titles, 
and y axis data. Returns a graph and/or table built from from the query.

=head2 Relations-Report (Perl)

A Web interface for Relations-Family, Reations-Query, and Relations-Display. 
It creates complex (too complex?) web pages for selecting from the different 
tables in a Relations-Family object. It also has controls for specifying the 
grouping and ordering of data with a Relations-Query object, which is also 
based on selections in the Relations-Family object. That Relations-Query can 
then be passed to a Relations-Display object, and a graph and/or table will 
be displayed.

=head2 Relations-Structure (XML)

An XML standard for Relations configuration data. With future goals being 
implmentations of Relations in different languages (current targets are 
Perl, PHP and Java), there should be some way of sharing configuration data
so that one can switch application languages seamlessly. That's the goal
of Relations-Structure A standard so that Relations objects can 
export/import their configuration through XML. 

=cut