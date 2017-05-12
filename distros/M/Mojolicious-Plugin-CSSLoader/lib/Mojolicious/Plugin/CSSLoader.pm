package Mojolicious::Plugin::CSSLoader;

# ABSTRACT: move css loading to the end of the document

use strict;
use warnings;

use parent 'Mojolicious::Plugin';

our $VERSION = 0.07;

sub register {
    my ($self, $app, $config) = @_;

    my $base  = $config->{base}  || '';
    my $media = $config->{media} || '';

    if ( $base and substr( $base, -1 ) ne '/' ) {
        $base .= '/';
    }

    $app->helper( css_load => sub {
        my $c = shift;

        if ( $_[1]->{check} ) {
            my $asset = $c->app->static->file(
                $_[1]->{no_base} ? $_[0] : "$base$_[0]"
            );

            return '' if !$asset;
        }

        push @{ $c->stash->{__CSSLOADERFILES__} }, [ @_ ];
    } );

    $app->hook( after_render => sub {
        my ($c, $content, $format) = @_;

        return if $format ne 'html';
        return if !$c->stash->{__CSSLOADERFILES__};

        my $load_css =
            join "\n", 
                map{
                    my ($file,$config) = @{ $_ };
                    my $local_base  = $config->{no_base} ? '' : $base;

                    $local_base  = $c->url_for( $local_base ) if $local_base;

                    my $local_media = "";

                    $local_media = ' media="' . $media . '"'           if $media;
                    $local_media = ' media="' . $config->{media} . '"' if $config->{media};

                    my $ie_start = '';
                    my $ie_end   = '';

                    if ( exists $config->{ie} ) {
                        my $start_extra = '';
                        my $end_extra   = '';
                        my $cmp         = '';
                        my $version     = '';

                        if ( !ref $config->{ie} && !$config->{ie} ) {
                            $start_extra = '<!-->';
                            $end_extra   = '<!--';
                            $cmp         = '!';
                        }
                        elsif( ref $config->{ie} ) {
                            my %map = qw/> gt >= gte < lt <= lte/;
                            (my $key, $version) = %{ $config->{ie} };
                            $cmp = $map{$key} || '';
                            $cmp .= ' ' if $cmp;
                        }

                        $ie_start = sprintf "<!-- [if %sIE %s]>%s",
                            $cmp,
                            $version,
                            $start_extra;

                        $ie_end = sprintf "%s<![endif]-->", $end_extra;
                    }

                    $config->{no_file} ? 
                         qq~$ie_start<style type="text/css">$file</style>$ie_end~ :
                         qq~$ie_start<link rel="stylesheet" href="$local_base$file"$local_media/>$ie_end~;
                }
                @{ $c->stash->{__CSSLOADERFILES__} || [] };

        return if !$load_css;

        ${$content} =~ s!(</head>)!$load_css$1! or ${$content} = $load_css . ${$content};
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::CSSLoader - move css loading to the end of the document

=head1 VERSION

version 0.07

=head1 SYNOPSIS

In your C<startup>:

    sub startup {
        my $self = shift;
  
        # do some Mojolicious stuff
        $self->plugin( 'CSSLoader' );

        # more Mojolicious stuff
    }

In your template:

    <% css_load('css_file.css') %>

=head1 HELPERS

This plugin adds a helper method to your web application:

=head2 css_load

This method requires at least one parameter: The path to the JavaScript file to load.
An optional second parameter is the configuration. You can switch off the I<base> for
this CSS file this way:

  # <link rel="stylesheet" href="$base/css_file.css"/>
  <% css_load('css_file.css') %>
  
  # <link rel="stylesheet" href="http://domain/css_file.css"/>
  <% css_load('http://domain/css_file.css', {no_base => 1});
  
  # load css file only in Internet Explorer
  # <!-- [if IE]> <link rel="stylesheet" href="http://domain/css_file.css"/> <![endif] -->
  <% css_load('css_file.css', {ie => 1});
  
  # load css file except in Internet Explorer
  # <!-- [if !IE]><!--> <link rel="stylesheet" href="http://domain/css_file.css"/> <!--<![endif] -->
  <% css_load('css_file.css', {ie => 0});
  
  # load css file in Internet Explorer greater version 7
  # <!-- [if gt IE 7]> <link rel="stylesheet" href="http://domain/css_file.css"/> <![endif] -->
  <% css_load('css_file.css', {ie => { '>' => 7 } });
  
  # allowed ie settings: >, >=, <, <=, ==

=head1 HOOKS

When you use this module, a hook for I<after_render> is installed. That hook inserts
the C<< <link> >> tag at the end of the C<< <head> >> part or at the start of the
document.

=head1 METHODS

=head2 register

Called when registering the plugin. On creation, the plugin accepts a hashref to configure the plugin.

    # load plugin, alerts are dismissable by default
    $self->plugin( 'CSSLoader' );

=head3 Configuration

    $self->plugin( 'CSSLoader' => {
        base  => 'http://domain/css',  # base for all CSS files
        media => 'screen',             # media setting (default: none)
    });

=head1 NOTES

This plugin uses the I<stash> key C<__CSSLOADERFILES__>, so you should avoid using
this stash key for your own purposes.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
