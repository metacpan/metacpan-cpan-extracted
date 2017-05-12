############################################################
#
# OpenGL::Shader::Common - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Shader::Common;

require Exporter;

use Carp;

use vars qw($VERSION @ISA);
$VERSION = '1.01';

@ISA = qw(Exporter);


=head1 NAME

  OpenGL::Shader::Common - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This module provides a base class for OpenGL shader types.
  Requires the OpenGL module.


=head1 SYNOPSIS

  ##########
  # Instantiate a shader

  use OpenGL::Shader;
  my $shdr = new OpenGL::Shader();


  ##########
  # Methods defined in this module:

  # Get shader type.
  my $type = $shdr->GetType();

  # Get shader version
  my $ver = $shdr->GetVersion();

  # Get shader description
  my $desc = $shdr->GetDescription();

  # Load shader files.
  my $stat = $shdr->LoadFiles($fragment_file,$vertex_file);

  # Get shader GL constants.
  my $fragment_const = $shdr->GetFragmentConstant();
  my $vertex_const = $shdr->GetVertexConstant();

  # Get objects.
  my $fragment_shader = $shdr->GetFragmentShader();
  my $vertex_shader = $shdr->GetVertexShader();
  my $program = $shdr->GetProgram();


  ##########
  # Methods defined in subclasses:

  # Load shader text.
  $shdr->Load($fragment,$vertex);

  # Enable shader.
  $shdr->Enable();

  # Set Vertex Attribute
  my $attr_id = $self->MapAttr($attr_name);
  glVertexAttrib4fARB($attr_id,$x,$y,$z,$w);

  # Get Global Variable ID (uniform/env)
  my $var_id = $self->Map($var_name);

  # Set float4 vector variable
  $stat = $self->SetVector($var_name,$x,$y,$z,$w);

  # Set float4x4 matrix via OGA
  $stat = $self->SetMatrix($var_name,$oga);

  # Disable shader.
  $shdr->Disable();

  # Destructor.
  $shdr->DESTROY();

=cut


# Base constructor
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my($type) = @_;
  my $self = {type => uc($type)};
  bless($self,$class);

  return $self;
}


# Get shader type
sub GetType
{
  my($self) = @_;
  return $self->{type};
}


# Get shader version
sub GetVersion
{
  my($self) = @_;
  return $self->{version};
}


# Get shader description
sub GetDescription
{
  my($self) = @_;
  return $self->{description};
}


# Get fragment shader constant
sub GetFragmentConstant
{
  my($self) = @_;
  return $self->{fragment_const};
}


# Get vertex shader constant
sub GetVertexConstant
{
  my($self) = @_;
  return $self->{vertex_const};
}


# Get fragment shader ID
sub GetFragmentShader
{
  my($self) = @_;
  return $self->{fragment_id};
}


# Get vertex shader ID
sub GetVertexShader
{
  my($self) = @_;
  return $self->{vertex_id};
}


# Get shader program object
sub GetProgram
{
  my($self) = @_;
  return $self->{program};
}


# Load shader files
sub LoadFiles
{
  my($self,$fragment_file,$vertex_file) = @_;

  my $fragment = '';
  if ($fragment_file)
  {
    return "Does not exist: $fragment_file" if (!-e $fragment_file);
    $fragment = $self->read_file($fragment_file);
    return "Empty fragment file" if (!$fragment);
  }

  my $vertex = '';
  if ($fragment_file)
  {
    return "Does not exist: $vertex_file" if (!-e $vertex_file);
    $vertex = $self->read_file($vertex_file);
    return "Empty vertex file" if (!$vertex);
  }

  return $self->Load($fragment,$vertex);
}


# Read file
sub read_file
{
  my($self,$file) = @_;

  return undef if (!open(FILE,$file));
  my @data = <FILE>;
  close(FILE);
  return join('',@data);
}


1;
__END__

