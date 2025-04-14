############################################################
#
# OpenGL::Shader::Objects - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

### SEE DOCS IN Common.pm

package OpenGL::Shader::Objects;

use strict;
use warnings;
use Carp;

our $VERSION = '1.02';

use OpenGL::Shader::Common;
our @ISA = qw(OpenGL::Shader::Common);

use OpenGL(':all');

=head1 NAME

OpenGL::Shader::Objects - plug-in module for use with OpenGL::Shader

=head1 SYNOPSIS

  # See docs in OpenGL/Shader/Common.pm

=head1 DESCRIPTION

This module provides a base class for high-level OpenGL shaders.

This subclasses of the OpenGL::Shader::Common module.

=head1 AUTHOR

Bob "grafman" Free - grafman@graphcomp.com.
Copyright 2007 Graphcomp - ALL RIGHTS RESERVED

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Shader constructor
sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my($type) = @_;
  my $self = OpenGL::Shader::Common->new($type);
  return undef if (!$self);
  bless($self,$class);
  # Check for required OpenGL extensions
  return undef if (OpenGL::glpCheckExtension('GL_ARB_shader_objects'));
  return undef if (OpenGL::glpCheckExtension('GL_ARB_fragment_shader'));
  return undef if (OpenGL::glpCheckExtension('GL_ARB_vertex_shader'));
  $self->{version} = '';
  $self->{description} = '';
  $self->{fragment_const} = '';
  $self->{vertex_const} = '';
  return $self;
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
    $self->{fragment_id} = glCreateShaderObjectARB($self->{fragment_const});
    return undef if !$self->{fragment_id};
    my $stat = _compile_shader($self->{fragment_id}, $fragment, 'Fragment');
    return $stat if $stat;
  }
  # Load vertex code
  if ($vertex) {
    $self->{vertex_id} = glCreateShaderObjectARB($self->{vertex_const});
    return undef if !$self->{vertex_id};
    my $stat = _compile_shader($self->{vertex_id}, $vertex, 'Vertex');
    return $stat if $stat;
  }
  # Link shaders
  my $sp = glCreateProgramObjectARB();
  glAttachObjectARB($sp, $self->{fragment_id}) if ($fragment);
  glAttachObjectARB($sp, $self->{vertex_id}) if ($vertex);
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

1;
