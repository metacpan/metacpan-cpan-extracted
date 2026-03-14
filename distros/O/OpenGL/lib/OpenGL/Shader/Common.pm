############################################################
#
# OpenGL::Shader::Common - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package # hide from PAUSE
  OpenGL::Shader::Common;

use strict;
use warnings;
use Carp;
use OpenGL(':all');

our $VERSION = '1.02';

=head1 NAME

OpenGL::Shader::Common - base class for use with OpenGL::Shader

=head1 SYNOPSIS

  # Instantiate a shader
  use OpenGL::Shader;
  my $shdr = OpenGL::Shader->new();

=head1 DESCRIPTION

This module provides a base class for OpenGL shader types.
See L<OpenGL::Shader> documentation.

=head1 AUTHOR

Bob "grafman" Free - grafman@graphcomp.com.
Copyright 2007 Graphcomp - ALL RIGHTS RESERVED

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


# Base constructor
sub new {
  # Check for required OpenGL extensions
  return undef if OpenGL::glpCheckExtension('GL_ARB_shader_objects');
  return undef if OpenGL::glpCheckExtension('GL_ARB_fragment_shader');
  return undef if OpenGL::glpCheckExtension('GL_ARB_vertex_shader');
  my $this = shift;
  my $class = ref($this) || $this;
  my $type = (split /::/, $class)[-1];
  my $self = bless {}, $class;
  return undef unless $self->{version} = $self->TypeVersion;
  $self->{type} = uc($type);
  $self->{description} = $self->TypeDescription;
  $self;
}

# Shader destructor
# Must be disabled first
sub DESTROY {
  my($self) = @_;
  if ($self->{program}) {
    glDetachObjectARB($self->{program},$self->{fragment_id}) if ($self->{fragment_id});
    glDetachObjectARB($self->{program},$self->{vertex_id}) if ($self->{vertex_id});
    glDeleteProgramsARB_p($self->{program});
  }
  glDeleteProgramsARB_p($self->{fragment_id}) if ($self->{fragment_id});
  glDeleteProgramsARB_p($self->{vertex_id}) if ($self->{vertex_id});
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

# Load shader strings
sub _compile_shader {
  my ($id, $src, $label) = @_;
  glShaderSourceARB_p($id, $src);
  glCompileShaderARB($id);
  return '' if glGetObjectParameterivARB_p($id, GL_OBJECT_COMPILE_STATUS_ARB) == GL_TRUE;
  my $stat = glGetInfoLogARB_p($id);
  return "$label shader: $stat" if $stat;
  '';
}
sub Load {
  my ($self,$fragment,$vertex) = @_;
  # Load fragment code
  if ($fragment) {
    $self->{fragment_id} = glCreateShaderObjectARB($self->GetFragmentConstant);
    return undef if !$self->{fragment_id};
    my $stat = _compile_shader($self->{fragment_id}, $fragment, 'Fragment');
    return $stat if $stat;
  }
  # Load vertex code
  if ($vertex) {
    $self->{vertex_id} = glCreateShaderObjectARB($self->GetVertexConstant);
    return undef if !$self->{vertex_id};
    my $stat = _compile_shader($self->{vertex_id}, $vertex, 'Vertex');
    return $stat if $stat;
  }
  # Link shaders
  my $sp = glCreateProgramObjectARB();
  glAttachObjectARB($sp, $self->{fragment_id}) if $fragment;
  glAttachObjectARB($sp, $self->{vertex_id}) if $vertex;
  glLinkProgramARB($sp);
  my $linked = glGetObjectParameterivARB_p($sp, GL_OBJECT_LINK_STATUS_ARB);
  if (!$linked) {
    my $stat = glGetInfoLogARB_p($sp);
    return "Link shader: $stat" if ($stat);
    return 'Unable to link shader';
  }
  $self->{program} = $sp;
  return '';
}

# Enable shader
sub Enable {
  my($self) = @_;
  glUseProgramObjectARB($self->{program}) if ($self->{program});
}


# Disable shader
sub Disable {
  my($self) = @_;
  glUseProgramObjectARB(0) if ($self->{program});
}


# Return shader vertex attribute ID
sub MapAttr {
  my($self,$attr) = @_;
  return undef if (!$self->{program});
  my $id = glGetAttribLocationARB_p($self->{program},$attr);
  return undef if ($id < 0);
  return $id;
}

# Return shader uniform variable ID
sub Map {
  my($self,$var) = @_;
  return undef if (!$self->{program});
  my $id = glGetUniformLocationARB_p($self->{program},$var);
  return undef if ($id < 0);
  return $id;
}

# Set shader Uniform integer array
sub SetArray {
  my($self,$var,@values) = @_;
  my $id = $self->Map($var);
  return 'Unable to map $var' if (!defined($id));
  my $count = scalar(@values);
  eval('glUniform'.$count.'iARB($id,@values)');
  return '';
}

# Set shader Uniform float array
sub SetVector {
  my($self,$var,@values) = @_;
  my $id = $self->Map($var);
  return 'Unable to map $var' if (!defined($id));
  my $count = scalar(@values);
  eval('glUniform'.$count.'fARB($id,@values)');
  return '';
}

# Set shader matrix
sub SetMatrix {
  my($self,$var,$oga) = @_;
  my $id = $self->Map($var);
  return 'Unable to map $var' if (!defined($id));
  if ($oga->elements == 16) {
    glUniformMatrix4fvARB_c($id,1,0,$oga->ptr());
  } elsif ($oga->elements == 9) {
    glUniformMatrix3fvARB_c($id,1,0,$oga->ptr());
  } else {
    return 'Only supports 3x3 and 4x4 matrices';
  }
  return '';
}

# Load shader files
sub LoadFiles
{
  my($self,$fragment_file,$vertex_file) = @_;

  my $fragment = '';
  if ($fragment_file) {
    return "Does not exist: $fragment_file" if (!-e $fragment_file);
    $fragment = $self->read_file($fragment_file);
    return "Empty fragment file" if (!$fragment);
  }
  my $vertex = '';
  if ($vertex_file) {
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
