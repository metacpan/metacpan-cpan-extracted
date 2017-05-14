## @file
# (Enter your file info here)
#
# @copy 2007 MailerMailer LLC
# $Id: MethodData.pm 432 2008-05-02 19:17:09Z damjan $

## @class RWDE::Doxy::MethodData
# This class stores an intermediate representation of a method for a class.
# method_params stores a list of param name located within the method
# method_brackets_count is used to tally { and }. It will be incremented for every { and decremented for every }.
# method_return_type stores the return type of the method. It will be either object or void.
package RWDE::Doxy::MethodData;

use strict;
use warnings;

use Error qw(:try);
use RWDE::Exceptions;

use base qw(RWDE::RObject);

use constant PUBLIC_METHOD    => "public";
use constant PROTECTED_METHOD => "protected";

our (@fieldnames, %fields, %static_fields, %modifiable_fields, @static_fieldnames, @modifiable_fieldnames);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 518 $ =~ /(\d+)/;

BEGIN {

  #all of the static fields present in the list table
  %static_fields = (

    # Field => [Type, Descr]
  );

  #all of the fields allowed to be modified in the list table
  %modifiable_fields = (

    # Field => [Type, Descr]
    method_name => [ 'char', 'Name of the method' ],

    #Use a hash for method_params because we want a set.
    method_params         => [ 'hash', 'Array of param names' ],
    method_brackets_count => [ 'int',  'State of bracket matches' ],
    method_return_type    => [ 'char', 'Bracket return type' ],
    method_type           => [ 'char', 'method or cmethod (new/constructor)' ],
    method_privileges     => [ 'char', 'public or protected' ],

    #Array is used for method_info because we need to preserver order.
    method_info        => [ 'array', 'list of all of the doxygen info lines that existed in the source file_content' ],
    method_param_info  => [ 'hash',  'info text displayed after the @param' ],
    method_return_info => [ 'char',  'info text displayed after the @return' ]
  );

  %fields = (%static_fields, %modifiable_fields);

  @static_fieldnames     = sort keys %static_fields;
  @modifiable_fieldnames = sort keys %modifiable_fields;
  @fieldnames            = sort keys %fields;
}

## @method object initialize($method_name)
# Create a new Object with the given method name
# @param method_name  (Enter explanation for param here)
# @return
sub initialize() {
  my ($self, $params) = @_;

  $self->method_params({});
  $self->method_brackets_count(0);
  $self->method_return_type('void');
  $self->method_name($$params{method_name});
  $self->method_info([]);
  $self->method_param_info({});

  #'new'/constructor object are represented by 'cmethod' command.
  #Any class method is also represented by cmethod other methods are represented by 'method' command
  $self->method_type(($self->method_name eq 'new' or $self->method_name =~ /^[A-Z]/) ? "cmethod" : "method");

  #We are only going to use protected and public for our perl methods.
  #Methods beginning with an underscore will be considered protected (Denoted by 'protected')
  #Methods otherwise will be considered public (Denoted by nothing)
  $self->method_privileges(($self->method_name =~ /^_/) ? PROTECTED_METHOD : PUBLIC_METHOD);

  return ();
}

## @method object increment_brackets_count()
# Increment the bracket level count
# @return (Enter explanation for return value--(Enter explanation for return value--(Enter explanation for return value here)--here)--here)
sub increment_brackets_count() {
  my ($self, $params) = @_;

  $self->method_brackets_count($self->method_brackets_count + 1);

  return $self->method_brackets_count;
}

## @method object decrement_brackets_count()
# Decrement the bracket level count
# @return (Enter explanation for return value--(Enter explanation for return value--(Enter explanation for return value here)--here)--here)
sub decrement_brackets_count() {
  my ($self, $params) = @_;

  #We do not want a negative number here. If we do then the parsed method has more } then {
  throw RWDE::DevelException({ info => 'Trying to set increment_brackets_count to negative number. Does the file compile?' })
    unless ($self->method_brackets_count - 1 >= 0);

  $self->method_brackets_count($self->method_brackets_count - 1);

  return $self->method_brackets_count;
}

## @method void add_param($param_name)
# Add a param to the parameter list
# @param param_name  The name of the parameter we are adding
sub add_param() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No param to add to param list' })
    unless defined($$params{param_name});

  #We only want a hash because we want a set.
  #The '1' serves as a dummy value and has no true meaning.
  $self->method_params->{ $$params{param_name} } = 1;

  return ();
}

## @method void add_info($info_line)
# Add an info
# @param info_line  (Enter explanation for param here)
sub add_info() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No info line to add to info_list' })
    unless defined($$params{info_line});

  my $method_info = $self->method_info;

  push(@{$method_info}, $$params{info_line});

  return ();
}

## @method void add_param_info($param_info, $param_name)
# Store param info: everything after @param
# @param param_info  (Enter explanation for param here)
# @param param_name  (Enter explanation for param here)
sub add_param_info() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No param_name specified' })
    unless defined($$params{param_name});
  throw RWDE::DataMissingException({ info => 'No param_info specified' })
    unless defined($$params{param_info});

  $self->method_param_info->{ $$params{param_name} } = $$params{param_info};

  return ();
}

## @method object get_param_info($param_name)
# (Enter get_param_info info here)
# @param param_name  (Enter explanation for param here)
# @return (Enter explanation for return value--(Enter explanation for return value--(Enter explanation for return value here)--here)--here)
sub get_param_info() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No param_specified' })
    unless defined($$params{param_name});

  return $self->method_param_info()->{ $$params{param_name} };
}

## @method object set_return_info($return_info)
# Store return info: everything after @return
# @param return_info  (Enter explanation for param here)
# @return (Enter explanation for return value--(Enter explanation for return value--(Enter explanation for return value here)--here)--here)
sub set_return_info() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No return_info specified' })
    unless defined($$params{return_info});

  $self->method_return_info($$params{return_info});

  return ();
}

## @method object param_list()
# This is a convenience method to simply print out an array of keys. This is what we wanted anyway.
# A hash was used simply because a set was needed.
# @return (Enter explanation for return value--(Enter explanation for return value--(Enter explanation for return value here)--here)--here)
sub param_list() {
  my ($self, $params) = @_;

  return sort keys %{ $self->method_params };
}

## @method object param_list_as_string()
# Return the params as a string, delim by ", "
# Ex: "$param1, $param2, $param3"
# @return (Enter explanation for return value--(Enter explanation for return value--(Enter explanation for return value here)--here)--here)
sub param_list_as_string() {
  my ($self, $params) = @_;

  my @param_list = $self->param_list();
  my $param_string;

  #Join everything together as a string. Prepend every element with a '$' because they are all references.
  if (scalar @param_list > 0) {
    $param_string = join(', $', @param_list);

    #Need to prepend the string so that the initial param will begin with '$'
    $param_string = '$' . $param_string;
  }
  else {
    $param_string = '';
  }

  return $param_string;
}

## @method object method_description()
# Print out the title of the method
# Ex. 'object new_from_file($file1, $file2)'
# @return (Enter explanation for return value--(Enter explanation for return value--(Enter explanation for return value here)--here)--here)
sub method_description() {
  my ($self, $params) = @_;

  #Only print out protected
  my $privileges = (($self->method_privileges eq PUBLIC_METHOD) ? '' : (PROTECTED_METHOD . ' '));

  return $privileges . $self->method_return_type . ' ' . $self->method_name . '(' . $self->param_list_as_string() . ')';
}

1;
