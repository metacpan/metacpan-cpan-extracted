## @file
# (Enter your file info here)
# 
# @copy 2007 MailerMailer LLC
# $Id: ClassData.pm 498 2008-08-22 15:35:28Z kamelkev $

## @class RWDE::Doxy::ClassData
# This class stores an intermediate representation of a class (or package).
package RWDE::Doxy::ClassData;

use strict;
use warnings;

use Error qw(:try);
use RWDE::Exceptions;

use RWDE::Doxy::MethodData;

use base qw(RWDE::RObject);

our (%fields, %static_fields, %modifiable_fields, @fieldnames, @static_fieldnames, @modifiable_fieldnames);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 518 $ =~ /(\d+)/;

BEGIN {

  #all of the static fields present 
  %static_fields = (

    # Field => [Type, Descr]
  );

  #all of the fields allowed to be modified 
  %modifiable_fields = (

    # Field => [Type, Descr]
    class_name    => [ 'char', 'Name of the class' ],
    class_methods => [ 'hash', 'Hash of methods for this class. The keys will be the method names and the values will be corresponding MethodData objects' ],

    #Array is used for class_info because we need to preserver order.
    class_info => [ 'array', 'list of all of the doxygen info lines that existed in the source file_content' ]

  );

  %fields = (%static_fields, %modifiable_fields);

  @static_fieldnames     = sort keys %static_fields;
  @modifiable_fieldnames = sort keys %modifiable_fields;
  @fieldnames            = sort keys %fields;
}

## @method void initialize($class_name)
# (Enter initialize info here)
# @param class_name  (Enter explanation for param here)
sub initialize() {
  my ($self, $params) = @_;

  $self->class_name($$params{class_name});

  $self->class_methods({});
  $self->class_info([]);

  return ();
}

#Create a new class data object and add it to file_classes hash
## @method object add_new_method()
# (Enter add_new_method info here)
# @return (Enter explanation for return value here)
sub add_new_method() {
  my ($self, $params) = @_;

  my $method_data = new RWDE::Doxy::MethodData($params);

  $self->class_methods->{ $method_data->method_name } = $method_data;

  return $method_data;
}

#Add a param to the parameter list
## @method void add_info($info_line)
# (Enter add_info info here)
# @param info_line  (Enter explanation for param here)
sub add_info() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No info line to add to info_list' })
    unless defined($$params{info_line});

  my $class_info = $self->class_info;

  push(@{$class_info}, $$params{info_line});

  return ();
}

## @method object get_method($method_name)
# Returns the class_method object for a class name or creates and returns a new one if one does not exists.
# @param method_name  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub get_method() {
  my ($self, $params) = @_;

  my @required = qw( method_name );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  my $method_data;

  if (not defined($self->class_methods->{ $$params{method_name} })) {
    $method_data = $self->add_new_method({ method_name => $$params{method_name} });
  }
  else {
    $method_data = $self->class_methods->{ $$params{method_name} };
  }

  return $method_data;
}

1;
