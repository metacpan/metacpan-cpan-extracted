# This is a component of a DBI/DBD-MySQL Relational Query Engine module. 

package Relations::Family::Value;
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

$Relations::Family::Value::VERSION = '0.93';

@ISA = qw(Exporter);

@EXPORT    = ();		

@EXPORT_OK = qw(new);

%EXPORT_TAGS = ();

# From here on out, be strict and clean.

use strict;



### Create a Relations::Family::Value object. This object 
### holds sql value and which members are needed to 
## create this value.

sub new {

  # Get the type we were sent

  my ($type) = shift;

  # Get all the arguments passed

  my ($name,
      $sql,
      $members) = rearrange(['NAME',
                             'SQL',
                             'MEMBERS'],@_);

  # $name - The name in the query of this value
  # $sql  - The SQL field/equation of this value
  # $members  - Members that hold this value 

  # Create the hash to hold all the vars
  # for this object.

  my $self = {};

  # Bless it with the type sent (I think this
  # makes it a full fledged object)

  bless $self, $type;

  # Add the info into the hash

  $self->{name} = $name;
  $self->{sql} = $sql;
  $self->{members} = $members;

  # Give thyself

  return $self;

}



### Returns text info about the Relations::Family::Value 
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

  $text .= $indent . "Relations::Family::Value: $self\n\n";
  $text .= $indent . "Name: $self->{name}\n";
  $text .= $indent . "SQL:  $self->{sql}\n";
  $text .= $indent . "Members:\n";
  
  foreach my $member (@{$self->{members}}) {

    $text .= $subindent . "Label: $member->{label} ";
    $text .= $subindent . "Name: $member->{name} ";
    $text .= $subindent . "Member: $member\n";

  }

  $text .= "\n";

  # Return the text

  return $text;

}

$Relations::Family::Value::VERSION;