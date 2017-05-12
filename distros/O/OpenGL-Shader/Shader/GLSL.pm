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

require Exporter;

use Carp;

use vars qw($VERSION $SHADER_VER $DESCRIPTION @ISA);
$VERSION = '1.01';

$DESCRIPTION = qq
{OpenGL Shader Language};

use OpenGL::Shader::Objects;
@ISA = qw(Exporter OpenGL::Shader::Objects);

use OpenGL(':all');



=head1 NAME

  OpenGL::Shader::GLSL - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This is a plug-in module for use with the OpenGL::Shader.
  While it may be called directly, it will more often be called
  by the OpenGL::Shader abstraction module.

  This is a subclass of the OpenGL::Shader::Objects module.


=head1 SYNOPSIS

  ##########
  # Instantiate a shader

  use OpenGL::Shader;
  my $shdr = new OpenGL::Shader('GLSL');

  # See docs in OpenGL/Shader/Common.pm

=cut


# Get Version
sub TypeVersion
{
  if (!defined($SHADER_VER))
  {
    return undef if (OpenGL::glpCheckExtension('GL_ARB_shading_language_100'));

    # Get GL_SHADING_LANGUAGE_VERSION_ARB
    my $ver = glGetString(0x8B8C);
    $ver =~ m|([\d\.]+)|;
    $SHADER_VER = $1 || '0';
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

  my $self = new OpenGL::Shader::Objects(@_);
  return undef if (!$self);
  bless($self,$class);

  $self->{type} = 'GLSL';
  $self->{version} = $ver;
  $self->{description} = $DESCRIPTION;

  $self->{fragment_const} = GL_FRAGMENT_SHADER;
  $self->{vertex_const} = GL_VERTEX_SHADER;

  return $self;
}


1;
__END__

