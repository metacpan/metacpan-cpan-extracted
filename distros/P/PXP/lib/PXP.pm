package PXP;

=head1 NAME

PXP - Perl Xtensions & Plugins

=head1 SYNOPSIS

 use PXP;
 PXP::init();

=head1 DESCRIPTION

This module provides a generic plugin framework, similar to the
Eclipse model.  It has been developed for the IMC project (see
http://www.idealx.org/prj/imc) and is now released as an autonomous
CPAN module.

=head2 Definitions

A "plugin" is a common design pattern found in many modern software
frameworks. However, plugins sometimes refer to just a loadable binary
library or require inheriting from a base class with the disadvantage
of additional coupling.

In the PXP model, plugins and extensions have a particular definition:

=over 4

=item B<plugin>

A I<plugin> is a packaged set of software components that extend a
system or provide extension points for other components.

A plugin may contain extensions, extension points, and the
configuration nodes (XML) related to these components.

A plugin can also contain other files, like CPAN modules, PAR (Perl
ARchive) modules, HTML templates, icons, etc.

A plugin is described by a 'plugin.xml' descriptor file. See the
example below.

=item B<extension point>

An I<extension-point> defines (as its name says!) an extension point
for extending a system with extension components.

For example, an extension point with id='MainMenu' could group
together many extensions, each one adding one or multiple menu
entries to the 'MainMenu' extension point.

Another example: an id='HttpPipeline' extension-point could be used to
build a pipeline of individual handlers that act together on a
HTTP::Request object to analyze and respond to a browser query. Each
stage of the pipeline could be registered in the 'HttpPipeline'
extension point to actually call a subroutine as the request is
processed.

In fact, these examples are really implemented in the IMC
platform. See http://imc.sourceforge.net/ for more details.

This definition of an extension point illustrates the fact that an
extension-point can be just a static hash of datas (menus) or can also
instantiate objects and execute code contained in extensions, as in
the pipeline example.

Also note, that the PXP framwework does not mandate any specific
behaviour for an extension-point : a dummy extension-point can just
'forget' about any extension that tries to register to it.

=item B<extension>

An I<extension> in the PXP model is what other frameworks usually call
a 'plugin'.

An I<extension> represents a component that extends the system.

It can be a piece of data (remember the menu example above), or it
can contain a part of code, or a class definition.

It is also commonly used to describe, configure and trigger the
creation of object I<instances>, in coordination with an extension
point.

=back

=head2 Annotated 'plugin.xml' example

<?xml version="1.0"?>

Every plugin descriptor is an XML file containing one <plugin>
definition.



<plugin id="IMC::WebApp::TestPlugin"
        name="Test plugin"
        version="0.1"
        provider-name='IDEALX'>

The 'id' is an arbitraty ID, and is not necessarily related to a Perl
object, class, or instance. However, if a class by the same name
exists under the directory containing the plugin descriptor, then this
class is loaded (require-ed) and its startup() method is called.

An optional 'class' overrides the 'id' attribute for loading the class
by name.

Other attributes, like 'name', 'version' or 'provider-name' are purely
informational.



  <require plugin='IMC::Core'/>

The <require> tag defines dependencies between plugins. The
C<PluginRegistry> will take care of resolving these dependencies in
advance, so that dependent plugins are loaded and startup()'ed before
the requiring plugin.



  <runtime>
    <library name="Crypt-SmbHash-0.02-i386-linux-thread-multi-5.8.3.par"/>
  </runtime>

The <runtime> tag loads additional libraries in the system. Each
library to load is defined by an sub <library> tag. The 'name'
attribute points to the PAR archive containing the bundled
library. The path is relative to the directory containing the
'plugin.xml' descriptor file.



  <extension-point
    id='IMC::MainPipeline'
    name='Main Pipeline Extension-Point'/>

An <extension-point> tag defines a new extension-point in the
system registry. The 'name' attribute is only informational.



  <extension 
    id='IMC::SessionLoader'
    name='Session Loader Extension'
    point="IMC::MainPipeline"/>

An <extension> tag defines an extension. By default, the
C<PluginRegistry> will not do anything special with an extension. It
will just pass it to the target extension-point.

It is the C<ExtensionPoint> that will decide what to do with the
extension definition. A default C<ExtensionPointBaseClass> provides a
simple implementation that creates class instances by 'id' or 'class'
and stores the resulting extension in a hash table.



</plugin>


=head1 SEE ALSO

C<PXP::PluginRegistry>, C<PXP::ExtensionPoint>, C<PXP::Extension>

See the article on eclipse.org describing the plugin architecture : 
http://www.eclipse.org/articles/Article-Plug-in-architecture/plugin_architecture.html

=head1 AUTHORS

David Barth <dbarth@idealx.com>

Aurélien Degrémont <adegremont@idealx.com>

Gérald Macinenti <gmacinenti@idealx.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - dbarth@idealx.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.1';

use PXP::I18N;
use PXP::Config;
use PXP::PluginRegistry;

use Log::Log4perl qw(get_logger);
our $logger = get_logger();

sub init {
  my $args = {@_};

  $args->{debug} = 1 if ($ENV{PXP_DEBUG});
  $ENV{PXP_DEBUG} = 1 if ($args->{debug});

  $ENV{PXP_HOME} ||= `pwd`;
  chomp($ENV{PXP_HOME}); # suppress trailing CR

  my $log_file = $args->{log_file} || "pxp.log";
  my $level = $args->{debug} ? "DEBUG, Logfile, Screen" : "INFO, Logfile";
  if ($args->{log_conf} && -e $args->{log_conf}) {
    Log::Log4perl::init('log.conf');
  } else {
    my $log_conf = <<END;
log4perl.rootLogger                = $level
log4perl.appender.Logfile          = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = $log_file
log4perl.appender.Loggile.layout   = Log::Log4perl::Layout::SimpleLayout
log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logfile.layout.ConversionPattern = %d %p - %m %n
log4perl.appender.Screen           = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr    = 1
log4perl.appender.Screen.layout    = Log::Log4perl::Layout::SimpleLayout
#log4perl.appender.Screen           = Log::Log4perl::Appender::ScreenColoredLevels
#log4perl.appender.Screen.layout    = Log::Log4perl::Layout::PatternLayout
#log4perl.appender.Screen.layout.ConversionPattern = %d %F{1} %L> %m %n
END
    Log::Log4perl::init(\$log_conf);
  }

  $logger->info("PXP init");

  # install Exception reporting
  _installExceptionHandler();

  my $loaderconf = { dir => './plugins',
		     default => 'all' };

  # try to load a configuration file
  if ($args->{configuration_file} && -r $args->{configuration_file}) {
    PXP::Config::init(file => $args->{configuration_file});
    # override default loader configuration
    $loaderconf = PXP::Config::getGlobal()->{pluginloader};
  }

  # load and startup plugins
  PXP::PluginRegistry::init($loaderconf);
}

sub _installExceptionHandler {
  $SIG{qq{__DIE__}} = sub {

    die @_ if $^S;	    # perldo -f die ... but it doesn't work ..

    local $SIG{qq{__DIE__}};	# next die() will be fatal

    my $msg = shift;

    my $err = "A fatal error occured : \n";
    $err .= $msg . "\n";

    # stack backtrace
    foreach my $i (1..30) {
      my ($package, $filename, $line, $subroutine,
	  $hasargs, $wantarray, $evaltext, $is_require) = caller($i);
      if ($package) {
	$err .= "\tat " . $subroutine;
	$err .= ' (' . $filename. ':' . $line . ")\n";
      }
    }
    $logger->error($err);

    die "stopping program\n";
  }

}

1;


