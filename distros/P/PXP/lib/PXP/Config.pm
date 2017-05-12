package PXP::Config;

=pod

=head1 NAME

B<PXP::Config>

=head1 SYNOPSIS

# do this only once at server initialization:

PXP::Config::init(file=>$finename);

# then from anywhere:

my $global_configuration_hash = PXP::Config::getGlobal();

# only from a plugin class:

my $plugin_configuration_hash = PXP::Config::get();

=head1 DESCRIPTION

B<PXP::Config> is a PXP component which provides a unified and
simplified API for the PXP server and PXP plugins to read and store there
configuration.

B<PXP::Config> uses the B<XML::Simple> module to access a centralized
XML configuration file. This file (F</opt/etc/imc.xml> by default)
contains root element named B<imc> which has a B<global> child for
the PXP server configuration and a B<plugins> child which has itself a
child per plugin configuration (the child name must be the plugin name
for this class to automatically retrieve a plugin configuration.

As plugins configurations are retrived by plugin name in a centralized
location, the only thing a plugin has to do in order to get its
configuration is to call the B<PXP::Config::get()> method which returns a
hash convertion of the plugin XML configuration.

Configuring plugins can be made in two manners:

1) the simple way - use it when you don't need to update the
configuration from the application itself and when your plugin
configuration has a very simple structure:

simply add a tag with the name of your plugin in the etc/imc.xml file, the
plugin configuration can then be accessed as a has by calling the
PXP::Config::get() method

2) the sophisticated way - use it in other cases:

create a new package in a file MyConfig/PLUGIN_NAME.pm under your
plugin directory

in this file, define a package that inherits from PXP::MyConfig class
and which overrode the config, loadFile and synchro methods (see
plugins/LogViewer/MyConfig/LogViewer.pm for an example)

edit your plugin.xml and add your new package as an extension to the
PXP::MyConfig extension point:


  <extension
    id="MyConfig::LogViewer"
    name="Plugin configuration"
    version="0.1"
    point="IMC::MyConfig"/>

     <file value='/tmp/imc.xml'/>

   </extension>

You can ommit the file tag, configuration file will then default to
the main configuration file (the one passed to the server with the -c
switch or etc/imc.xml by default).

See the B<PXP::Config> and B<PXP::MyConfig> APIs for using configuration
inside plugins.


=head1 METHODS

=over 4

=cut 

use strict;
use warnings;

use XML::Simple;

use Log::Log4perl qw(get_logger);
our $logger = get_logger(__PACKAGE__);

our $instance;

sub new {
  my $class = shift;
  my $args = {@_};

  my $file = $args->{file} || 'pxp-config.xml';
  $XML::Simple::PREFERRED_PARSER = 'XML::Parser'; # may switch to
                                                  # XML::SAX if
                                                  # configuration
                                                  # file becomes
                                                  # huge
  my $hash = XMLin($file);

  $logger->info("Loading configuration from file $file");


  my $self = {
	      file=>$file,
	      hash=>$hash,
	     };

  return bless($self, $class);
}

=pod

=item init(file=>$filename)

Initialize a single PXP::Config instance with the whole XML file
$filename converted as a hash.

=cut

sub init {
  my $args = {@_};
  $instance = new PXP::Config(file=>$args->{file}) unless defined $instance;
}

=pod

=item getGlobal()

Returns a hash convertion of the XML subnode with name "global"

=cut

sub getGlobal{
  my $section = shift;

  return $section ? $instance->{hash}->{global}->{$section} :
    $instance->{hash}->{global};
}

=pod

=item file()

Returns conf filename.

=cut

sub file {
  my $self = shift;

  return $instance->{file};
}

=pod

=item getPluginConfig($plugin_name)

Returns a hash convertion of the XML configuration subnode with path
"plugins/$plugin_name"

=cut

sub getPluginConfig {
  my $plugin_name = lc(shift);

  $logger->debug("getPlugin from $plugin_name");
  return $instance->{hash}->{plugins}->{$plugin_name};
}

sub getPlugin { die "not supported anymore: use getPluginConfig() now"; }

=pod

=item get($section)

Return a hash converted from the XML subnode with path
"plugins/$plugin_name" where $plugin_name is computed from the calling
class. Behaviour when called from outside a plugin class is
undefined.

You can specify a first level section to get only this section.

=cut

sub get {
  my $section = shift;

  my @parts = split '::',lc(caller());
  my $caller = $parts[0] =~ /imc/i ? $parts[1] : $parts[0];

  return $section ? $instance->{hash}->{plugins}->{$caller}->{$section} :
    $instance->{hash}->{plugins}->{$caller};
}


=pod

=item getMyConfig($section)

Returns the specific object of class derived from PXP::MyConfig for
the calling plugin.

You can specify a first level section to get only this section.

=cut


sub getMyConfig {
  my $section = shift;

  my @parts = split '::',caller();
  my $caller = $parts[0] =~ /imc/i ? $parts[1] : $parts[0];
  my $class = "MyConfig::$caller";

  my $registry = PXP::PluginRegistry::getExtensionPoint('PXP::MyConfig')->registry();
  foreach my $conf (@$registry) {
    if ($conf->isa($class)) {
      $logger->debug("Found configuration object of class: $class");
      return $section ? $conf->get($section) : $conf;
    }
  }
  return undef;
}

=pod

=back

=cut

1;
