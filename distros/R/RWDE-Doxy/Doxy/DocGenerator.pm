## @file
# (Enter your file info here)
#
# @copy 2007 MailerMailer LLC
# $Id: DocGenerator.pm 353 2007-08-14 17:46:43Z damjan $

## @class RWDE::Doxy::DocGenerator
# Note: This class is abstract.
# It makes calls to fields that do not exist.
# Please do not instantiate.

package RWDE::Doxy::DocGenerator;

use strict;
use warnings;

use Error qw(:try);

use RWDE::Exceptions;
use RWDE::Doxy::MethodData;

use constant COMMENT        => '#';    #Comments start with this character
use constant COMMAND_PREFIX => '@';    #Prefix of the command

use constant CHARACTER_SIZE => 1;      #Size of one character
use constant PARAM_SIZE     => 9;      #Size of '$$params{'
use constant RETURN_SIZE    => 6;      #Size of 'return'

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 518 $ =~ /(\d+)/;

## @method void doxygenate()
# Write/save the content to file. if you give a filename overwrites the original saves backup into the filename given
# this function takes the filename gets the contents and creates all the tags we know how returns the marked up contents
sub doxygenate() {
  my ($self, $params) = @_;

  #Process the file, placing all non_doxy lines into file_content_out
  #also populate MethodData and class data with the necessary info.
  $self->_create_intermediate_data();

  #We now	have intemediate data in file_content_out
  #We want to read from the file_content_out and write the complete doxygenated file
  #So place the file_content_out into the file_content_in.
  #Reset the file and class cursors.
  #Reset file content out
  $self->file_content_in($self->file_content_out);
  $self->reset_file_index();
  $self->reset_file_content_out();
  $self->reset_file_current_class();

  #Insert initial info on top of page
  $self->_insert_file_data();

  #Insert all other command and info
  $self->_insert_document_data();

  return ();
}

## @method protected void _create_intermediate_data()
# Form an array of intermediate data. This will consist of all lines in file_content_in that are not doxy_lines
# Also populate class and method data so we can preserve doxy comments.
# (We can then add them back in somewhere else)
sub _create_intermediate_data() {
  my ($self, $params) = @_;

  #Loop through every line of the file and parse/analyze it.
  while ($self->current_line()) {

    #if it is a doxy command tag

    #enter if the current line is a doxy tag command
    if ($self->current_line() =~ /^\s*## @(\S+)\s?(.*)(\n)/) {
      my $command_name = $1;
      my $command_info = $2;

      #Already saw the command. We will not need it again so increment the file index
      #We will regenerate this line when we remake the doxy tags so this will not be added to file_content_out
      $self->next_line();

      if ($command_name eq 'file') {
        $self->_store_file_info();
      }
      elsif ($command_name eq 'class') {

        #Command info consists of the class name
        #Ex:
        #@class <class_name>
        #@class is the $command_name, whicle the class name is the $command_info,
        $self->_store_class_info({ command_info => $command_info });

        #Methods will need to know what class they belong to
        #We will keep the name of this class handy so we can store the methods' method_data in the correct class_data
        $self->file_current_class($command_info);
      }
      elsif ($command_name eq 'method' or $command_name eq 'cmethod') {
        $self->_store_method_info({ command_info => $command_info });
      }
      else {

        #This tag could be a todo, enum, etc. So just echo it to file_out
        $self->add_to_file_out({ content => $self->current_line() });
        $self->next_line();
      }
    }

    #This is not a tag so just add the line to the end of file_content_intermediate
    else {
      $self->add_to_file_out({ content => $self->current_line() });
      $self->next_line();
    }
  }
}

## @method protected void _store_file_info()
# Store all \@file-related doxy info lines (no command present) for later use.
# All \@file info is placed at the top of the perl document file.
sub _store_file_info() {
  my ($self, $params) = @_;

  $self->_store_info({ data => $self });
}

## @method protected void _store_class_info($command_info, $command_info})
# Store all \@class-related doxy info lines (no command present) for later use.
# @param command_info  (Enter explanation for param here)
sub _store_class_info() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No class_name specified' })
    unless defined($$params{command_info});

  $self->_store_info({ data => $self->get_class({ class_name => $$params{command_info} }) });

  return ();
}

## @method protected void _store_method_info($command_info)
# Store all \@method-related doxy info lines (no command present) for later use.
# @param command_info  (Enter explanation for param here)
sub _store_method_info() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No class_name specified' })
    unless defined($$params{command_info});

  my $class_data = $self->get_class({ class_name => $self->file_current_class });

  $$params{command_info} =~ /(\S+)\(.*\)\s*$/;

  my $method_data = $class_data->get_method({ method_name => $1 });

  $self->_store_info({ data => $method_data, sub_info => 1 });

  return ();
}

## @method protected void _store_info($data)
# Checks to see if a class info exists
# If a ClassData entry exists then tell it to store the info lines
# If it does not exist then create a new ClassData object and populate the info
# @param data  (Enter explanation for param here)
sub _store_info() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No data specified' })
    unless defined($$params{data});

  my $data = $$params{data};

  #While we are looking at a "block" of doxy tags (every line until we do not start a line with "# ")
  while ($self->current_line() =~ /^\s*#\s(.*)\n/) {

    #@ implies that a tag exists so ignore anything that is not an info line
    #However, we will need to store params, etc.
    if ($self->current_line() !~ /^\s*#\s\@(\S+)\s*(.*)/) {
      $data->add_info({ info_line => $1 });
    }
    else {

      #Files and classes do not have params and returns.
      #But methods do 
      #This area will only be intered if sub_info param is defined.
      if (defined($$params{sub_info})) {
        if ($1 eq 'param') {
          my $param_info = $2;

          $param_info =~ /(\S+)\s*(.*)/;

          $data->add_param_info({ param_name => $1, param_info => $2 });
        }
        elsif ($1 eq 'return') {
          $data->set_return_info({ return_info => $2 });
        }
      }
    }

    $self->next_line();
  }

  return ();
}

## @method protected void _insert_file_data()
#Insert \@file template info at the top of the file
#Four lines, where filename is the file_name of the file.
#		## \@file
#		# (Enter your file info here)
#		#
#		# \@copy 2007 MailerMailer LLC
#		# Subversion ID tag
sub _insert_file_data() {
  my ($self, $params) = @_;

  my $info_lines = $self->file_info();

  #Create the entire tag for this command
  $self->add_to_file_out({ content => $self->_command({ command => 'file' }) });

  #Want to check if we store any @file lines
  if (scalar @{$info_lines} > 0) {

    #We have some lines stored. Add them in
    $self->_insert_info_lines({ info_lines => $info_lines });
  }
  else {

    #No lines were found so generate the default stuff.
    $self->add_to_file_out({ content => $self->_info({ info => '(Enter your file info here)' }) });
    $self->add_to_file_out({ content => $self->_info() });
    $self->add_to_file_out({ content => $self->_sub_command({ command => 'copy', info => '2007 MailerMailer LLC' }) });
    $self->add_to_file_out({ content => $self->_info({ info => '$Id$' }) });
    $self->add_to_file_out({ content => "\n" });
  }

  return ();
}

## @method protected void _insert_document_data()
#Insert method and sub tag data into new updated_file_data
#The methods inside the 'if' will increment the line_index and return it.
sub _insert_document_data() {
  my ($self, $params) = @_;

  #Loop through every line of the file and parse/analyze it.
  while ($self->current_line()) {

    #Does this line contain the start of a valid package/class?
    if ($self->current_line() =~ /^\s*package\s+(\S+);/) {

      #Update the current package name
      $self->file_current_class($1);

      #Insert class/package data before 'package <package_name> ...'
      $self->_insert_class_data({ class_name => $self->file_current_class });

      $self->add_to_file_out({ content => $self->current_line() });

      $self->next_line();
    }

    #Does this line contain a valid method.
    elsif ($self->current_line() =~ /^\s*sub\s+(\w+)/) {

      #Store current line index. we will need it later to copy lines to updated_file_content
      my $initial_line_index = $self->file_index;

      #Get the method data object or create a new one.
      my $class_data = $self->get_current_class();
      my $method_data = $class_data->get_method({ method_name => $1 });

      #Find method information (such as params, return info)

      #This method will increment $self->file_index so we will need it after the method is finished.
      $self->_determine_method_attributes({ method_data => $method_data });

      #Insert method/sub data before 'sub <sub_name> ...'
      $self->_insert_method_data({ method_data => $method_data });

      #Because the tag/comments occur on top of the method, we had to hold off until after that stuff was
      #taken care of. Now we can copy over the method, itself.
      #We subtract one off file_index because it is pointing to the line after the method, which
      #this loop will take care of on the next iteration.
      $self->add_range_to_file_out({ start_index => $initial_line_index, end_index => $self->file_index - 1 });
    }

    #Nothing special about the line, just copy it over
    else {
      $self->add_to_file_out({ content => $self->current_line() });
      $self->next_line();
    }

  }

  return ();
}

## @method protected void _insert_class_data($class_name})
# Insert \@class template info above the "package <package_name>"
# Two lines:
#	## @class
#	# (Enter your class info here)
# @param class_name  (Enter explanation for param here)
sub _insert_class_data() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No class_name specified' })
    unless defined($$params{class_name});

  $self->add_to_file_out({ content => $self->_command({ command => 'class', info => $$params{class_name} }) });

  my $info_lines = $self->get_class($params)->class_info();

  #If we saved some info lines from before...add them in.
  if (scalar @{$info_lines} > 0) {
    $self->_insert_info_lines({ info_lines => $info_lines });
  }
  else {

    #We have no lines to add so just generate an info line
    $self->add_to_file_out({ content => $self->_info({ info => '(Enter ' . $$params{class_name} . ' info here)' }) });
  }

  return ();
}

## @method protected object _insert_method_data($method_data)
# Insert method or cmethod template info above the "sub <sub_name> ..."
# @param method_data  (Enter explanation for param here)
sub _insert_method_data() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No method_data specified' })
    unless defined($$params{method_data});

  my $method_data = $$params{method_data};

  #Combine the method info
  $self->add_to_file_out({ content => $self->_command({ command => $method_data->method_type, info => $method_data->method_description() }) });

  if (scalar @{ $method_data->method_info } > 0) {
    $self->_insert_info_lines({ info_lines => $method_data->method_info });
  }
  else {

    #We have no lines to add so just generate an info line
    $self->add_to_file_out({ content => $self->_info({ info => '(Enter ' . $method_data->method_name . ' info here)' }) });
  }

  foreach my $param_name (keys %{ $method_data->method_params() }) {

    #Get param info for this param name. It will return undef if one does not exist.
    my $param_info = $method_data->get_param_info({ param_name => $param_name });

    #Use the param info if it exists or generate a generic info string if it does not
    $param_info = ($param_info ne undef) ? $param_info : '(Enter explanation for param here)';

    $self->add_to_file_out({ content => $self->_sub_command({ command => 'param', info => "$param_name  $param_info" }) });
  }

  if ($method_data->method_return_type ne "void") {
    my $return_info = ($method_data->method_return_info ne undef and $method_data->method_return_info ne '') 
    ? $method_data->method_return_info() : '(Enter explanation for return value here)';

    $self->add_to_file_out({ content => $self->_sub_command({ command => 'return', info => $return_info }) });
  }

  return ();
}

## @method protected void _insert_info_lines($info_lines)
# (Enter _insert_info_lines info here)
sub _insert_info_lines() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No info_lines specified' })
    unless defined($$params{info_lines});

  foreach my $info_line (@{ $$params{info_lines} }) {
    $self->add_to_file_out({ content => $self->_info({ info => $info_line }) });
  }

  return ();
}

## @method protected object _determine_method_attributes($method_data)
# Add the new tag lines to the updated_file_content
# @param method_data  (Enter explanation for param here)
sub _determine_method_attributes() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No method_data specified' })
    unless defined($$params{method_data});

  my $method_data = $$params{method_data};

  #We always need to go into the while loop once
  my $initial_loop = 1;

  #For every { we will increment the bracket count by 1. For every } we will decrement the bracket count by 1.
  #Once the bracker count reaches zero, then we have found the end of the method.
  #Start by incrementing here if necessary because one { could be on the same line as the method declaration: "sub my_name() {"
  #But we only want to do that if one is there.
  if ($self->current_line() =~ /\{/) {
    $method_data->increment_brackets_count();
  }

  #Go to the next line and start pulling information from the method
  $self->next_line;

  #Loop through the entire line (which is a string) and look for certain properties.
  while (($self->current_line() and ($method_data->method_brackets_count != 0)) or $initial_loop) {
    $initial_loop = undef;

    #The character index for this line's string
    my $line             = $self->current_line();
    my $char_index       = 0;
    my $no_comment_found = 1;                       #True as long as we do not find a comment

    while ($char_index < length($line) and $no_comment_found) {

      #If this character is a comment then the rest of the lines should not be analyzed.
      if (substr($line, $char_index, CHARACTER_SIZE) eq COMMENT) {
        $no_comment_found = 0;
      }

      #Is this character a {. If so then increment the bracket counter
      elsif (substr($line, $char_index, CHARACTER_SIZE) eq "{") {
        $method_data->increment_brackets_count();
        $char_index++;
      }

      #If this character is a } then decrement the bracket counter
      elsif (substr($line, $char_index, CHARACTER_SIZE) eq "}") {
        $method_data->decrement_brackets_count();
        $char_index++;
      }

      #Do the next 9 characters show '$$params{'. If so, then we have found a param (unless a compile problem exists).
      #There is one case where we do not want to count $$params{<something>} as a parameter
      #-Lets say the we assign a value to a param key, such as $$params{something} = 4;
      #-This param was not passed in, so we do not want to count it
      #-However, if the param was passed in and it is reassigned (as above), it will still get picked up as a param
      #because it will appear at least twice.
      #-The regex takes care of this.
      elsif (substr($line, $char_index, PARAM_SIZE) eq '$$params{' and $line !~ /\$\$params\{\s*\S+\s*}\s*=/) {
        my $param_name;
        my $rest_of_line = substr($line, $char_index + PARAM_SIZE, length($line) - $char_index + PARAM_SIZE);

        if ($rest_of_line =~ /^\s*(\w+)/) {
          $param_name = $1;
          $method_data->add_param({ param_name => $param_name });
          $char_index += (PARAM_SIZE + length($param_name) + 1);    #The +1 is for the '}'
        }
        else {
          throw RWDE::DataBadException({ info => 'Malformed param File will probably not compile. On line ' . $self->file_index });
        }
      }
      elsif (substr($line, $char_index, RETURN_SIZE) eq 'return') {
        my $rest_of_line = substr($line, $char_index + RETURN_SIZE, length($line) - $char_index + RETURN_SIZE);

        #If not "return;" and not "return();" then it is an object. Otherwise leave it at the default void.
        if ($rest_of_line !~ /^\s*\(?\s*\)?;/){
          $method_data->method_return_type('object');
        }

        $char_index += RETURN_SIZE;
      }
      else {
        $char_index++;
      }
    }

    $self->next_line();
  }

  return ();
}

## @method protected object _command($command)
# This returns a one-line command string.
# Example:	command param is 'file', info param is "info"
#					will return '## @file info'
# @param command  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub _command() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'Command not specified' })
    unless defined($$params{command});

  #Use two comment characters for the major command.
  $$params{prefix} = COMMENT . COMMENT;

  return $self->_line($params);
}

## @method protected object _sub_command($command)
#This returns a one-line sub command string.
#Example:	command param is 'file', info param is 'info"
#					will return '# @file info'
# @param command  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub _sub_command() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'Command not specified' })
    unless defined($$params{command});

  $$params{prefix} = COMMENT;

  return $self->_line($params);
}

## @method protected object _info($command)
# This returns a one-line info string.
# Example:	info param is 'file'
#					will return '# file'
# Note that commands are not allowed in info strings. Please see _command and _sub_command for that
# @param command  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub _info() {
  my ($self, $params) = @_;

  #info does not have a command. So passing in a command is illegal.
  throw RWDE::DataMissingException({ info => 'Command specified' })
    unless not defined($$params{command});

  $$params{prefix} = COMMENT;

  return $self->_line($params);
}

## @method protected object _line($command, $info, $prefix)
# This returns a one-line sub command string.
# Example:	info param is 'file'
#					will return '# file'
# Note that commands are not allowed in info strings. Please see _command and _sub_command for that
# @param info  (Enter explanation for param here)
# @param command  (Enter explanation for param here)
# @param prefix  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub _line() {
  my ($self, $params) = @_;

  throw RWDE::DataMissingException({ info => 'No tag prefix specified' })
    unless defined($$params{prefix});

  my $tag = '';    #We just want an empty line for some reason.;

  if (defined($$params{info}) and defined($$params{command})) {
    $tag = COMMAND_PREFIX . $$params{command} . ' ' . $$params{info};
  }
  elsif (defined($$params{command})) {
    $tag = COMMAND_PREFIX . $$params{command};
  }
  elsif (defined($$params{info})) {
    $tag = $$params{info};
  }

  return $$params{prefix} . ' ' . $tag . "\n";
}

1;
