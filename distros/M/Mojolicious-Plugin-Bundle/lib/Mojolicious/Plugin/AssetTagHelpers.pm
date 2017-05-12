package Mojolicious::Plugin::AssetTagHelpers;

BEGIN {
    $Mojolicious::Plugin::AssetTagHelpers::VERSION = '0.004';
}

use strict;

# Other modules:
use base qw/Mojolicious::Plugin/;
use Mojo::ByteStream;
use Regexp::Common qw/URI/;
use Mojo::UserAgent;
use HTTP::Date;
use File::stat;
use File::Spec::Functions;
use File::Basename;

# Module implementation
#

__PACKAGE__->attr('asset_dir');
__PACKAGE__->attr('asset_host');
__PACKAGE__->attr('relative_url_root');
__PACKAGE__->attr( 'javascript_dir' => '/javascripts' );
__PACKAGE__->attr( 'stylesheet_dir' => '/stylesheets' );
__PACKAGE__->attr( 'image_dir'      => '/images' );
__PACKAGE__->attr( 'javascript_ext' => '.js' );
__PACKAGE__->attr( 'stylesheet_ext' => '.css' );
__PACKAGE__->attr(
    'image_options' => sub { [qw/width height class id border/] } );
__PACKAGE__->attr('app');
__PACKAGE__->attr( 'true' => 1 );

sub register {
    my ( $self, $app, $conf ) = @_;
    $self->asset_dir( $app->static->root );
    $self->app($app);
    if ( my $url = $self->compute_relative_url( @_[ 1, -1 ] ) ) {
        $self->relative_url_root($url);
        $app->log->debug("relative url root: $url");

# -- in case of non-default value strip off the name before serving the assets
        $app->static->root($url);
    }
    if ( my $host = $self->compute_asset_host( @_[ 1, -1 ] ) ) {
        $self->asset_host($host);
    }

    # -- image tag
    $app->helper(
        image_tag => sub {
            my ( $c, $name, %options ) = @_;
            my $tags;
            if (%options) {
                if ( defined $options{size} ) {
                    $tags
                        = qq/height="$options{size}" width="$options{size}"/;
                }
                if ( defined $options{alt} ) {
                    $tags .= qq/alt="$options{alt}"/;
                }
                for my $opt_name ( @{ $self->image_options } ) {
                    $tags .= qq/ $opt_name="$options{$opt_name}"/
                        if defined $options{$opt_name};
                }
            }
            else {
                my $alt_name = $self->compute_alt_name($name);
                $tags .= qq/alt="$alt_name"/;
            }

            my $source = $self->compute_image_path( $name, $self->true );
            return Mojo::ByteStream->new(qq{<img src="$source" $tags/>});
        }
    );

    # -- javascript tag
    $app->helper(
        javascript_include_tag => sub {
            my ( $c, $name ) = @_;
            my $source = $self->compute_javascript_path( $name, $self->true );
            return Mojo::ByteStream->new(
                qq{<script src="$source" type="text/javascript"></script>});
        }
    );

    # -- stylesheet tag
    $app->helper(
        stylesheet_link_tag => sub {
            my ( $c, $name, %option ) = @_;
            my $source = $self->compute_stylesheet_path( $name, $self->true );
            my $media
                = $option{media}
                ? qq{media="$option{media}}
                : qq{media="screen"};

            return Mojo::ByteStream->new(
                qq{<link href="$source" $media rel="stylesheet" type="text/css" />}
            );
        }
    );

    $app->helper(
        'stylesheet_path' => sub {
            my ( $c, $path ) = @_;
            return Mojo::ByteStream->new(
                $self->compute_stylesheet_path($path) );
        }
    );

    $app->helper(
        'javascript_path' => sub {
            my ( $c, $path ) = @_;
            return Mojo::ByteStream->new(
                $self->compute_javascript_path($path) );
        }
    );

    $app->helper(
        'image_path' => sub {
            my ( $c, $path ) = @_;
            return Mojo::ByteStream->new( $self->compute_image_path($path) );
        }
    );
}

sub compute_relative_url {
    my ( $self, $app, $conf ) = @_;
    my $url;
    if ( $app->can('config') and defined $app->config->{relative_url_root} ) {
        $url = $app->config->{relative_url_root};
    }

    if ( defined $conf and defined $conf->{relative_url_root} ) {
        $url = $conf->{relative_url_root};
    }
    $url;
}

sub compute_asset_host {
    my ( $self, $app, $conf ) = @_;
    my $host;
    if ( $app->can('config') and defined $app->config->{asset_host} ) {
        $host = $app->config->{asset_host};
    }

    if ( defined $conf and defined $conf->{asset_host} ) {
        $host = $conf->{asset_host};
    }
    $host;
}

sub compute_alt_name {
    my ( $self, $name ) = @_;
    my $img_regexp = qr/^([^.]+)\.(jpg|png|gif)$/;
    if ( $name =~ $RE{URI}{HTTP} ) {
        my $img_name = basename $name;
        return ucfirst $1 if $img_name =~ $img_regexp;
        return ucfirst $img_name;
    }

    return ucfirst $1 if $name =~ $img_regexp;
    return ucfirst $name;
}

sub compute_asset_id {
    my ( $self, $file ) = @_;
    if ( $file =~ $RE{URI}{HTTP} ) {
        my $tx = Mojo::UserAgent->new->head($file);
        if ( my $res = $tx->success ) {
            my $asset_id = str2time( $res->headers->last_modified );
            return $asset_id;
        }
        else {
            return;
        }
    }

    my $full_path = catfile( $self->asset_dir, $file );
    if ( -e $full_path ) {
        my $st = stat($full_path);
        return $st->mtime;
    }
}

sub compute_image_path {
    my ( $self, $name, $default ) = @_;
    my $image_path
        = $default
        ? $self->compute_asset_path( catfile( $self->image_dir, $name ) )
        : $self->compute_asset_path($name);
    my $asset_id
        = $default
        ? $self->compute_asset_id( catfile( $self->image_dir, $name ) )
        : $self->compute_asset_id($name);

    return $image_path . '?' . $asset_id if $asset_id;
    $image_path;
}

sub compute_javascript_path {
    my ( $self, $name, $default ) = @_;
    my ( $js_path, $asset_id );
    if ( $name !~ $RE{URI}{HTTP} ) {
        $name = $name . $self->javascript_ext if $name !~ /\.js$/;
    }

    $js_path
        = $default
        ? $self->compute_asset_path( catfile( $self->javascript_dir, $name ) )
        : $self->compute_asset_path($name);
    $asset_id
        = $default
        ? $self->compute_asset_id( catfile( $self->javascript_dir, $name ) )
        : $self->compute_asset_id($name);

    return $js_path . '?' . $asset_id if $asset_id;
    $js_path;
}

sub compute_stylesheet_path {
    my ( $self, $name, $default ) = @_;
    my ( $css_path, $asset_id );
    if ( $name !~ $RE{URI}{HTTP} ) {
        $name = $name . $self->stylesheet_ext if $name !~ /\.css$/;
    }

    $css_path
        = $default
        ? $self->compute_asset_path( catfile( $self->stylesheet_dir, $name ) )
        : $self->compute_asset_path($name);

    $asset_id
        = $default
        ? $self->compute_asset_id( catfile( $self->stylesheet_dir, $name ) )
        : $self->compute_asset_id($name);

    return $css_path . '?' . $asset_id if $asset_id;
    $css_path;
}

sub compute_asset_path {
    my ( $self, $file ) = @_;
    return $file if $file =~ $RE{URI}{HTTP};    ## -- full http url
    my $path
        = $self->relative_url_root
        ? $self->relative_url_root . $file
        : $file;
    $path = $self->asset_host ? $self->asset_host . '/' . $path : $path;
    $path;
}

1;    # Magic true value required at end of module

=pod

=head1 NAME

Mojolicious::Plugin::AssetTagHelpers

=head1 VERSION

version 0.004

=head1 NAME

B<Mojolicious::Plugin::AssetTagHelpers> - [Tag helpers for javascripts,images and
stylesheets]

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
