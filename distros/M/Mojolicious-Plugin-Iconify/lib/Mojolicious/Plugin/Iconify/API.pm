package Mojolicious::Plugin::Iconify::API;
use Mojo::Base 'Mojolicious::Plugin';

use Carp;

use Mojo::File qw(path);
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Cache;

use constant DEBUG => $ENV{MOJO_ICONIFY_DEBUG} || 0;

use constant SVG_ROOT => '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
                               preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24"
                               style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);"></svg>';

our $VERSION = '1.20';

sub register {

    my ( $self, $app, $config ) = @_;

    # Config
    my $prefix = $config->{route} // $app->routes->any('/iconify');
    $prefix->to( return_to => $config->{return_to} // '/' );

    my $collections_dir  = $config->{collections} // Carp::croak 'collections is required';
    my $collections_path = path $collections_dir;

    my $collections = {};

    my $cache = Mojo::Cache->new;

    foreach my $file ( $collections_path->list->each ) {
        next if ( !$file =~ /.json/ );
        $collections->{ $file->basename('.json') } = $file;
    }

    # Helpers

    $app->helper(
        'iconify_api_collection' => sub {

            my ( $self, $collection ) = @_;

            return $cache->get($collection) if ( $cache->get($collection) );

            return if ( !defined $collections->{$collection} );

            my $collection_data = decode_json $collections->{$collection}->slurp;
            $cache->set( $collection => $collection_data );

            $self->app->log->debug("[Iconify] Loaded '$collection' collection") if DEBUG;

            return $collection_data;
        }
    );

    $app->helper( 'iconify_api_js'              => \&_iconify_api_js );
    $app->helper( 'iconify_api_collections'     => sub { sort keys %{$collections} } );
    $app->helper( 'iconify_api_collection_info' => sub { shift->iconify_api_collection(shift)->{'info'} } );

    $app->helper( 'iconify_svg_icon_url' => \&_iconify_svg_icon_url );
    $app->helper( 'svg_icon_url'         => \&_iconify_svg_icon_url );

    $app->helper( 'iconify_svg_icon' => \&_iconify_svg_icon );
    $app->helper( 'svg_icon'         => \&_iconify_svg_icon );

    # Routes
    $prefix->get( '/' => sub { shift->reply->not_found } )->name('iconify_api');

    $prefix->get( '/:prefix' => \&_iconify_api => [ format => [ 'js', 'json' ] ] )->name('iconify_api_collection');
    $prefix->get( '/:prefix/:icon' => \&_iconify_api => [ format => 'svg' ] )->name('iconify_api_icon');

}

sub _iconify_api {

    my $c = shift;

    my $params = $c->req->query_params->to_hash;

    my $prefix = $c->param('prefix');
    my $icon   = $c->param('icon');

    my @collections = $c->iconify_api_collections;

    return $c->reply->not_found if ( !$prefix );

    if ( !grep /$prefix/, @collections ) {
        return $c->reply->not_found;
    }

    my $collection = $c->iconify_api_collection($prefix);

    # Iconify API
    if ( $c->accepts( 'js', 'json' ) ) {

        if ( !defined( $params->{icons} ) ) {
            return $c->reply->not_found;
        }

        my $icons = delete $params->{icons} || '';
        my @icons = split /,/, $icons;

        my $iconify = {
            'prefix'  => $prefix,
            'icons'   => {},
            'aliases' => {},
        };

        foreach my $icon (@icons) {

            if ( defined $collection->{aliases}->{$icon} ) {
                $iconify->{aliases}->{$icon} = $collection->{aliases}->{$icon};
                $icon = $collection->{aliases}->{$icon}->{parent};
            }

            next if ( !defined $collection->{icons}->{$icon} );

            my $icon_data = $collection->{icons}->{$icon};

            $iconify->{icons}->{$icon} = $icon_data;

            if ( defined $params->{width} ) {
                $iconify->{icons}->{$icon}->{width} = $params->{width};
            }
            if ( defined $params->{height} ) {
                $iconify->{icons}->{$icon}->{height} = $params->{heigth};
            }

        }

        my $properties = [ 'width', 'height', 'top', 'left', 'inlineHeight', 'inlineTop', 'verticalAlign' ];

        foreach my $property ( @{$properties} ) {
            if ( defined $collection->{$property} ) {
                $iconify->{$property} = $collection->{$property};
            }
        }

        my $callback = 'SimpleSVG._loaderCallback';

        if ( defined $params->{callback} ) {
            if ( $params->{callback} !~ /^[a-z0-9_.]+$/ ) {
                return $c->render( text => 'Bad Request', status => 400 );
            }
            $callback = $params->{callback};
        }

        my $content = $callback . "(" . encode_json($iconify) . ");";

        return $c->respond_to(
            json => { json => $iconify },
            js   => { text => $content }
        );

    }

    # Single icon (eg. /iconify/mdi/account.svg)
    if ( $c->accepts('svg') ) {

        if ( defined $collection->{aliases}->{$icon} ) {
            $icon = $collection->{aliases}->{$icon}->{parent};
        }

        if ( !defined $collection->{icons}->{$icon} ) {
            return $c->reply->not_found;
        }

        my $width  = '1em';
        my $height = '1em';
        my $fill   = undef;

        if ( $params->{width} ) {
            $width  = $params->{width};
            $height = $params->{width};
        }

        if ( $params->{height} ) {
            $width  = $params->{height};
            $height = $params->{height};
        }

        # TODO add support for #hex color
        if ( $params->{color} ) {
            $fill = $params->{color};
        }

        # TODO add "rotate" support

        my $body = $collection->{icons}->{$icon}->{body};

        my $dom = Mojo::DOM->new->xml(1)->parse(SVG_ROOT);

        $dom->at('svg')->append_content($body);
        $dom->at('svg')->attr( width => $width, height => $height );
        $dom->at('path')->attr( fill => $fill ) if ($fill);

        return $c->render( text => $dom, format => 'svg' );

    }

    return $c->reply->not_found;

}

sub _iconify_api_js {

    my $c = shift;

    my $api_url    = $c->url_for('iconify_api');
    my $api_script = <<"EOF";

if (typeof Iconify.setConfig === 'function') {
    Iconify.setConfig('defaultAPI', '$api_url/{prefix}.js?icons={icons}');
} else {
    Iconify.addAPIProvider('', { resources: ['$api_url'] });
}

EOF

    return _tag( 'script', type => 'text/javascript', $api_script )->html_unescape;

}

sub _iconify_svg_icon_url {
    my ( $c, $icon ) = @_;
    return if ( !$icon );
    return $c->url_for('iconify_api') . "/$icon";
}

sub _iconify_svg_icon {

    my ( $c, $icon ) = @_;

    return if ( !$icon );

    my $prefix = undef;

    ( $prefix, $icon ) = split /:/, $icon;

    my @collections = $c->iconify_api_collections;

    return if ( !$prefix );
    return if ( !grep /$prefix/, @collections );

    my $collection = $c->iconify_api_collection($prefix);

    if ( defined $collection->{aliases}->{$icon} ) {
        $icon = $collection->{aliases}->{$icon}->{parent};
    }

    if ( !defined $collection->{icons}->{$icon} ) {
        return;
    }

    my $body   = $collection->{icons}->{$icon}->{body};
    my $width  = '1em';
    my $height = '1em';

    my $dom = Mojo::DOM->new->xml(1)->parse(SVG_ROOT);
    $dom->at('svg')->attr( width => $width, height => $height );

    $dom->at('svg')->append_content($body);
    return $dom;

}

sub _tag { Mojo::ByteStream->new( Mojo::DOM::HTML::tag_to_html(@_) ) }

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Iconify::API - Iconify API helpers.


=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Iconify::API', { collections => '/path-of/iconify-collections/json' });

  # Mojolicious::Lite
  plugin 'Iconify' => { collections => '/path-of/iconify-collections-json' };


=head1 DESCRIPTION

L<Mojolicious::Plugin::Iconify> is a L<Mojolicious> plugin to add Iconify support in your Mojolicious application.


=head1 HELPERS

L<Mojolicious::Plugin::Iconify> implements the following helpers.

=head2 iconify_api_js

  %= iconify_api_js

Generate C<script> tag for add Iconify API support in your web page.

=head2 iconify_api_collections

Return the list of Iconify icon collections.

=head2 iconify_api_collection

Return Iconify collection data.

=head2 iconify_api_collection_info

Return Iconify collection info.

=head2 iconify_svg_icon_url

Return SVG icon URL.

    <img src="<%== iconify_svg_icon_url 'logos:perl' %>" width=16 height=16>

B<Note>: You can use C<svg_icon_url> alias.


=head2 iconify_svg_icon

Return L<Mojo::DOM> instance of SVG icon.

    <%== iconify_svg_icon 'logos:perl' %>

B<Note>: You can use C<svg_icon> alias.


=head1 METHODS

L<Mojolicious::Plugin::Iconify> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new, { collections => '/path-of/iconify-collections/json' });

Register helpers in L<Mojolicious> application.


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<https://iconify.design/docs/>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify>

    git clone https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify.git


=head1 AUTHORS

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020-2021, Giuseppe Di Terlizzi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

__DATA__

@@ iconify_api.js.ep

if (typeof Iconify.setConfig === 'function') {
    Iconify.setConfig('defaultAPI', '<%= url_for('iconify_api') %>/{prefix}.js?icons={icons}');
} else {
    Iconify.addAPIProvider('', { resources: ['<%= url_for('iconify_api') %>'] });
}
