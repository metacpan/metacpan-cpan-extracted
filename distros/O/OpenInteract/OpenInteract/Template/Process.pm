package OpenInteract::Template::Process;

# $Id: Process.pm,v 1.24 2002/09/16 20:18:36 lachoy Exp $

use strict;
use Data::Dumper qw( Dumper );
use OpenInteract::Template::Context;
use OpenInteract::Template::Plugin;
use OpenInteract::Template::Provider;
use Template;

$OpenInteract::Template::Process::VERSION  = sprintf("%d.%02d", q$Revision: 1.24 $ =~ /(\d+)\.(\d+)/);

use constant DEFAULT_COMPILE_EXT => '.ttc';
use constant DEFAULT_CACHE_SIZE  => 75;

# Since each website gets its own template object, when we call
# initialize() all the website's information has been read in and
# setup so we should be able to ask the config object what plugin
# objects are defined, etc.

sub initialize {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && $R->scrib( 1, "Starting template initialization process" );
    my $CONFIG = $R->CONFIG;
    my $oi_tt_config = $CONFIG->{template_info};

    $Template::Config::CONTEXT = 'OpenInteract::Template::Context';

    # Default configuration -- this can be modified by each site

    my $cache_size  = ( defined $oi_tt_config->{cache_size} )
                        ? $oi_tt_config->{cache_size} : DEFAULT_CACHE_SIZE;
    my $compile_ext = $oi_tt_config->{compile_ext} || DEFAULT_COMPILE_EXT;
    my $compile_dir = $CONFIG->get_dir( 'cache_tt' );

    # If the compile_dir isn't specified, be sure to set it **and**
    # the extension to undef, otherwise TT will try to compile/save
    # the templates into the directory we find them (maybe: the custom
    # provider might override, but whatever)

    unless ( defined $compile_dir ) {
        $compile_ext = undef;
        $compile_dir = undef;
    }

    my %tt_config = ( PLUGINS     => { OI => 'OpenInteract::Template::Plugin' },
                      CACHE_SIZE  => $cache_size,
                      COMPILE_DIR => $compile_dir,
                      COMPILE_EXT => $compile_ext );

    # Install various template configuration items (currently plugins
    # and blocks) as specified by packages

    $class->_package_template_config( \%tt_config );

    # Create the configuration for this TT object and give the user a
    # chance to add to or modify it

    if ( my $custom_init_class = $CONFIG->{template_info}{custom_init_class} ) {
        eval "require $custom_init_class";
        if ( $@ ) {
            $R->scrib( 0, "Custom initialize class ($custom_init_class) is not",
                          "available for me to use: ($@). I'm going to keep going." );
        }
        else {
            my $method = $CONFIG->{template_info}{custom_init_method} || 'handler';
            $R->DEBUG && $R->scrib( 1, "Running custom template init handler: ",
                                       "$custom_init_class\->$method" );
            eval { $custom_init_class->$method( \%tt_config ) };
            if ( $@ ) {
                $R->scrib( 0, "Custom template init handler ($custom_init_class\->$method)",
                              "failed. ($@) I'm going to keep running initialize()." );
            }
            else {
                $R->DEBUG && $R->scrib( 1, "Ran custom template init handler ok" );
            }
        }
    }

    # Put the configured OI provider in the mix. Note that we do this
    # AFTER the customization process so the user can set cache size,
    # compile directory, etc.

    my $oi_provider = OpenInteract::Template::Provider->new(
                                        CACHE_SIZE  => $tt_config{CACHE_SIZE},
                                        COMPILE_DIR => $tt_config{COMPILE_DIR},
                                        COMPILE_EXT => $tt_config{COMPILE_EXT} );
    unshift @{ $tt_config{LOAD_TEMPLATES} }, $oi_provider;

    $R->DEBUG && $R->scrib( 3, 'Configuration before sent to Template->new():',
                               Dumper( \%tt_config ) );
    my $template = Template->new( %tt_config ) || die Template->error();
    return $template;
}


# Display an OI document

sub handler {
    my ( $class, $template_config, $template_vars, $template_source ) = @_;
    my $R = OpenInteract::Request->instance;

    my ( $name, $to_process );
    if ( $template_source->{text} ) {
        $to_process = ( ref $template_source->{text} eq 'SCALAR' )
                        ? $template_source->{text} : \$template_source->{text};
        $name       = '_anonymous_';
        $R->DEBUG && $R->scrib( 1, "Using raw template source (",
                                   ref $template_source->{text}, ") for processing" );
    }
    elsif ( $template_source->{object} ) {
        $to_process = \$template_source->{object}{contents};
        $name       = $template_source->{object}->create_name;
        push @{ $R->{templates_used} }, $name;
        $R->DEBUG && $R->scrib( 1, "Using template object [$name] for processing" );
    }

    # Using 'db' will be deprecated soon...

    elsif ( $template_source->{db} ) {
        unless ( $template_source->{package} ) {
            die "Must give 'package' along with 'db' when processing " .
                "template. (Given: $template_source->{db})\n";
        }
        $name = join( '::', $template_source->{package}, $template_source->{db} );
        $to_process = $name;
        push @{ $R->{templates_used} }, $name;
        $R->DEBUG && $R->scrib( 1, "Using template name [$name] for processing" );
    }

    elsif ( $template_source->{name} ) {
        $name = $template_source->{name};
        $to_process = $name;
        push @{ $R->{templates_used} }, $name;
        $R->DEBUG && $R->scrib( 1, "Using template name [$name] for processing" );
    }

    # Uh oh...

    else {
        $R->scrib( 0, "No template to process! Information given for source:\n",
                      Dumper( $template_source ) );
        die "No template to process!\n";
    }
    # Grab the template object and the OI plugin, making the OI plugin
    # available to every template

    my $template         = $R->template_object;
    $template_vars->{OI} = $template->context->plugin( 'OI' );

    # Allow websites to modify the $template_vars passed to every page

    if ( my $custom_variable_class = $R->CONFIG->{template_info}{custom_variable_class} ) {
        eval "require $custom_variable_class";
        if ( $@ ) {
            $R->scrib( 0, "Custom variable class ($custom_variable_class) is not",
                          "available for me to use: ($@). I'm going to keep going." );
        }
        else {
            my $method = $R->CONFIG->{template_info}{custom_variable_method} || 'handler';
            $R->DEBUG && $R->scrib( 1, "Running custom template variable handler: ",
                                       "$custom_variable_class\->$method" );
            eval { $custom_variable_class->$method( $name, $template_vars ) };
            if ( $@ ) {
                $R->scrib( 0, "Custom template handler ($custom_variable_class\-\>$method) died ",
                              "with ($@). I'm going to keep processing." );
            }
            else {
                $R->DEBUG && $R->scrib( 1, "Ran custom template init handler ok" );
            }
        }
    }

    my ( $html );
    $template->process( $to_process, $template_vars, \$html )
                    || die "Cannot process template!", $template->error();
    return $html;
}


sub _package_template_config {
    my ( $class, $config ) = @_;
    my $R = OpenInteract::Request->instance;

    # Find all the packages in this website

    my $website_dir = $R->CONFIG->{dir}{base};
    my $pkg_list  = $R->repository->fetch( undef, { directory => $website_dir } )
                                  ->fetch_all_packages;
    $R->DEBUG && $R->scrib( 1, "Packages for inspection by template initialization read ok" );

    # For each package in the site, read in custom blocks and template
    # plugins if they are available

    foreach my $pkg ( @{ $pkg_list } ) {
        if ( ref $pkg->{template_block} eq 'HASH' ) {
            foreach my $block_class ( keys %{ $pkg->{template_block} } ) {
                my $block_method = $pkg->{template_block}{ $block_class };
                my $item_blocks = eval { $block_class->$block_method() };
                foreach my $block_name ( keys %{ $item_blocks } ) {
                    $R->DEBUG && $R->scrib( 1, "Found template block ($block_name) in",
                                               "$block_class\->$block_method" );
                    $config->{BLOCKS}{ $block_name } = $item_blocks->{ $block_name };
                }
            }
        }
        if ( ref $pkg->{template_plugin} eq 'HASH' ) {
            foreach my $plugin_tag ( keys %{ $pkg->{template_plugin} } ) {
                $R->DEBUG && $R->scrib( 1, "Found template plugin $plugin_tag",
                                           "=> $pkg->{template_plugin}{ $plugin_tag }" );
                $config->{PLUGINS}{ $plugin_tag } = $pkg->{template_plugin}{ $plugin_tag };
            }
        }
    }
}


1;

__END__

=head1 NAME

OpenInteract::Template::Process - Process OpenInteract templates

=head1 SYNOPSIS

 # Specify an object by fully-qualified name (preferrred)

 my $html = $R->template->handler( {}, { key => 'value' },
                                   { name => 'my_pkg::this_template' } );

 # Specify an object by package and name

 my $html = $R->template->handler( {}, { key => 'value' },
                                   { package => 'my_pkg',
                                     db      => 'this_template' } );

 # Directly pass text to be parsed (fairly rare)

 my $little_template = 'Text to replace -- here is my login name: ' .
                       '[% login.login_name %]';
 my $html = $R->template->handler( {}, { key => 'value' },
                                   { text => $little_template } );

 # Pass the already-created object for parsing (rare)

 my $site_template_obj = $R->site_template->fetch( 'mypkg::myname' );
 my $html = $R->template->handler( {}, { key => 'value' },
                                   { object => $site_template_obj } );

=head1 DESCRIPTION

This class processes templates within OpenInteract. The main method is
C<handler()> -- just feed it a template name and a whole bunch of keys
and it will take care of finding the template (from a database,
filesystem, or wherever) and generating the finished content for you.

Shorthand used below: TT == Template Toolkit.

=head1 INITIALIZATION

B<initialize( \%config )>

Creates a TT processing object with necessary parameters and returns
it. We generally call C<initialize()> from
L<OpenInteract::Request|OpenInteract::Request> on the first request
for a template object. Each website running in the same process gets
its own template object.

Since we create one TT object per website, we can initialize that
object with website-specific information. So the initialization
process steps through the packages available in the website and asks
each one for its list of template plugins and template blocks. Once
retrieved, the TT object is started up with them and they are
available via the normal means.

Package plugins created in this matter are available either via:

 [% USE MyPlugin %]

or by defining a C<custom_variable_class> for the template and setting
the plugin to be available without the TT 'use' statement. (See below
for details.)

Package BLOCKs created in this manner can be used via the TT 'PROCESS'
directive:

[% PROCESS mycustomblock( this = that ) -%]

See L<Template::Manual::Directives|Template::Manual::Directives> for
more information.

Note that you can also define custom initialization methods (on a
global website basis) as described below.

=head2 Custom Initialization

You can define information in the server configuration of your website
that enables you to modify the configuration passed to the C<new()>
method of L<Template|Template>.

In your server configuration, define values for the keys:

  template_info->{custom_init_class}
  template_info->{custom_init_method}

The class/method combination (if you do not specify a method name,
'handler' will be used) get passed the template configuration hashref,
which you can modify as you see fit. There are many variables that you
can change; learn about them at
L<Template::Manual::Config|Template::Manual::Config>.

For instance, say you have a template of all the BLOCKs you use to
define common graphical elements. (You can more easily do this with
template widgets, but this is just an example.) You can save this
template as C<$WEBSITE_DIR/template/myblocks.tmpl>. Then to make it
available to all templates processed by your site, you can do:

 # In conf/server.perl

 template_info => {
    custom_init_class  => 'MyCustom::Template',
    custom_init_method => 'initialize',
 },

 # In MyCustom/Template.pm:

 package MyCustom::Template;

 use strict;

 sub initialize {
     my ( $class, $template_config ) = @_;
     push @{ $template_config->{PRE_PROCESS} }, 'myblocks';
 }

Easy! Since 'myblocks.tmpl' is a global template, it will get picked
up by
L<OpenInteract::Template::Provider|OpenInteract::Template::Provider>
when TT tries to process it before every request. And since TT does
template caching, you should not get the performance hit associated
with parsing/compiling the global BLOCKs template with every template
processed.

Since this is a normal Perl handler, you can perform any actions you
like here. For instance, you can retrieve templates from a website via
LWP, save them to a file and specify that file in C<PRE_PROCESS>.

Note that C<initialize()> should only get executed once for every
website for every Apache child; most of the time this is fairly
infrequent, so you can execute code here that takes a little more time
than if it were being executed with every request.

(Non sequitur: the same MACRO/BLOCK can be specified in multiple
PRE_PROCESS items. Items read later in the list get precedence.)

=head1 PROCESSING

B<handler( \%template_params, \%template_variables, \%template_source )>

Generate template content, given keys and values in
C<\%template_variables> and a template identifier in
C<\%template_source>.

Parameters:

=over 4

=item *

B<template_params> (\%)

Configuration options for the template. Note that you can set defaults
for these at configuration time as well.

=item *

B<template_variables> (\%)

The key/value pairs that will get plugged into the template. These can
be arbitrarily complex, since the Template Toolkit can do anything :-)

=item *

B<template_source>

Tell the method how to find the source for the template you want to
process. There are a number of ways to do this:

Method 1: Use a combined name (preferred method)

 name    => 'package_name::template_name'

Method 2: Specify package and name separately

 package => 'package_name',
 db      => 'template_name'

Note that both the template name and package are B<required>. This is
a change from older versions when the template package was optional.

Method 3: Specify the text yourself

 text    => $scalar_with_text
 or
 text    => \$scalar_ref_with_text

Method 4: Specify an object of type
L<OpenInteract::SiteTemplate|OpenInteract::SiteTemplate>

 object => $site_template_obj

=back

=head2 Custom Processing

You have the opportunity to step in during the executing of C<handler()>
with every request and set template variables. To do so, you need to
define a handler and tell OI where it is.

To define the handler, just define a normal Perl class method that
gets two arguments: the name of the current template (in
'package::name' format) and the template variable hashref:

 sub my_variable {
     my ( $class, $template_name, $template_vars ) = @_;
     ...
 }

To tell OI where your handler is, in your server configuration file
specify:

 'template_info' => {
    custom_variable_class  => 'MyCustom::Template',
    custom_variable_method => 'variable',
 }

Either the 'custom_variable_method' or the default method name
('handler') will be called.

You can set (or, conceivably, remove) information bound for every
template. Variables set via this method are available to the template
just as if they had been passed in via the C<handler()> call.

Example where we make a custom plugin (see C<initialize()> above)
available to every template:

  # In server.perl:

  template_info => {
    custom_variable_class  => 'MyCustom::Template',
    custom_variable_method => 'variable',
  },

  # In MyCustom/Template.pm:

  package MyCustom::Template;

  use strict;

  sub variable {
      my ( $class, $template_name, $template_vars ) = @_;
      my $R = OpenInteract::Request->instance;
      $template_vars->{MyPlugin} = $R->template_object
                                     ->context
                                     ->plugin( 'MyPlugin' );
  }

  1;

Using this process, our templates will not need to execute a:

 [% USE MyPlugin %]

before using the methods in the plugin.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<Template|Template>

L<OpenInteract::Template::Context|OpenInteract::Template::Context>

L<OpenInteract::Template::Plugin|OpenInteract::Template::Plugin>

L<OpenInteract::Template::Provider|OpenInteract::Template::Provider>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
