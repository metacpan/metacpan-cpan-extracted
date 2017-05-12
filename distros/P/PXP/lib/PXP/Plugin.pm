package PXP::Plugin;

=pod

=head1 NAME

  PXP::Plugin - Plugin class definition (used only in the
  internal registry)

=head1 SYNOPSIS

<?xml version="1.0"?>

<plugin
  id="IMC::WebApp::TestPlugin"
  name="Test plugin"
  version="0.1"
  provider-name='IDEALX'>

</plugin>


=head1 DESCRIPTION

A plugin groups together a set of extensions and/or
extension-points.

A C<PXP::Plugin> represents such a container as it is read and its
content loaded into the system. A common interface is provided to
access the configuration descriptors and the actual implementation
that has been loaded into the system.

B<NOTE>: a C<PXP::Plugin> object is B<NOT> a plugin.

A I<real> plugin, is just a set of Perl modules loaded according to
the 'plugin.xml' descriptor file.

Plugin dependencies are supported with the <require> tag.

=head2 Limitations

We support only a subset of the Eclipse plugin model.

=cut

use strict;
use warnings;

use PXP::ExtensionPoint;
use PXP::Extension;

use XML::XPath;
use File::Spec;
use Cwd;

use Log::Log4perl qw(get_logger);
my $logger = get_logger(__PACKAGE__);

sub new {
  my $class = shift;
  my $self = {
	      name => '',
	      id => '',
	      version => 0,
	      provider_name => '',
	      extensions => {},
	      extension_points => {},
	      dependencies => []
	     };
  bless $self, $class;
  return $self->init(@_);
}

sub init {
  my $self = shift;
  my %opts = @_;

  # TODO : warn if no directory
  $self->directory($opts{'directory'});

  my $filename = $opts{'filename'} || '';
  if ($filename) {
    my $config = $self->loadLocalizedResource($filename)
      || die "cannot find config for plugin";

    my $xp = XML::XPath->new(xml => $config);

    $self->loadFromXML($xp);
  }

  return $self;
}

sub loadFromXML {
  my $self = shift;
  my $xp = shift;

  # FIXME: Check all values

  # Set plugin params;
  my @nodes = $xp->findnodes('/plugin');
  unless (@nodes) {
    $logger->error("No plugin defined in xml config file. Loading aborted.");
    return undef;
  }

  my $node = shift @nodes;
  # Define parameters
  $self->id($node->getAttribute('id'));
  $self->class($node->getAttribute('class'));
  $self->name($node->getAttribute('name'));
  $self->version($node->getAttribute('version'));
  $self->providerName($node->getAttribute('provider-name'));

  # Handle dependencies
  my @deps = $xp->findnodes('/plugin/require');
  $self->addDependencies(map ($_->getAttribute('plugin'), @deps));

  # Handle libraries
  my @libs = $xp->findnodes('/plugin/runtime/library');
  $self->addLibraries(map ($_->getAttribute('name'), @libs));

  # Save XML node
  $self->{'xml'} = $xp;

  # Add the plugin directory to Perl search path
  unshift @INC, $self->directory();

  # Extensions and ExtensionPoints are no longer instantiated here.
  # This must be done by _instantiateExtensions(), after dependencies
  # have been loaded.
}

sub instantiateExtensions {
  my $self = shift;

  my $xp = $self->{'xml'};
  my $node;
  # Create extension points
  foreach $node ($xp->findnodes('/plugin/extension-point')) {
    my $id = $node->getAttribute('id') || die "bummer";
    my $class = $node->getAttribute('class') || $id; # FIXME: if nothing was specified, do not force a class load
    my $name = $node->getAttribute('name');
    my $version = $node->getAttribute('version');
    my $obj;

    # Instantiate it
    # FIXME: Add test on values
    my $extpt = PXP::ExtensionPoint->new($self);
    if (_loadClass($class)) {
      $obj = $class->new($self);
      # support for Aurelien's approach (an extension point 'IS-A' PXP::ExtensionPoint)
      if ($obj->isa('PXP::ExtensionPoint')) {
        $logger->warn("$id should not be an PXP::ExtensionPoint !");
	undef $extpt;
	$extpt = $obj;
      }
      $extpt->object($obj);
    }
    $extpt->id($id);
    $extpt->class($class);
    $extpt->name($name);
    $extpt->version($version);
    $self->_storeExtensionPoint($extpt);
  }

  # Add extensions
  foreach $node ($xp->findnodes('/plugin/extension')) {

    # Get informations
    my $id = $node->getAttribute('id') || die "bummer";
    my $point = $node->getAttribute('point') || die "bummer";
    my $class = $node->getAttribute('class') || $id;
    my $name = $node->getAttribute('name');
    my $version = $node->getAttribute('version');
    my $obj;

    my $ext = PXP::Extension->new($self);
    $ext->id($id);
    $ext->class($class);
    $ext->name($name);
    $ext->version($version);
    $ext->point($point);
    $ext->node($node);
    $self->_storeExtension($ext);
  }
}

=pod

=over 4

=item instantiateExtension($class, @args)

Load a perl class ($class) and instantiate a new object of this class, with optional arguments for the object initializer (@args)

Return the new instance or undef if the class could not be loaded

=back

=cut

sub instantiateExtension {
  my $self = shift;
  my $class = shift;
  my @args = shift;
  
  # Instantiate
  if (PXP::Plugin::_loadClass($class)) {
    return $class->new(@args);
  } else {
    die "Could not instanciate class $class";
    return undef;
  }
}

=pod "

=over 4

=item I<name>, I<id>, I<version>, I<providerName>

Basic accessors for plugin properties.

=cut "

sub name {
  my $self = shift;
  if (@_) {
    $self->{name} = shift;
    return $self;
  } else {
    return $self->{name};
  }
}

sub id {
  my $self = shift;
  if (@_) {
    $self->{id} = shift;
    return $self;
  } else {
    return $self->{id};
  }
}

sub class {
  my $self = shift;
  if (@_) {
    $self->{class} = shift;
    return $self;
  } else {
    return $self->{class};
  }
}

sub version {
  my $self = shift;
  if (@_) {
    $self->{version} = shift;
    return $self;
  } else {
    return $self->{version};
  }
}

sub providerName {
  my $self = shift;
  if (@_) {
    $self->{provider_name} = shift;
    return $self;
  } else {
    return $self->{provider_name};
  }
}

=pod

=item I<resourceDir>

Accessor for the 'resourceDir' attribute. 'resourceDir' points to the
directory containing the resources bundled with the plugin, such as
config files, templates, etc.

This method is called by the I<PluginRegistry> as it loads the plugin.

=cut "

sub resourceDir {
  my $self = shift;
  return $self->directory(@_);
}

sub xml {
  my $self = shift;
  return $self->{xml};
}

sub directory {
  my $self = shift;
  if (@_) {
    $self->{directory} = shift;
    return $self;
  } else {
    return $self->{directory};
  }
}

sub fullDirectory {
  my $self = shift;
  return File::Spec->catdir(getcwd(), $self->{directory});
}

sub resource {
  my $self = shift;
  return File::Spec->catfile($self->directory(), @_);
}

sub fullResource {
  my $self = shift;
  return File::Spec->catfile($self->fullDirectory(), @_);
}

sub getDependencies {
  my $self = shift;
  return $self->{'dependencies'};
}

sub addDependencies {
  my $self = shift;
  push @{$self->{'dependencies'}}, @_;
  return $self;
}

sub libraries {
  my $self = shift;
  return $self->{'libraries'};
}

sub addLibraries {
  my $self = shift;
  push @{$self->{'libraries'}}, @_;
  return $self;
}

sub _loadClass {
  my $class = shift;

  eval "require $class";
  if ($@) {
    warn "Could not load $class: " .$@;
    return undef;
  }
  return 1;
}

sub _storeExtensionPoint {
  my $self = shift;
  my $ext = shift;
  $self->{'extension_points'}->{$ext->id()} = $ext;
  return $ext;
}

sub getExtensionPoint {
  my $self = shift;
  my $id = shift;
  return $self->{'extension_points'}->{$id};
}

sub getAllExtensionPoints {
  my $self =  shift;

  if ($self->{'extension_points'}) {
      return (values %{$self->{'extension_points'}});
  }
}

sub _storeExtension {
  my $self = shift;
  my $ext = shift;
  $self->{'extensions'}->{$ext->id()} = $ext;
  # remember extension declaration order in the plugin.xml file
  push @{$self->{'extensions_array'}}, $ext;
  return $ext;
}

sub getExtension {
  my($self) = shift;
  my($id) = shift;
  return($self->{'extensions'}->{$id});
}

# Return an _ordered_ list of extensions for the plugin, so we can control extension registration order
# (this is important for constructing the MainPipeline, and make sure the RequestManager gets called first)

sub getAllExtensions {
  my $self =  shift;

  if ($self->{'extensions_array'}) {
      return @{$self->{'extensions_array'}};
  }
}

use FileHandle;

sub getResourceHandle {
  my $self = shift;
  my $resourceId = shift;

  if (! $self->isa('PXP::Plugin')) {
    $self = PXP::PluginRegistry::getPlugin($self)
      || die "cannot find which plugin I am !";
  }

  my $filename = File::Spec->catfile($self->resourceDir(), $resourceId);
  $logger->debug("resource for " . $self->id() . " should be in " . $filename);

  return new FileHandle $filename;
}

# almost the same code as above, except we try to find a localized property file
# property files are named with the locale and after the original filename,
# but with a .properties extension (instead of the filename original extension, like .xml)
sub getPropertyFileHandle {
  my $self = shift;
  my $resourceId = shift;

  my $dir;
  if (! $self->isa('PXP::Plugin')) {
    $self = PXP::PluginRegistry::getPlugin($self)
      || die "cannot find which plugin I am !";
  }

  $dir = $self->resourceDir();
  use File::Basename;
  my ($filenamePrefix, $dummy, $dummy2) = fileparse($resourceId, qr/\..*/);
  my $filename = File::Spec->catfile($dir, $filenamePrefix);

  $logger->debug('looking for property file ' . $filenamePrefix . '.properties');
  my $pfname = PXP::I18N::getPropertyFile($filename);

  return new FileHandle $pfname;
}

sub loadResource {
  my $self = shift;
  my $resourceId = shift;

  $logger->debug("loading resource $resourceId");
  my $handle = $self->getResourceHandle($resourceId);
  local $/;
  return <$handle>;
}

# same as above, but we look for a property file
# and substitute with the '%property' pattern (same as in Eclipse)
sub loadLocalizedResource {
  my $self = shift;
  my $resourceId = shift;

  $logger->debug("loading localized resource $resourceId");
  my $pfh = $self->getPropertyFileHandle($resourceId);
  unless ($pfh) {
    my $rfh = $self->getResourceHandle($resourceId);
    local $/;
    return <$rfh>;
  }

  my $rfh = $self->getResourceHandle($resourceId);

  return PXP::I18N::loadNLocalize($rfh, $pfh);
}

=pod "

=head1 SEE ALSO

C<PXP::PluginRegistry>, C<PXP::ExtensionPoint>, C<PXP::Extension>

See the article on eclipse.org describing the plugin architecture : 
http://www.eclipse.org/articles/Article-Plug-in-architecture/plugin_architecture.html

=cut

1;
