############################################################
#
# OpenGL::Shader::ARB - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Shader::ARB;

require Exporter;

use Carp;

use vars qw($VERSION $SHADER_VER $DESCRIPTION @ISA);
$VERSION = '1.01';

$SHADER_VER = '1.0';

$DESCRIPTION = qq
{ARBfp1.0 and ARBvp1.0 Assembly};

use OpenGL::Shader::Common;
@ISA = qw(Exporter OpenGL::Shader::Common);

use OpenGL(':all');



=head1 NAME

  OpenGL::Shader::ARB - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This is a plug-in module for use with the OpenGL::Shader.
  While it may be called directly, it will more often be called
  by the OpenGL::Shader abstraction module.

  This is a subclass of the OpenGL::Shader::Common module.


=head1 SYNOPSIS

  ##########
  # Instantiate a shader

  use OpenGL::Shader;
  my $shdr = new OpenGL::Shader('ARB');

  # See docs in OpenGL/Shader/Common.pm

=cut


# Get Version
sub TypeVersion
{
  return undef if (OpenGL::glpCheckExtension('GL_ARB_fragment_program'));
  return undef if (OpenGL::glpCheckExtension('GL_ARB_vertex_program'));

  # ARBfp1.0 and ARBvp1.0
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

  # Check for required OpenGL extensions
  my $ver = TypeVersion();
  return undef if (!$ver);

  my $self = new OpenGL::Shader::Common(@_);
  return undef if (!$self);
  bless($self,$class);

  $self->{type} = 'ARB';
  $self->{version} = $ver;
  $self->{description} = TypeDescription();

  $self->{fragment_const} = GL_FRAGMENT_PROGRAM_ARB;
  $self->{vertex_const} = GL_VERTEX_PROGRAM_ARB;

  ($self->{fragment_id},$self->{vertex_id}) = glGenProgramsARB_p(2);
  return undef if (!$self->{fragment_id} || !$self->{vertex_id});

  return $self;
}


# Shader destructor
# Must be disabled first
sub DESTROY
{
  my($self) = @_;
  glDeleteProgramsARB_p($self->{fragment_id}) if ($self->{fragment_id});
  glDeleteProgramsARB_p($self->{vertex_id}) if ($self->{vertex_id});
}


# Load shader strings
sub Load
{
  my($self,$fragment,$vertex) = @_;

  glBindProgramARB($self->{fragment_const}, $self->{fragment_id});
  glProgramStringARB_p($self->{fragment_const}, $fragment);
  $self->{fragment_code} = $fragment;
  $self->{frag_vars} = {};

  glBindProgramARB($self->{vertex_const}, $self->{vertex_id});
  glProgramStringARB_p($self->{vertex_const}, $vertex);
  $self->{vertex_code} = $vertex;
  $self->{vert_vars} = {};

  return '';
}


# Enable shader
sub Enable
{
  my($self) = @_;

  glEnable($self->{fragment_const});
  glEnable($self->{vertex_const});
}


# Disable shader
sub Disable
{
  my($self) = @_;

  glDisable($self->{fragment_const});
  glDisable($self->{vertex_const});
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
    glProgramLocalParameter4fARB($self->{vertex_const},$id,@values);
    return '';
  }

  $id = $self->Map($var,1);
  return 'Unable to map $var' if (!defined($id));

  glProgramLocalParameter4fARB($self->{fragment_const},$id,@values);
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
    $self->set_matrix($self->{vertex_const},$id,$oga);
    return '';
  }

  $id = $self->Map($var,1);
  return 'Unable to map $var' if (!defined($id));

  $self->set_matrix($self->{fragment_const},$id,$oga);
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
__END__

