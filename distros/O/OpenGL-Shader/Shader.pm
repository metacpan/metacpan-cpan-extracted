############################################################
#
# OpenGL::Shader - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

### SEE DOCS IN Shader.pod

package OpenGL::Shader;

require Exporter;

use strict;
use warnings;
use Carp;

use vars qw($VERSION $SHADER_TYPES @ISA);
$VERSION = '1.01';

@ISA = qw(Exporter);

use OpenGL(':all');


# Return hashref of supported shader types
# Must be able to open a hidden GL context.
sub GetTypes
{
  return ReturnTypes() if (ref($SHADER_TYPES));

  my $dir = __FILE__;
  return if ($dir !~ s|\.pm$||);

  my @types;
  # Grab OpenGL/Shader modules
  if (opendir(DIR,$dir))
  {
    foreach my $type (readdir(DIR))
    {
      next if ($type !~ s|\.pm$||);
      next if ($type eq 'Common');
      next if ($type eq 'Objects');
      push(@types,$type);
    }
    closedir(DIR);
  }
  return if (!@types);

  $SHADER_TYPES = {};
  foreach my $type (@types)
  {
    my $info = HasType($type);
    next if (!$info);
    $SHADER_TYPES->{$type} = $info;
  }

  return ReturnTypes();
}

sub ReturnTypes
{
  return wantarray ? values(%$SHADER_TYPES) : $SHADER_TYPES;
}


# Get shader's version
# Must be able to open a hidden GL context.
sub GetTypeVersion
{
  my($type) = @_;
  return if (!$type);

  my $info = HasType($type);
  return if (!$info);
  return $info->{version};
}


# Check for engine availability; returns module version
sub HasType
{
  my($type,$min_ver,$max_ver) = @_;
  return if (!$type);

  my $module = GetTypeModule($type);

  my($version,$desc);
  my $exec = qq
  {
    use $module;
    \$version = $module\::TypeVersion();
    \$desc = $module\::TypeDescription();
  };
  eval($exec);

  return if (!$version);
  return if ($min_ver && $version lt $min_ver);
  return if ($max_ver && $version gt $max_ver);

  my $info = {};
  $info->{name} = $type;
  $info->{module} = $module;
  $info->{version} = $version;
  $info->{description} = $desc;

  return $info;
}


# Constructor wrapper for shader type
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless($self,$class);

  my @types = @_ ? @_ : ('GLSL','CG','ARB');
  foreach my $type (@types)
  {
    my $obj;
    my $module = GetTypeModule($type);
    my $exec = qq
    {
      use $module;
      \$obj = new $module\();
    };
    eval($exec);

    return $obj if ($obj && !$@);
  }
  return undef;
}


# Get shader module name
sub GetTypeModule
{
  my($type) = @_;
  return __PACKAGE__.'::'.uc($type);
}




1;
__END__

