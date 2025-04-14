############################################################
#
# OpenGL::Shader::GLSL - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Shader::GLSL;

use strict;
use warnings;
use Carp;

our $VERSION = '1.02';

our $SHADER_VER;
our $DESCRIPTION = qq
{OpenGL Shader Language};

use OpenGL::Shader::Objects;
our @ISA = qw(OpenGL::Shader::Objects);

use OpenGL(':all');

=head1 NAME

OpenGL::Shader::GLSL - plug-in module for use with OpenGL::Shader

=head1 SYNOPSIS

  ##########
  # Instantiate a shader
  use OpenGL::Shader;
  my $shdr = OpenGL::Shader->new('GLSL');
  # See docs in OpenGL/Shader/Common.pm

=head1 DESCRIPTION

This is a plug-in module for use with the OpenGL::Shader.
While it may be called directly, it will more often be called
by the OpenGL::Shader abstraction module.

This is a subclass of the OpenGL::Shader::Objects module.

=head1 AUTHOR

Bob "grafman" Free - grafman@graphcomp.com.
Copyright 2007 Graphcomp - ALL RIGHTS RESERVED

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Get Version
sub TypeVersion {
  if (!defined($SHADER_VER)) {
    return undef if (OpenGL::glpCheckExtension('GL_ARB_shading_language_100'));
    # Get GL_SHADING_LANGUAGE_VERSION_ARB
    my $ver = glGetString(0x8B8C);
    $ver =~ m|([\d\.]+)|;
    $SHADER_VER = $1 || '0';
  }
  return $SHADER_VER;
}

# Get Description
sub TypeDescription {
  $DESCRIPTION;
}

# Shader constructor
sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  # Check for additional required OpenGL extensions
  my $ver = TypeVersion();
  return undef if (!$ver);
  my $self = OpenGL::Shader::Objects->new('GLSL');
  return undef if (!$self);
  bless($self,$class);
  $self->{version} = $ver;
  $self->{description} = $DESCRIPTION;
  $self->{fragment_const} = GL_FRAGMENT_SHADER;
  $self->{vertex_const} = GL_VERTEX_SHADER;
  return $self;
}

1;
