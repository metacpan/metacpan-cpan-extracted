package Mojolicious::Plugin::Sprite;

use warnings;
use strict;
use Mojo::Base 'Mojolicious::Plugin';
use XML::LibXML;

use constant DEFAULT_CONFIG_FILE => 'sprite.xml';
use constant DEFAULT_CSS_URL     => '/css/sprite.css';

our $VERSION = '0.01';

our $parser  = XML::LibXML->new();

sub register {
    my ( $self, $app, $conf ) = @_;
    $conf ||= {};

    my $config  = $conf->{config}  || DEFAULT_CONFIG_FILE;
    my $css_url = $conf->{css_url} || DEFAULT_CSS_URL;

    my $sprite_images = ref($config) eq 'HASH'
        ? $config
        : $self->_parse_xml_config($app, $config)
    ;

    unless (scalar %$sprite_images) {
        $app->log->warn( __PACKAGE__ .": Plugin not activated.");
    }

    $app->hook(after_dispatch => sub {
        my ($c) = @_;
        my $res = $c->res;

        # Only successful response
        return if $res->code !~ m/^2/;

        # Only html response
        return unless $res->headers->content_type;
        return if $res->headers->content_type !~ /html/;
        return if $res->body !~ /^\s*</;

        # Skip if "?no_sprites=1" and mode is 'develompent'
        return if $app->mode eq 'development' && $c->param('no_sprites');

        my $dom = $parser->parse_html_string($res->body);

        # Replace "img" tags
        foreach my $img ( $dom->findnodes('//img') ) {
            # Skip if "src" is empty
            my $src = $img->getAttribute('src') or last;

            # Remove first "/"
            $src =~ s/^\///;

            # Skip if not found
            my $selector = $sprite_images->{$src} or last;

            # Change node name
            $img->setNodeName('span');

            # Add single space
            $img->appendText(' ');

            # Add 'class' and 'id' attribute
            my @class = grep { $_ } ($img->getAttribute('class'), 'spr');
            if ( substr($selector, 0, 1) eq '.' ) {
                push @class, substr($selector, 1);
            }
            else {
                $img->setAttribute( 'id', substr($selector, 1) );
            }
            $img->setAttribute( 'class', join(' ', @class) );

            # Remove unneeded attributes
            $img->removeAttribute($_) for qw(src width height alt);
        }

        # Add 'sprite.css'
        foreach my $head ( $dom->findnodes('/html/head') ) {
            my $style = $head->addNewChild(undef, 'link');
            $style->setAttribute('rel', 'stylesheet');
            $style->setAttribute('href', $css_url);
        }

        $res->body( $dom->toStringHTML() );
    });
}

sub _parse_xml_config {
    my ($self, $app, $config) = @_;

    unless (-e $config) {
        $app->log->warn( __PACKAGE__ .": Config file '$config' does not exists.");
        return {};
    }

    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file($config);

    my %sprite_images = map {
        $_->getAttribute('image') => $_->getAttribute('selector')
    } $dom->findnodes('/root/sprite/image');

    return \%sprite_images;
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Sprite - let you easy introduce and maintain CSS sprites in your web-site.

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Sprite');

    # Mojolicious::Lite
    plugin 'Sprite';

    # Custom options
    plugin 'Sprite' => {
        config  => "sprite.xml",
        css_url => "/css/sprite.css"
    };

=head1 DESCRIPTION

This plugin parses HTML out and converts images into sprites according to rules of configuration file,

In other words, HTML tag <img src="icons/img1.gif"> will be converted to <span class="spr spr-icons-img1"> and will be used CSS like:

    .spr {
        display: -moz-inline-stack;
        display: inline-block;
        zoom: 1;
        *display: inline;
        background-repeat: no-repeat;
    }
    .spr-icons-img1,.spr-icons-img2 {
        background-image: url('/sprites/sprite.png?1376352016') !important;
    }
    .spr-icons-img1 {
        background-position: 0px 0px !important;
        width:32px;
        height:32px;
    }
    .spr-icons-img2 {
        background-position: 0px -32px !important;
        width:48px;
        height:48px;
    }

For generating sprites you can use L<CSS::SpriteBuilder> module.

=head1 METHODS

L<Mojolicious::Plugin::Sprite> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 CONFIGURATION

The following options can be set for the plugin:

=over 4

=item * B<config> [ = "sprite.xml" ]

Specify XML config file like:

    <root>
      <sprite src="/sprites/sprite.png?1376352016">
        <image width="32" selector=".spr-icons-small-add" x="0" height="32" image="icons/small/Add.png" y="0" is_background="0" repeat="no"/>
        <image width="48" selector=".spr-icons-medium-cd" x="0" height="48" image="icons/medium/CD.png" y="32" is_background="0" repeat="no"/>
        ...
      </sprite>
    </root>

* This file can be generated by L<CSS::SpriteBuilder>.

Or hash like:

    {
        "icons/small/Add.png" => ".spr-icons-small-add",
        "icons/medium/CD.png" => ".spr-icons-medium-cd",
        ...
    }

=item * B<css_url> [ = "/css/sprite.css" ]

Specify url for CSS file.

* This file can be generated by L<CSS::SpriteBuilder>.

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<CSS::SpriteBuilder>.

=head1 AUTHOR

Yuriy Ustushenko, E<lt>yoreek@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Yuriy Ustushenko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
