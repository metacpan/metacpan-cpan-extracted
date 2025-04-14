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

use strict;
use warnings;
use Carp;
use OpenGL(':all');

our $VERSION = '1.02';
our @ISA = qw(Exporter);
our $SHADER_TYPES;

# Return hashref of supported shader types
# Must be able to open a hidden GL context.
sub GetTypes {
  return ReturnTypes() if (ref($SHADER_TYPES));
  my $dir = __FILE__;
  return if ($dir !~ s|\.pm$||);
  my @types;
  # Grab OpenGL/Shader modules
  if (opendir(DIR,$dir)) {
    foreach my $type (readdir(DIR)) {
      next if ($type !~ s|\.pm$||);
      next if ($type eq 'Common');
      next if ($type eq 'Objects');
      push(@types,$type);
    }
    closedir(DIR);
  }
  return if (!@types);
  $SHADER_TYPES = {};
  foreach my $type (@types) {
    my $info = HasType($type);
    next if (!$info);
    $SHADER_TYPES->{$type} = $info;
  }
  return ReturnTypes();
}

sub ReturnTypes {
  wantarray ? values(%$SHADER_TYPES) : $SHADER_TYPES;
}

# Get shader's version
# Must be able to open a hidden GL context.
sub GetTypeVersion {
  my($type) = @_;
  return if (!$type);
  my $info = HasType($type);
  return if (!$info);
  return $info->{version};
}

# Check for engine availability; returns module version
sub HasType {
  my($type,$min_ver,$max_ver) = @_;
  return if (!$type);
  my $module = GetTypeModule($type);
  (my $file = $module) =~ s{::}{/}g;
  require "$file.pm";
  my $version = $module->can('TypeVersion')->();
  my $desc = $module->can('TypeDescription')->();
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
sub new {
  my $this = shift;
  my @types = @_ ? @_ : ('GLSL','CG','ARB');
  foreach my $type (@types) {
    next if !$type;
    my $module = GetTypeModule($type);
    (my $file = $module) =~ s{::}{/}g;
    require "$file.pm";
    my $obj = $module->new;
    return $obj if $obj;
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
