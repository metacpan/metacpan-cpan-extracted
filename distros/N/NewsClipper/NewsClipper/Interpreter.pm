# -*- mode: Perl; -*-

# This package implements the interpreter engine that executes a series of
# News Clipper commands.

package NewsClipper::Interpreter;

use strict;
use Exporter;
use NewsClipper::Types qw(ValidateTypeSignature GetTypeSignature
                          ConvertTypeToEnglish TypesMatch);

use vars qw( $VERSION @ISA @EXPORT_OK );

@ISA = qw( Exporter );

@EXPORT_OK = qw(RunHandler);

$VERSION = 0.33;

use NewsClipper::Globals;

# ------------------------------------------------------------------------------

# @update_times stores the update times for a handler before the handler's Get
# function is called. The Get function will then call a function in
# AcquisitionFunctions::GetURL later, which will access this value.

my @update_times;

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

  return $self;
}

# ------------------------------------------------------------------------------

# Executes a set of News Clipper commands.

sub Execute
{
  my $self = shift;
  my @commands = @_;

  # Fill in any defaults
  @commands = _GetDefaultCommands(@commands);

  dprint "Executing ",$#commands+1," commands.";

  return unless $#commands != -1;

  my $data = undef;

  return unless _CommandsValid(@commands);

  # For each command...
  foreach my $command (@commands)
  {
    my ($handlerType,$attributeList) = @$command;

    my $handlerName = $attributeList->{name};
    delete $attributeList->{name};

    $data = RunHandler($handlerName,$handlerType,$data,$attributeList);
  }

}

# ------------------------------------------------------------------------------

sub _GetDefaultCommands
{
  my @commands = @_;

  # We only try to fill in defaults if the user only specified an input
  # command.
  return @commands if $#commands > 0 || $commands[0][0] ne 'input';

  my ($type,$attributeList) = @{$commands[0]};

  my $handlerName = $attributeList->{name};

  # Ask the HandlerFactory to create a handler for us, based on the name.
  my $handler = $NewsClipper::Globals::handlerFactory->Create($handlerName);

  if (defined $handler)
  {
    # Set up default values
    $attributeList = $handler->ProcessAttributes($attributeList,'input');
    unless (defined $attributeList)
    {
      $errors{'interpreter'} .= dequote <<"      EOF";
        The handler "$handlerName" was loaded, but the attributes were not
        correctly specified.
      EOF

      return ();
    }

    my $defaultHandlerText = $handler->GetDefaultHandlers($attributeList);

    # Save the default handler info for later, in case there is an error and
    # we need to output diagnostic info.
    $errors{'expanded commands'} = $defaultHandlerText;

    require NewsClipper::TagParser;
    my $tagParser = new NewsClipper::TagParser;

    my @extraCommands = $tagParser->parse($defaultHandlerText);

    if ($#extraCommands != -1)
    {
      dprint "Adding " . ($#extraCommands+1) .
        " default filter and output handlers:\n$defaultHandlerText";

      push @commands, @extraCommands;
    }
    else
    {
      $errors{'interpreter'} .= dequote <<"      EOF";
        The handler "$handlerName" was loaded, but the default handlers could
        not be parsed.
      EOF
      return ();
    }
  }
  else
  {
    $errors{'interpreter'} .= dequote <<"    EOF";
      The handler "$handlerName" could not be loaded, so this series of News
      Clipper commands could not be executed.
    EOF
    return ();
  }

  return @commands;
}

# ------------------------------------------------------------------------------

sub _CommandsValid(@)
{
  my @commands = @_;

  if ($commands[0][0] ne 'input' || $commands[-1][0] ne 'output')
  {
    $errors{'interpreter'} .= dequote<<'    EOF';
      Your sequence of News Clipper commands should begin with an "input"
      command and end with an "output" command.
    EOF
    return 0;
  }

  # Count the number of "input" commands
  {
    my @count = grep { $_->[0] eq 'input' } @commands;

    if ($#count != 0)
    {
      $errors{'interpreter'} .= dequote<<'      EOF';
        Your sequence of News Clipper commands should have only one "input"
        command.
      EOF
      return 0;
    }
  }

  # Count the number of "output" commands
  {
    my @count = grep { $_->[0] eq 'output' } @commands;

    if ($#count != 0)
    {
      $errors{'interpreter'} .= dequote<<'      EOF';
        Your sequence of News Clipper commands should have only one "output"
        command.
      EOF
      return 0;
    }
  }

  return 1;
}

# ------------------------------------------------------------------------------

# Executes a single News Clipper command, invoking _GetData, _FilterData, or
# _OutputData depending on the type of command.

sub RunHandler
{
  my $handlerName = shift;
  my $handlerType = shift;
  my $data = shift;
  my $attributeList = shift;

  die qq(Unknown handler type "$handlerType". It should be one of "input",\n) .
      qq("filter", or "output".\n")
    unless $handlerType =~ /^(input|filter|output)$/;

  dprint "Executing handler $handlerName\n";

  # Ask the HandlerFactory to create a handler for us, based on the name.
  my $handler = $NewsClipper::Globals::handlerFactory->Create($handlerName);

  # Now have the handler handle it!
  if (defined $handler)
  {
    if ($handlerType eq 'input')
    {
      $data = _GetData($handlerName,$handler,$attributeList);

      # If the get function failed, or everything was filtered out, quit
      unless (defined $data)
      {
        dprint "Aborting execution for this News Clipper tag.";
        $errors{'interpreter'} .=
          "Get function for handler $handlerName failed.\n";
        return undef;
      }
    }
    elsif (defined $data && $handlerType eq 'filter')
    {
      # Typically this happens if a handler calls RunHandler with invalid data
      return undef unless _DataOK($data,$handlerName,'input');

      $data = _FilterData($handlerName,$handler,$attributeList,$data);

      # If the get function failed, or everything was filtered out, quit
      unless (defined $data)
      {
        dprint "Aborting execution for this News Clipper tag.";
        $errors{'interpreter'} .=
          "Filter function for handler $handlerName failed.\n";
        return undef;
      }
    }
    elsif (defined $data && $handlerType eq 'output')
    {
      # Typically this happens if a handler calls RunHandler with invalid data
      return undef unless _DataOK($data,$handlerName,'input');

      _OutputData($handlerName,$handler,$attributeList,$data);
      return undef;
    }
  }

  return $data;
}

# ------------------------------------------------------------------------------

# Checks that the internal data of a complex structure is a ref. (Not a ref to
# a ref or a plain scalar.)

sub _DataOK($$$);

sub _DataOK($$$)
{
  my $data = shift;
  my $handlerName = shift;
  my $handlerType = shift;

  unless (defined $data)
  {
    $errors{'interpreter'} .=<<"    EOF";
News Clipper executed the $handlerType handler "$handlerName", but the handler
returned an undefined data element, which is not allowed. Please notify the
handler author of the problem.
    EOF
    return 0;
  }

  unless (ref $data)
  {
    $errors{'interpreter'} .=<<"    EOF";
News Clipper executed the $handlerType handler "$handlerName", but the handler
returned a data element that was not a reference
("$data"), which is not allowed.  Please notify the handler
author of the problem.
    EOF
    return 0;
  }

  if (UNIVERSAL::isa($data,'REF'))
  {
    $errors{'interpreter'} .=<<"    EOF";
News Clipper executed the $handlerType handler $handlerName, but the handler
returned a data element that was a reference to a reference, which is not
allowed. Please notify the handler author of the problem.
    EOF
    return 0;
  }

  if (UNIVERSAL::isa($data,'ARRAY'))
  {
    foreach my $temp (@$data)
    {
      return 0 unless _DataOK($temp,$handlerName,$handlerType);
    }
  }

  if (UNIVERSAL::isa($data,'HASH'))
  {
    foreach my $temp (keys %$data)
    {
      return 0 unless _DataOK($$data{$temp},$handlerName,$handlerType);
    }
  }

  return 1;
}

# ------------------------------------------------------------------------------

# Checks that the type of the data matches the expected type of the filter or
# output handler. This used to be strictly "name equivalence" (types match if
# names match, but now its "structural equivalence" (types match if structure
# matches).

sub _TypesMatch($$$$$)
{
  my $data = shift;
  my $attributeList = shift;
  my $handler = shift;
  my $handlerName = shift;
  my $type = shift;

  my $expectedTypes;

  # Set up default values
  $attributeList = $handler->ProcessAttributes($attributeList,$type);
  return undef unless defined $attributeList;
  
  $expectedTypes = $handler->FilterType($attributeList,$data)
    if $type eq 'filter';
  $expectedTypes = $handler->OutputType($attributeList,$data) 
    if $type eq 'output';

  if ($expectedTypes eq 'NOT SUPPORTED')
  {
    $errors{'interpreter'} .= dequote<<"    EOF";
      "$handlerName" can not be used as a $type handler.  This
      normally means that your sequence of News Clipper commands is broken.
      Try changing "$handlerName" to a more suitable handler.
    EOF
    return 0;
  }

  dprint "Comparing data type \"",GetTypeSignature($data),"\" to expected ",
         "types \"$expectedTypes\".";

  if (TypesMatch($data,$expectedTypes))
  {
    dprint "\"",GetTypeSignature($data),"\" is a subtype of ",
      "\"$expectedTypes\".";
    return 1;
  }
  else
  {
    my $translatedExpected = ConvertTypeToEnglish($expectedTypes);
    my $translatedActual = ConvertTypeToEnglish(GetTypeSignature($data));
    $errors{'interpreter'} .= dequote<<"    EOF";
      The data expected by "$handlerName" is supposed to be of type
      "$translatedExpected", but it's actually of type "$translatedActual".
      This normally means that your sequence of News Clipper commands is
      broken. Try changing "$handlerName" to a more suitable handler, or use a
      filter to convert the data from "$translatedActual" to
      "$translatedExpected".
    EOF
    return 0;
  }
}

# ------------------------------------------------------------------------------

# Calls the Get function of the handler and checks the result for errors.

sub _GetData($$$)
{
  my $handlerName = shift;
  my $handler = shift;
  my $attributeList = shift;

  dprint "Calling Get function for handler $handlerName.";

  # Set up default values
  $attributeList = $handler->ProcessAttributes($attributeList,'input');
  return undef unless defined $attributeList;

  # Get the update times for the handler, and store it in the global variable
  # @update_times. This value is accessed by AcquisitionFunctions::GetURL
  # later.
  @NewsClipper::Interpreter::update_times =
    _GetUpdateTimes($handlerName,$handler,$attributeList);

  # Get the data
  my $data = $handler->Get($attributeList);
  return undef unless defined $data;

  return undef unless _DataOK($data,$handlerName,'input');

  dprint $#{$data}+1," lines acquired" if ref($data) eq "ARRAY";
  dprint length $$data," characters acquired." if ref($data) eq "SCALAR";

  return $data;
}

# ------------------------------------------------------------------------------

# This function calls GetUpdateTimes on the handler in order to get the update
# times, and checks that the times are reasonable. Returns undef if there is a
# problem, or a list of update times.

sub _GetUpdateTimes
{
  my $handlerName = shift;
  my $handler = shift;
  my $attributeList = shift;

  my $updateTimesRef = $handler->GetUpdateTimes($attributeList);

  my @updateTimes = @$updateTimesRef;

  if (DEBUG)
  {
    local $" = ',';
    dprint "Update times are: @updateTimes";
  }

  # Make sure all the time specifications look okay.
  for my $timeSpec (@updateTimes)
  {
    unless ($timeSpec =~ /^[a-z]*\D*[\d ,]*\s*[a-z]{0,5}$/i)
    {
      $errors{'interpreter'} .= dequote <<"      EOF";
There is a problem with your update times for handler $handlerName --
"$timeSpec" is an invalid time specification. Please contact the handler
author to have the problem fixed.
      EOF
      return undef;
    }
  }

  return @updateTimes;
}

# ------------------------------------------------------------------------------

# Calls the Filter function of the handler and checks the result for errors.

sub _FilterData($$$$)
{
  my $handlerName = shift;
  my $handler = shift;
  my $attributeList = shift;
  my $data = shift;

  dprint "Calling Filter function for handler $handlerName.";

  # Set up default values
  $attributeList = $handler->ProcessAttributes($attributeList,'filter');
  return undef unless defined $attributeList;

  return undef unless _TypesMatch($data,$attributeList,$handler,
    $handlerName,'filter');

  # Filter the data
  $data = $handler->Filter($attributeList,$data);
  return undef unless defined $data;

  return undef unless _DataOK($data,$handlerName,'filter');

  dprint $#{$data}+1," lines filtered." if ref($data) eq "ARRAY";
  dprint length $$data," characters filtered." if ref($data) eq "SCALAR";

  return $data;
}

# ------------------------------------------------------------------------------

# Calls the Output function of the handler.

sub _OutputData($$$$)
{
  my $handlerName = shift;
  my $handler = shift;
  my $attributeList = shift;
  my $data = shift;

  dprint "Calling Output function for handler $handlerName.";

  # Set up default values
  $attributeList = $handler->ProcessAttributes($attributeList,'output');
  return undef unless defined $attributeList;

  my $expectedTypes = $handler->OutputType($attributeList,$data);

  return undef unless _TypesMatch($data,$attributeList,$handler,
                 $handlerName,'output');

  $handler->Output($attributeList,$data);
}

1;
