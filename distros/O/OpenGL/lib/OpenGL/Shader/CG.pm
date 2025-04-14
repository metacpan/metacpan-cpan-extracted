############################################################
#
# OpenGL::Shader::CG - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Shader::CG;

use Carp;

use strict;
use warnings;
our $VERSION = '1.02';

our $SHADER_VER = '1.0';
our $DESCRIPTION = qq
{nVidia's Cg Shader Language};

use OpenGL::Shader::Objects;
our @ISA = qw(OpenGL::Shader::Objects);

use OpenGL(':all');

=head1 NAME

OpenGL::Shader::CG - plug-in module for use with OpenGL::Shader

=head1 SYNOPSIS

  ##########
  # Instantiate a shader
  use OpenGL::Shader;
  my $shdr = OpenGL::Shader->new('CG');
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
sub TypeVersion
{
  if (!defined($SHADER_VER))
  {
    return undef if (OpenGL::glpCheckExtension('GL_EXT_Cg_shader'));

    # Get GL_SHADING_LANGUAGE_VERSION_ARB
    my $ver = glGetString(0x8B8C);
    $ver =~ m|Cg ([\d\.]+)|i;

    # Some drivers do not report Cg version
    $SHADER_VER = $1 || '1.00';
  }
  return $SHADER_VER;
}


# Get Description
sub TypeDescription
{
  return $DESCRIPTION;
}


# Shader constructor
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;

  # Check for additional required OpenGL extensions
  my $ver = TypeVersion();
  return undef if (!$ver);

  my $self = OpenGL::Shader::Objects->new('CG');
  return undef if (!$self);
  bless($self,$class);

  $self->{version} = $ver;
  $self->{description} = $DESCRIPTION;

  $self->{fragment_const} = GL_CG_FRAGMENT_SHADER_EXT;
  $self->{vertex_const} = GL_CG_VERTEX_SHADER_EXT;

  return $self;
}

1;
