# -*- mode: Perl; -*-
package NewsClipper::Handler;

# This package contains the Handler class, from which all handlers derive.  To
# use it, subclass it and redefine the Get, Filter, and Output methods. 

use strict;
use Carp;
use Exporter;
use File::Cache;

use vars qw( $VERSION @ISA @EXPORT );

@ISA = qw( Exporter );

# We'll import all these APIs so we can pass them down to handlers that derive
# from this class.
use NewsClipper::AcquisitionFunctions;
use NewsClipper::HTMLTools;
use NewsClipper::Globals;
use NewsClipper::Interpreter qw(RunHandler);
use NewsClipper::Types;

# We'll export our own function, as well as all the functions in the HTMLTools
# API, and all the Globals stuff. This will save us from having to do all that
# in the handler.
@EXPORT = ("error","RunHandler",@NewsClipper::HTMLTools::EXPORT,
           @NewsClipper::Globals::EXPORT, @NewsClipper::Types::EXPORT,
           @NewsClipper::AcquisitionFunctions::EXPORT,
           'NewsClipper::Interpreter::RunHandler');

$VERSION = 0.44;

# ------------------------------------------------------------------------------

sub error
{
  my $message = join '',@_;

  # Get the caller's name
  my $caller = (caller(0))[0];
  $caller =~ s/.*://s;

  $message =~ s/\n*$//s;

  $errors{"handler#$caller"} .= "$message\n";

  return 1;
}

# ------------------------------------------------------------------------------

sub new
{
  my $proto = shift;

  # We take the ref if "new" was called on an object, and the class ref
  # otherwise.
  my $class = ref($proto) || $proto;

  # Create an "object"
  my $self = {};

  # Make the object a member of the class
  bless ($self, $class);

  my $handlerType = $class;
  $handlerType =~ s/.*::(\w+?)::.*?$/$1/;
  my $namespace = $class;
  $namespace =~ s/.*:://;

  my $cache_key =
    "$NewsClipper::Globals::home/.NewsClipper/state/$handlerType";

  # Set up the handler's state
  $self->{'state'} = new File::Cache (
        { cache_key => $cache_key,
          namespace => $namespace,
          username => '',
          filemode => 0666,
          auto_remove_stale => 0,
          persistence_mechanism => 'Data::Dumper',
        } );

  return $self;
}

# ------------------------------------------------------------------------------

# This should be overridden by handlers that have default attribute values.

sub ProcessAttributes
{
  my $self = shift;
  my $attributes = shift;
  my $handlerRole = shift;

  return $attributes;
}

# ------------------------------------------------------------------------------

# Overriding this method is optional, but recommended.

sub GetDefaultHandlers
{
  my $self = shift;
  my $attributes = shift;

  # Sometimes we have to know how the input is called in order to choose a
  # handler.
  my $inputAttributes = shift;

  # The format should be a string that looks like a series of News Clipper
  # filter and output commands. The last item should be an output handler
  # description, and the others are filter descriptions.
  #
  # my $returnVal =<<EOF;
  #   <filter name='highlight' words='linux,wine,mitnick'>
  #   <output name = 'string'>
  # EOF

  return '';
}

# ------------------------------------------------------------------------------

# This should be overridden by data acquisition handlers. (Filter and output
# handlers can safely ignore it.)

sub ComputeURL
{
  my $self = shift;
  my $attributes = shift;

  return 'NO URL PROVIDED';
}

# ------------------------------------------------------------------------------

# This should be overridden by data acquisition handlers. (Filter and output
# handlers can safely ignore it.)

sub Get
{
  my $self = shift;
  my $attributes = shift;

  my $type = ref($self);
  croak ("$type does not have the ability to do data acquisition.\n");
}

# ------------------------------------------------------------------------------

# Declares what type of data a filter handler can handle. Subclasses should
# define this function if they are handlers that can be used as filters.

sub FilterType
{
  my $self = shift;
  my $attributes = shift;

  return 'NOT SUPPORTED';
}

# ------------------------------------------------------------------------------

# This function is used to filter out some of the data acquired using Get.
# Currently it does nothing, but subclasses can override this behavior.

sub Filter
{
  my $self = shift;
  my $attributes = shift;
  my $grabbedData = shift;

  # Return a reference to the data.
  return $grabbedData;
}

# ------------------------------------------------------------------------------

# Declares what type of data a output handler can handle. Subclasses should
# define this function if they are handlers that can be used to output data.

sub OutputType
{
  my $self = shift;
  my $attributes = shift;
  my $data = shift;

  return 'NOT SUPPORTED';
}

# ------------------------------------------------------------------------------

# This should be overridden by data acquisition handlers. (Filter and output
# handlers can safely ignore it.)

sub Output
{
  my $self = shift;
  my $attributes = shift;
  my $grabbedData = shift;
}

# ------------------------------------------------------------------------------

# Overriding this method is optional.

sub GetUpdateTimes
{
  my $self = shift;
  my $attributes = shift;

  return ['2,5,8,11,14,17,20,23'];
}

1;
