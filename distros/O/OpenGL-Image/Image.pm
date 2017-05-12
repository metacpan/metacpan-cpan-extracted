############################################################
#
# OpenGL::Image - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

### SEE DOCS IN Image.pod

package OpenGL::Image;

require Exporter;

use strict;
use warnings;
use Carp;

use vars qw($VERSION @ISA);
$VERSION = '1.03';

@ISA = qw(Exporter);


# Return hashref of installed imaging engines
# Use OpenGL/Image/Engines.lst if exists
sub GetEngines
{
  my $dir = __FILE__;
  return if ($dir !~ s|\.pm$||);

  my @engines;
  # Use engine list if exists
  my $list = "$dir/Engines.lst";
  if (open(LIST,$list))
  {
    foreach my $engine (<LIST>)
    {
      $engine =~ s|[\r\n]+||g;
      next if (!-e "$dir/$engine.pm");
      push(@engines,$engine);
    }
    close(LIST);
  }
  # Otherwise grab OpenGL/Image modules
  elsif (opendir(DIR,$dir))
  {
    foreach my $engine (readdir(DIR))
    {
      next if ($engine !~ s|\.pm$||);
      push(@engines,$engine);
    }
    closedir(DIR);

    # Targa engine gets priority when no Engines.lst exists
    @engines = ((grep {$_ eq 'Targa'} @engines),
      grep {$_ ne 'Targa'} @engines);
  }
  return if (!@engines);

  my @info;
  my $engines = {};
  my $priority = 1;
  foreach my $engine (@engines)
  {
    next if ($engine eq 'Common');
    my $info = HasEngine($engine);
    next if (!$info);

    if (wantarray)
    {
      push(@info,$info);
    }
    else
    {
      $info->{priority} = $priority++;
      $engines->{$engine} = $info;
    }
  }

  return wantarray ? @info : $engines;
}


# Check for engine availability; returns installed version
sub HasEngine
{
  my($engine,$min_ver,$max_ver) = @_;
  return if (!$engine);

  my($version,$desc);
  my $module = GetEngineModule($engine);

  # Redirect Perl errors if module can't be loaded
  open(OLD_STDERR, ">&STDERR");
  close(STDERR);

  my $exec = qq
  {
    use $module;
    \$version = $module\::EngineVersion();
    \$desc = $module\::EngineDescription();
  };
  eval($exec);

  # Restore STDERR
  open(STDERR, ">&OLD_STDERR");
  close(OLD_STDERR);

  return if (!$version);
  return if ($min_ver && $version lt $min_ver);
  return if ($max_ver && $version gt $max_ver);

  my $info = {};
  $info->{name} = $engine;
  $info->{module} = $module;
  $info->{version} = $version;
  $info->{description} = $desc;

  return $info;
}


# Get module name for engine
sub GetEngineModule
{
  my($engine) = @_;
  return if (!$engine);
  return __PACKAGE__."::$engine";
}


# Constructor wrapper for imaging engine
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless($self,$class);

  my %params = @_;
  my $engine = $params{engine};
  if ($engine)
  {
    return if ($engine eq 'Common');
    return NewEngine($engine,%params);
  }

  my @engines = GetEngines();
  foreach my $info (@engines)
  {
    my $obj = NewEngine($info->{name},%params);
    return $obj if ($obj);
  }
  return undef;
}


# Instantiate engine
sub NewEngine
{
  my($engine,%params) = @_;
  return undef if (!$engine);

  my $obj;
  my $module = GetEngineModule($engine);

  my $exec = qq
  {
    use $module;
    \$obj = new $module\(\%params);
  };
  eval($exec);

  return $obj;
}


1;
__END__

