## @file
# (Enter your file info here)
#
# @copy 2007 MailerMailer LLC
# $Id: SCF.pm 498 2008-08-22 15:35:28Z kamelkev $

## @class RWDE::Doxy::SCF
# S(ource)C(ode)F(file) is going to be implementing DoxGenerator interface it's going to be doxygenable
package RWDE::Doxy::SCF;

use strict;
use warnings;

use Error qw(:try);
use RWDE::Exceptions;

use RWDE::Doxy::ClassData;
use RWDE::Doxy::MethodData;

use base qw(RWDE::RObject RWDE::Doxy::DocGenerator);

our (%fields, %static_fields, %modifiable_fields, @fieldnames, @static_fieldnames, @modifiable_fieldnames);

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

    file_location      => [ 'char',  'Location of the file' ],
    file_content_in    => [ 'array', 'Content of the file_name. Each element is one line of the file' ],
    file_content_out   => [ 'array', 'Conetnt for the output file' ],
    file_index         => [ 'int',   'An index of a line of file_content' ],
    file_current_class => [ 'char',  'Cursor for class name that is being processed.' ],
    file_classes       => [ 'hash',  'A hash of (class name, class_data) pairs. All classes in this file' ],

    #Array is used because we need to preserver order.
    file_info => [ 'array', 'list of file-related doxygen info lines that existed in the source file_content' ]
  );

  %fields = (%static_fields, %modifiable_fields);

  @static_fieldnames     = sort keys %static_fields;
  @modifiable_fieldnames = sort keys %modifiable_fields;
  @fieldnames            = sort keys %fields;

}

## @method void initialize()
# (Enter initialize info here)
sub initialize() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No file_location specified' })
    unless defined($$params{file_location});

  $self->file_location($$params{file_location});
  $self->file_content_in($self->_read_file());
  $self->file_content_out([]);
  $self->file_index(0);
  $self->file_classes({});
  $self->file_current_class(undef);
  $self->file_info([]);

  return ();
}

## @method object current_line()
# Return file_content[file_index], the data residing in the file_index of file_content
# @return The current line
sub current_line() {
  my ($self, $params) = @_;

  return undef
    unless ($self->file_index < scalar @{ $self->file_content_in });

  #return file_content[file_index] if we are within the bounds of the array, undef oterwise
  return $self->file_content_in->[ $self->file_index ];
}

## @method void next_line()
# Increment the file_index + 1
sub next_line() {
  my ($self, $params) = @_;

  $self->file_index($self->file_index + 1);
  return ();
}

#Reset the file_index
# @return (Enter explanation for return value here)
## @method void reset_file_index()
# (Enter reset_file_index info here)
sub reset_file_index() {
  my ($self, $params) = @_;

  $self->file_index(0);
  return ();
}

#Reset the file_index
## @method object reset_file_current_class()
# (Enter reset_file_current_class info here)
# @return (Enter explanation for return value here)
sub reset_file_current_class() {
  my ($self, $params) = @_;

  return $self->file_current_class(undef);
}

#Reset the file_content_out to an empty array
## @method void reset_file_content_out()
# (Enter reset_file_content_out info here)
sub reset_file_content_out() {
  my ($self, $params) = @_;

  $self->file_content_out([]);

  return ();
}

## @method object get_file_name()
# Convert absolute file name to relative file name
# '/web/imageserver/testing/AddKbAndTipIdTester.pl' => 'AddKbAndTipIdTester.pl'
# @return filename
sub get_file_name() {
  my ($self, $params) = @_;

  my @split = split('/', $self->file_location);
  return pop @split;
}

## @method object get_file_directory()
# Get the file directory for the file_location
# @return file directory
sub get_file_directory() {
  my ($self, $params) = @_;

  #Return the path excluding the relative name
  #Ex: '/web/imageserver/testing/ManyAssessors.pm' => '/web/imageserver/testing/'
  #Return empty string if relative path = absolute path
  #Ex: 'ManyAssessors.pm' => ''
  return ($self->file_location =~ /(.*)(\/)(.*)/) ? ($1 . $2) : '';
}

## @method protected object _read_file()
# Get the file contents from the file_location
# @return Contents of the file as array
sub _read_file() {
  my ($self, $params) = @_;

  open(HANDLE, $self->file_location())
    or throw RWDE::DevelException({ info => 'Could not open file' });

  my @file_array = <HANDLE>;

  close(HANDLE)
    or throw RWDE::DevelException({ info => 'Could not close file' });

  return \@file_array;
}

## @method void save($save_file_name)
# Write the documented file to disk. If param save_file_name exists, then move current file to file_location + save_file_name.
# Place new file at old location.
# If params save_file_name dne, then simply save it to file_location . ".doxy"
# @param save_file_name  The name of the destination file to save to
sub save() {
  my ($self, $params) = @_;

  my $new_file_path;

  #If a relative file name is passed in: move the existing file at file_location over to file_directory . save_file_name
  #Save new file into former location.
  if (defined($$params{save_file_name})) {
    rename($self->file_location, $self->get_file_directory() . $$params{save_file_name});
    $new_file_path = $self->file_location();
  }

  #Otherwise simply append .doxy to the end of the current location and leave alone the original file.
  else {
    $new_file_path = $self->file_location . '.doxy';
  }

  open(WRITE_HANDLE, '+>' . $new_file_path)
    or throw RWDE::DevelException({ info => 'Could not open file' });
  my $out = join('', @{ $self->file_content_out });
  print WRITE_HANDLE $out;
  close(WRITE_HANDLE)
    or throw RWDE::DevelException({ info => 'Could not close file' });

  return ();
}

## @method void add_to_file_out($content)
# Add new line to update_file_data
# @param content  (Enter explanation for param here)
sub add_to_file_out() {
  my ($self, $params) = @_;

  my @lines;
  if (ref $$params{content} eq 'ARRAY') {
    @lines = @{ $$params{content} };
  }
  elsif (defined $$params{content}) {
    push @lines, $$params{content};
  }

  foreach my $line (@lines) {
    push(@{ $self->file_content_out }, $line);
  }

  return ();
}

## @method void add_range_to_file_out($end_index, $start_index)
# Copy lines over from file_content to file_content_out
# @param end_index  Last line number to copy
# @param start_index  First line number to copy
sub add_range_to_file_out() {
  my ($self, $params) = @_;

  my @required = qw( start_index end_index );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  for (my $file_index = $$params{start_index} ; $file_index <= $$params{end_index} ; $file_index++) {
    $self->add_to_file_out({ content => $self->file_content_in->[$file_index] });
  }

  return ();
}

## @method object add_new_class()
# Create a new class data object and add it to file_classes hash
# @return (Enter explanation for return value here)
sub add_new_class() {
  my ($self, $params) = @_;

  my $class_data = new RWDE::Doxy::ClassData($params);

  $self->file_classes->{ $class_data->class_name } = $class_data;

  return $class_data;
}

## @method object get_class($class_name)
# Returns the class_method object for a class name or creates and returns a new one if one does not exists.
# @param class_name  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub get_class() {
  my ($self, $params) = @_;

  my @required = qw( class_name );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  my $class_data;

  if (not defined($self->file_classes->{ $$params{class_name} })) {
    $class_data = $self->add_new_class({ class_name => $$params{class_name} });
  }
  else {
    $class_data = $self->file_classes->{ $$params{class_name} };
  }

  return $class_data;
}

## @method object get_current_class()
# Returns the current class object in class_data form
# @return (Enter explanation for return value here)
sub get_current_class() {
  my ($self, $params) = @_;

  return $self->get_class({ class_name => $self->file_current_class });
}

## @method void add_info($info_line)
# Add a param to the parameter list
# @param info_line  (Enter explanation for param here)
sub add_info() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No info line to add to info_list' })
    unless defined($$params{info_line});

  my $file_info = $self->file_info;

  push(@{$file_info}, $$params{info_line});

  return ();
}


1;
