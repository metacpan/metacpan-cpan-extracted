############################################################
#
# OpenGL::Shader::ARB - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package # hide from PAUSE
  OpenGL::Shader::ARB;

use strict;
use warnings;
use Carp;
use OpenGL(':all');

our $VERSION = '1.02';
our $SHADER_VER = '1.0';
our $DESCRIPTION = qq
{ARBfp1.0 and ARBvp1.0 Assembly};

use OpenGL::Shader::Common;
our @ISA = qw(OpenGL::Shader::Common);

=head1 NAME

OpenGL::Shader::ARB - plug-in module for use with OpenGL::Shader

=head1 SYNOPSIS

  ##########
  # Instantiate a shader
  use OpenGL::Shader;
  my $shdr = OpenGL::Shader->new('ARB');
  # See docs in OpenGL/Shader/Common.pm

=head1 DESCRIPTION

This is a plug-in module for use with L<OpenGL::Shader>.
While it may be called directly, it will more often be called
by the abstraction module.

This is a subclass of the L<OpenGL::Shader::Common> module.

=head1 AUTHOR

Bob "grafman" Free - grafman@graphcomp.com.
Copyright 2007 Graphcomp - ALL RIGHTS RESERVED

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


# Get Version
sub TypeVersion {
  return undef if (OpenGL::glpCheckExtension('GL_ARB_fragment_program'));
  return undef if (OpenGL::glpCheckExtension('GL_ARB_vertex_program'));
  # ARBfp1.0 and ARBvp1.0
  return $SHADER_VER;
}

# Get Description
sub TypeDescription {
  return $DESCRIPTION;
}

sub GetFragmentConstant { GL_FRAGMENT_PROGRAM_ARB }
sub GetVertexConstant { GL_VERTEX_PROGRAM_ARB }

# Shader destructor
# Must be disabled first
sub DESTROY
{
  my($self) = @_;
  glDeleteProgramsARB_p($_) for grep $_, @$self{qw(fragment_id vertex_id)}
}


# Load shader strings
sub Load
{
  my($self,$fragment,$vertex) = @_;
  return "Failed glGenProgramsARB" if grep !$_,
    @$self{qw(fragment_id vertex_id)} = glGenProgramsARB_p(2);
  for ([fragment => $fragment], [vertex => $vertex]) {
    my ($p, $code) = @$_;
    my ($method, $id, $codemem, $varsmem) = ("Get".ucfirst($p)."Constant", $p."_id", $p."_code", substr($p,0,4)."_vars");
    glBindProgramARB($self->$method, $self->{$id});
    glProgramStringARB_p($self->$method, $code);
    @$self{$codemem, $varsmem} = ($code, {});
  }
  return '';
}


# Enable shader
sub Enable
{
  my($self) = @_;

  glEnable($self->GetFragmentConstant);
  glEnable($self->GetVertexConstant);
}


# Disable shader
sub Disable
{
  my($self) = @_;

  glDisable($self->GetFragmentConstant);
  glDisable($self->GetVertexConstant);
}


# Return shader vertex attribute ID
sub MapAttr
{
  my($self,$attr) = @_;
  return undef if ($self->load_attrs());
  return $self->{attrs}->{$attr};
}


# Return shader local variable ID
sub Map
{
  my($self,$var,$prog) = @_;

  $self->load_vars($self->{frag_vars},$self->{fragment_code});
  $self->load_vars($self->{vert_vars},$self->{vertex_code});

  if ($prog == 1)
  {
    return undef if (!$self->{frag_vars});
    return $self->{frag_vars}->{$var};
  }

  if ($prog == 2)
  {
    return undef if (!$self->{vert_vars});
    return $self->{vert_vars}->{$var};
  }

  if ($self->{vert_vars})
  {
    my $id = $self->{vert_vars}->{$var};
    return $id if (defined($id));
  }

  return undef if (!$self->{frag_vars});
  return $self->{frag_vars}->{$var};
}


# Set shader vector
sub SetVector
{
  my($self,$var,@values) = @_;

  my $count = scalar(@values);
  push(@values,(0) x (4-$count)) if ($count < 4);

  my $id = $self->Map($var,2);
  if (defined($id))
  {
    glProgramLocalParameter4fARB($self->GetVertexConstant,$id,@values);
    return '';
  }

  $id = $self->Map($var,1);
  return 'Unable to map $var' if (!defined($id));

  glProgramLocalParameter4fARB($self->GetFragmentConstant,$id,@values);
  return '';
}


# Set shader 4x4 matrix
sub SetMatrix
{
  my($self,$var,$oga) = @_;
  return 'No oga supplied' if (!$oga);

  my $id = $self->Map($var,2);
  if (defined($id))
  {
    $self->set_matrix($self->GetVertexConstant,$id,$oga);
    return '';
  }

  $id = $self->Map($var,1);
  return 'Unable to map $var' if (!defined($id));

  $self->set_matrix($self->GetFragmentConstant,$id,$oga);
  return '';
}

sub set_matrix
{
  my($self,$const,$id,$oga) = @_;
  for (my $i=0; $i<4; $i++)
  {
    glProgramLocalParameter4fvARB_c($const,$id+$i,$oga->offset($i*4));
  }
}


# Parse attribute names
sub load_attrs
{
  my($self) = @_;
  return '' if ($self->{attrs});
  return 'No vertex program' if (!$self->{vertex_code});

  my @lines = split('[\r\n]+',$self->{vertex_code});
  foreach my $line (@lines)
  {
    next if ($line !~ m|ATTRIB\s*(\w+)\s*\=\s*vertex\.([^;]+)|);
    my($var,$map) = ($1,$2);

    if ($map =~ m|attrib\[(\d+)\]|)
    {
      $self->{attrs}->{$var} = $1;
    }
    elsif ($map eq 'position')
    {
      $self->{attrs}->{$var} = 0;
    }
    elsif ($map =~ m|weight|)
    {
      $self->{attrs}->{$var} = 1;
    }
    elsif ($map eq 'normal')
    {
      $self->{attrs}->{$var} = 2;
    }
    elsif ($map eq 'color.secondary')
    {
      $self->{attrs}->{$var} = 4;
    }
    elsif ($map =~ m|color|)
    {
      $self->{attrs}->{$var} = 3;
    }
    elsif ($map =~ m|fogcoord|)
    {
      $self->{attrs}->{$var} = 5;
    }
    elsif ($map eq 'texcoord')
    {
      $self->{attrs}->{$var} = 8;
    }
    elsif ($map =~ m|texcoord\[(\d+)\]|)
    {
      $self->{attrs}->{$var} = $1;
    }
  }
}

# Parse variable names
sub load_vars
{
  my($self,$href,$code) = @_;
  return '' if (scalar(%$href));
  return 'No program' if (!$code);

  my @lines = split('[\r\n]+',$code);
  foreach my $line (@lines)
  {
    next if ($line !~ m|PARAM\s*([^\[\s]+)[\[\d\]\s]*\=[\{\s]*program\.local\[([0-9]+)|);
    my($var,$index) = ($1,$2);
    $href->{$var} = $index;
  }
}

1;
