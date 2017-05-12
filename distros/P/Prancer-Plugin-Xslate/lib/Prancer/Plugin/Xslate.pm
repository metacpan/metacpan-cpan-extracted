package Prancer::Plugin::Xslate;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.06';

use Prancer::Plugin;
use parent qw(Prancer::Plugin Exporter);

use Prancer::Core;
use Text::Xslate;
use Carp;

our @EXPORT_OK = qw(render mark_raw unmark_raw html_escape uri_escape);
our %EXPORT_TAGS = ('all' => [ @EXPORT_OK ]);

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

sub load {
    my ($class, $config_override) = @_;

    # already got an object
    return $class if ref($class);

    # this is a singleton
    my $instance = undef;
    {
        no strict 'refs';
        $instance = \${"${class}::_instance"};
        return $$instance if defined($$instance);
    }

    my $self = bless({}, $class);

    # merge together options from the configuration file ($config) with options
    # given to this method ($options). later this set of configuration options
    # will be merged with any options given to "render".
    my $config = ($self->config() && $self->config->get("template"));
    $self->{'_config'} = _merge($config || {}, $config_override || {});

    # now export the keyword with a reference to $self
    {
        ## no critic (ProhibitNoStrict ProhibitNoWarnings)
        no strict 'refs';
        no warnings 'redefine';
        *{"${\__PACKAGE__}::render"} = sub {
            my $this = ref($_[0]) && $_[0]->isa(__PACKAGE__) ?
                shift : (defined($_[0]) && $_[0] eq __PACKAGE__) ?
                bless({}, shift) : bless({}, __PACKAGE__);
            return $self->_render(@_);
        };
    }

    $$instance = $self;
    return $self;
}

sub path {
    my $self = shift;
    if (@_) {
        $self->{'_config'}->{'path'} = shift;
    }
    return $self->{'_config'}->{'path'};
}

sub _render {
    my ($self, $template, $vars, $config_override) = @_;

    # just pass all of the options directly to Text::Xslate
    # some default options that are important to remember:
    #    cache     = 1
    #    cache_dir = $ENV{'HOME'}/.xslate_cache
    #    verbose   = 1
    #    suffix    = '.tx'
    #    syntax    = 'Kolon'
    #    type      = 'html' (identical to xml)
    my $tx_config = _merge($self->{'_config'}, $config_override);
    my $tx = Text::Xslate->new(%{$tx_config});

    # merge configuration values into the template variable list
    my $user_config = ($self->config() && $self->config->get()) || {};
    $vars = _merge({ 'config' => $user_config }, $vars);

    return $tx->render($template, $vars);
}

sub mark_raw {
    my $self = ref($_[0]) && $_[0]->isa(__PACKAGE__) ?
        shift : (defined($_[0]) && $_[0] eq __PACKAGE__) ?
        bless({}, shift) : bless({}, __PACKAGE__);
    return Text::Xslate::mark_raw(@_);
}

sub unmark_raw {
    my $self = ref($_[0]) && $_[0]->isa(__PACKAGE__) ?
        shift : (defined($_[0]) && $_[0] eq __PACKAGE__) ?
        bless({}, shift) : bless({}, __PACKAGE__);
    return Text::Xslate::unmark_raw(@_);
}

sub html_escape {
    my $self = ref($_[0]) && $_[0]->isa(__PACKAGE__) ?
        shift : (defined($_[0]) && $_[0] eq __PACKAGE__) ?
        bless({}, shift) : bless({}, __PACKAGE__);
    return Text::Xslate::html_escape(@_);
}

sub uri_escape {
    my $self = ref($_[0]) && $_[0]->isa(__PACKAGE__) ?
        shift : (defined($_[0]) && $_[0] eq __PACKAGE__) ?
        bless({}, shift) : bless({}, __PACKAGE__);
    return Text::Xslate::uri_escape(@_);
}

# stolen from Hash::Merge::Simple
sub _merge {
    my ($left, @right) = @_;

    return $left unless @right;
    return _merge($left, _merge(@right)) if @right > 1;

    my ($right) = @right;
    my %merged = %{$left};

    for my $key (keys %{$right}) {
        my ($hr, $hl) = map { ref($_->{$key}) eq "HASH" } $right, $left;

        if ($hr and $hl) {
            $merged{$key} = _merge($left->{$key}, $right->{$key});
        } else {
            $merged{$key} = $right->{$key};
        }
    }

    return \%merged;
}

1;

=head1 NAME

Prancer::Plugin::Xslate

=head1 SYNOPSIS

This plugin provides access to the L<Text::Xslate> templating engine for your
L<Prancer> application and exports a keyword to access the configured engine.

This template plugin supports setting the basic configuration in your Prancer
application's configuration file. You can also configure all options at runtime
using arguments to C<render>.

To set a configuration in your application's configuration file, begin the
configuration block with C<template> and put all options underneath that. For
example:

    template:
        cache_dir: /path/to/cache
        verbose: 2

Any option for Text::Xslate whose value can be expressed in a configuration
file can be put into your application's configuration. Then using the template
engine is as simple as this:

    use Prancer::Plugin::Xslate qw(render);

    Prancer::Plugin::Xslate->load();

    print render("foobar.tx", \%vars);

However, there are some configuration options that cannot be expressed in
configuration files, especially the C<functions> option. There are two
additional ways to handle that. The first way is to pass them to the template
plugin when loading it, like this:

    Prancer::Plugin::Xslate->load({
        'function' => {
            'encode_json' => sub {
                return JSON::encode_json(@_);
            }
        }
    });

The second way is to the optional third argument to C<render>, like this:

    print render("foobar.tx", \%vars, {
        'function' => {
            'md5_hex' => sub {
                return Digest::MD5::md5_hex(@_);
            }
        }
    });

Options passed when initializing the template plugin will override options
configured in the configuration file. Options passed when calling C<render>
will override options passed when initializing the template plugin. This is
the way you might go about adding support for functions and methods.

=head1 METHODS

=over

=item path

This will set the C<path> option for Text::Xslate to anything that Text::Xslate
suports. Each call to this method will overwrite whatever the previous template
path was. For example:

    # sets template path to just /path/to/templates
    $plugin->path('/path/to/templates');

    # blows away /path/to/templates set previously and sets it to this arrayref
    $plugin->path([ '/path/to/global-templates', '/path/to/local-templates' ]);

    # blows away the arrayref set previously and sets it to this hashref
    $plugin->path({
        'foo.tx' => '<html><body><: $foo :><br/></body></html>',
        'bar.tx' => 'Hello, <: $bar :>.',
    });

=item mark_raw, unmark_raw, html_escape, uri_escape

Proxies access to the static functions of the same name provided in
L<Text::Xslate>. These can all be called statically or an instance of the
plugin and all will work just fine. All of these can also be exported on
demand. For more information on how to use these functions, read the
Text::Xslate documentation.

=back

=head1 COPYRIGHT

Copyright 2014, 2015 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over

=item

L<Prancer>

=item

L<Text::Xslate>

=back

=cut
