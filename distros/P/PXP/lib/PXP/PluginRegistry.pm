package PXP::PluginRegistry;

=pod

=head1 NAME

PXP::PluginRegistry - Registry of plugins for PXP

=cut

use strict;
use warnings;

use constant PLUGIN_INFO_FILE => 'plugin.xml';

use PXP::Plugin;
use File::Spec;

use Log::Log4perl qw(get_logger);
our $logger = get_logger(__PACKAGE__);

our $VERSION = '0.1';
our $plugins;

=pod "

=head1 SYNOPSIS

  use PXP::PluginRegistry;
  PXP::init(dir => './plugins', default => 'all', load => [], noload => []);
  ...
  my $plugin   = PXP::PluginRegistry::getExtension(ref($self))->plugin();
  my $extpt = PXP::PluginRegistry::getExtensionPoint('PXP::StaticResourcesHandler');

=head1 ABSTRACT

The PluginRegistry groups together a set of plugins, extension points
and extensions for the running system.

=head1 DESCRIPTION

The PluginRegistry manages plugins, extension points and extensions.

The PluginRegistry takes care of loading the plugins from file,
loading classes and Perl modules and, optionnaly, running 'startup'
sub-routines as each plugin is loaded in the system.

=over 4

=item I<init>

Initialize the plugin registry. Note: only one instance of
PluginRegistry is supported (singleton pattern).

=back

=cut "

our $loader = {};

sub init {
  $loader = shift;

  loadPluginsFromDirectory($loader->{dir});
}

=pod "

=item I<getPluginList()>

Return a hash containing all registered plugins.

=back

=cut "

sub getPluginList {
  return %{$plugins};
}

=pod "

=over 4

=item I<getPlugin(id)>

Return a plugin referenced by its id, or undef if no such plugin exists.

I<Warning> : a plugin id can be different from its actual object class, as declared in plugin.xml

=back

=cut "

sub getPlugin {
  my $id = shift;
  return $plugins->{$id};
}

=pod "

=over 4

=item I<loadPluginsFromDirectory(directory)>

Load all plugins present in the directory.

This is usually called once by by PXP::init. Plugin developpers can
call this function to load plugins installed outside of the system
default directory ('plugins' at the root of the PXP home directory).

See below for details about the loading process.

=back

=cut "

sub loadPluginsFromDirectory {
  my $directory = shift;

  # List the plugins inside the directory
  $directory = File::Spec->canonpath($directory);
  $logger->debug("looking for plugins in $directory...");
  opendir DIR, $directory;
  my @dirs = readdir DIR;
  closedir DIR;

  # Check each sub-directory.
  my ($pluginFile, @plugins);
  my $default = $loader->{default};
  my $load = $loader->{load};
  if ($load && ref $load eq "ARRAY") {
	  $load = join ' ',@$load;
  }
  my $noload = $loader->{noload};
  if ($noload && ref $noload eq "ARRAY") {
    $noload = join ' ',@$noload;
  }

  my $debugList = '';

  foreach my $plugdir (@dirs) {
    if ($default eq 'none') {
      next unless $load and $load =~ /$plugdir/i;
    } else { # load all by default
      next if $noload and $noload =~ /$plugdir/i;
    }

    my $dir = File::Spec->catdir(($directory, $plugdir));

    next unless (-d $dir);

    # Load the plugin xml description file
    $pluginFile = File::Spec->catfile($dir, PLUGIN_INFO_FILE);

    # Create plugin files list
    if (-e $pluginFile) {
      my $plugin = PXP::Plugin->new('filename' => PLUGIN_INFO_FILE, 'directory' => $dir, 'moduleName' => $plugdir);
      foreach my $p (@plugins) {
	if ($p->id eq $plugin->id) {
	  $logger->fatal("Plugin " . $p->id . " loaded twice in " .
			 $p->directory . " and " . $plugin->directory);
	  die "problem detected in the plugin directory";
	}
      }
      push @plugins, $plugin;
      $debugList .= "$dir, ";
    }
  }

  $logger->info("preparing to load the following plugins : [$debugList]");

  # Load all plugins, considering dependencies
  loadPlugins(@plugins) if (@plugins);
}

sub loadPlugins {
  my @plugins = @_;

  # Check dependencies to load the plugins in right order.
  my $tree = {};
  my $instances = {};

  # Get plugin dependencies & Fill the tree
  foreach my $plugin (@plugins) {
    $tree->{$plugin->id()} = $plugin->getDependencies();
    $instances->{$plugin->id()} = $plugin;
  }

  # Load the dependencies in the right order
  foreach (@plugins) {
    _loadAndStartPlugin($_ , $tree, $instances);
  }

  return 1;
}

sub _loadAndStartPlugin {
  my $plugin = shift;
  my $tree = shift;
  my $instances = shift;
  my @path = @_;

  # Maybe the plugin is already loaded ?
  return 1 if (_getRegisteredPlugin($plugin->id()));

  $logger->debug("loading plugin " . $plugin->id);
  # Check to find circular dependencies
  if (grep {$plugin->id() eq $_} @path) {
    die "Circular dependencies detected with ".$plugin->id().". Correct this first !";
  }

  # Does the plugin have dependencies ?
  if ($tree->{$plugin->id()} && ref($tree->{$plugin->id()}) eq 'ARRAY') {
    # Load them !
    foreach my $dep (@{$tree->{$plugin->id()}}) {

      # Check if dependency is right
      my $insdep = $instances->{$dep} || _getRegisteredPlugin($dep);
      unless ($insdep) {
	$logger->warn("Dependency $dep does not exist for plugin ".$plugin->id().'. Loading aborted.');
	die "check dependency problem";
      }

      unless (_loadAndStartPlugin($insdep, $tree, $instances, @path, $plugin->id())) {
	$logger->warn("Error loading dependency $dep for ".$plugin->id().'. Loading aborted.');
	die "check dependency problem";
      }
    }
  }

  # Load libraries
  _loadLibraries($plugin->directory(), $plugin->libraries());

  # Instantiate the extensions
  $plugin->instantiateExtensions();

  # register everybody
  registerPlugin($plugin);

  # and call startup
  startupPlugin($plugin);
}


sub _loadLibraries {
  my $dir = shift;
  my $libs = shift;

  foreach my $lib (@{$libs}) {
    $logger->debug("loading library $lib (in $dir)");
    my $filename = File::Spec->catfile($dir, $lib);
    my $loader = "use PAR \'$filename\';";
    eval $loader;
  }
  return 1;
}

sub registerPlugin {
  my $plugin = shift;

  my $error = 1;

  if ($plugin && ref($plugin) && $plugin->isa('PXP::Plugin')) {
    $error = 0;

    # Register extensions with their extension point
    foreach my $ext ($plugin->getAllExtensions()) {
      # in case the plugin does not declare extensions
      last if not $ext;

      # Search the extension point in the global registry or in the own registry of the plugin we're currently registering
      my $extpt = _getExtensionPoint($ext->point()) || $plugin->getExtensionPoint($ext->point());
      if ($extpt) {
	$logger->debug("registering " . $ext->id . " (" . ref($ext) . ") with " . $extpt->id . " (" . ref($extpt) . ")");
	$extpt->register($ext);
      } else {
	$logger->warn("No matching extension point " . $ext->point() . ' while registering '.$plugin->id());
	# $error = 1;
	last;
      }
    }

  } else {

    $logger->error("Could not register the specified plugin. Wrong plugin type.");
    return 0;

  }

  # FIXME : can there really be _detected_ errors now !?
  unless ($error) {

    # Store the plugin in registry
    $plugins->{$plugin->id()} = $plugin;
    $logger->debug('Plugin '.$plugin->id().'-'.$plugin->version()." successfully registered.");
    return 1;
  }
}


# remember which plugin we started to avoid double starts
our $startupRegistry = {};

sub startupPluginWithDependencies {
  my $plugin = shift;
  my $tree = shift;
  my $instances = shift;
  my @path = @_;

  # if class is not declared, do not attempt to startup the plugin
  return 1 if (not $plugin->class);

  # Maybe the plugin has already been started ?
  return 1 if ($startupRegistry->{$plugin->id()});

  # Does the plugin have dependencies ?
  if ($tree->{$plugin->id()} && ref($tree->{$plugin->id()}) eq 'ARRAY') {
    # Load them !
    foreach my $dep (@{$tree->{$plugin->id()}}) {
      # Check if dependency is right
      my $insdep = $instances->{$dep} || _getRegisteredPlugin($dep);
      unless ($insdep) {
	$logger->warn("Dependency $dep does not exist for plugin ".$plugin->id().'. Startup aborted.');
	return undef;
      }

      unless (startupPluginWithDependencies($insdep, $tree, $instances, @path, $plugin->id())) {
	$logger->warn("Error starting up dependency $dep for ".$plugin->id().'. Startup aborted.');
	return undef;
      }
    }
  }

  $startupRegistry->{$plugin->id} = 1 if startupPlugin($plugin);
}

sub startupPlugin {
  my $plugin = shift;

  my $module = $plugin->class() || $plugin->id();

  my $module_file = $module .".pm";
  $module_file =~ s|::|/|g;
  $module_file = File::Spec->catfile($plugin->directory(), $module_file);

  # try to load the module
  if(-e $module_file) {
    $logger->debug("loading $module");
    eval "require $module";
    # $logger->warn("$@\n") if $@;
    die $@ if $@;
  }

  # startup
  {
    no strict;
    if (defined &{"${module}::startup"}) {
      $logger->debug("calling 'startup' for $module");
      &{"${module}::startup"}($plugin);
    }
  }

  return 1;
}

sub getResourceHandle {
  my $plugin = shift;
  my $resourceId = shift;

  return $plugin->getResourceHandle($resourceId);
}

sub loadResource {
  my $plugin = shift;
  my $resourceId = shift;

  return $plugin->loadResource($resourceId);
}

=pod "

=over 4

=item I<getExtensionPoint(id)>

Search the registry for an C<ExtensionPoint> and return it, based on its id.

=back

=cut "

# public interface : this one returns the _object_ associated with an
# extension point, ie the _object_ that actually handles the
# extensions, _not_ the internal descriptor.
sub getExtensionPoint {
  my $id = shift;

  foreach (values %{$plugins}) {
    return $_->getExtensionPoint($id)->object() if ($_->getExtensionPoint($id));
  }
  return undef;
}

# private function : returns the internal ExtensionPoint descriptor,
# _not_ the object that actually handles the extensions.
sub _getExtensionPoint {
  my $id = shift;

  #FIXME: Add checks;
  foreach (values %{$plugins}) {
    return $_->getExtensionPoint($id) if ($_->getExtensionPoint($id));
  }
  return undef;
}

=pod "

=over 4

=item I<getExtensionNode()>

Return the internal XML node describing the extension in the plugin.xml file.

This is mostly used by plugin developpers to get access to the XML config.

=back

=cut "

sub getExtensionNode {
  my $id = shift;

  #FIXME: Add checks;
  foreach (values %{$plugins}) {
    return $_->getExtension($id)->node() if ($_->getExtension($id));
  }
  return undef;
}

=pod "

=over 4

=item I<getExtension(id)>

Search the registry for an C<Extension> and return it, based on its id.

This returns the internal extension descriptor object, ie an PXP::Extension object, not the real extension
See the code for details of the private API.

=back

=cut "

# find the extension object in the registry
sub getExtension {
  my $id = shift;

  #FIXME: Add checks;
  foreach (values %{$plugins}) {
    return $_->getExtension($id) if ($_->getExtension($id));
  }
  return undef;
}

sub _getRegisteredPlugin {
  my $id = shift || '';
  return $plugins->{$id};
}

=pod

=head2 Loading process

First, the PluginRegistry calls loadPluginFromDirectory to load all
the plugins installed in the system directory (usually called
'plugins' inside the PXP hierarchy). The loader calculates the
dependencies so that plugin can resolve symbols.

For each plugin, extension points are instantiated and registered
into the global registry.

Then, extension _definitions_ are handed to the extension points to be
registered. Extension points choose wether to instantiate a particular
objet for each of their extensions.

Last, the PluginRegistry calls the 'startup' routine of each plugin
that declared a specific class (class="" attribute inside the
plugin.xml header).

An error during plugin load stops the process for a whole plugin
dependency branch, but plugin startup is still called for plugins that
have already been loaded.

=head1 SEE ALSO

See C<PXP::ExtensionPoint>, C<PXP::Extension> for details about the
concepts


1;
