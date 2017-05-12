package Mojolicious::Plugin::UniqueTagHelpers;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util 'md5_sum';
use Encode qw(encode_utf8);

our $VERSION = '1.3';

sub _block {
    ref $_[0] eq 'CODE' ? $_[0]() :
    defined $_[0]       ? "$_[0]" :
                          ''
}

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};
    $conf->{max_key_length} //= 256;

    $app->helper(stylesheet_for => sub {
        my ($c, $name, $content) = @_;
        $name ||= 'content';

        my $hash = $c->stash->{'uniquetaghelpers.stylesheet'} ||= {};
        if( defined $content ) {
            $hash->{$name} ||= {};
            my $key = _block($content);
            $key    = md5_sum( encode_utf8($key) )
                if $conf->{max_key_length} < length $key;

            return $c->content( $name ) if exists $hash->{$name}{$key};
            $hash->{$name}{$key} = 1;

            $c->content_for( $name => $c->stylesheet($content) );
        }
        return $c->content( $name );
    });

    $app->helper(javascript_for => sub {
        my ($c, $name, $content) = @_;
        $name ||= 'content';

        my $hash = $c->stash->{'uniquetaghelpers.javascript'} ||= {};
        if( defined $content ) {
            $hash->{$name} ||= {};
            my $key = _block($content);
            $key    = md5_sum( encode_utf8($key) )
                if $conf->{max_key_length} < length $key;

            return $c->content( $name ) if exists $hash->{$name}{$key};
            $hash->{$name}{$key} = 1;

            $c->content_for( $name => $c->javascript($content) );
        }
        return $c->content( $name );
    });

    $app->helper(unique_for => sub {
        my ($c, $name, $content) = @_;
        $name ||= 'content';

        my $hash = $c->stash->{'uniquetaghelpers.unique'} ||= {};
        if( defined $content ) {
            $hash->{$name} ||= {};
            my $key = _block($content);
            $key    = md5_sum( encode_utf8($key) )
                if $conf->{max_key_length} < length $key;

            return $c->content( $name ) if exists $hash->{$name}{$key};
            $hash->{$name}{$key} = 1;

            $c->content_for( $name => $content );
        }
        return $c->content( $name );
    });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::UniqueTagHelpers - Mojolicious Plugin to use unique
javascript and stylesheet links.

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('UniqueTagHelpers');

  # Mojolicious::Lite
  plugin 'UniqueTagHelpers';

=head1 DESCRIPTION

L<Mojolicious::Plugin::UniqueTagHelpers> is a set of HTML tag helpers for
javascript and stylesheets, allowing multiple includes in templates.

=head1 OPTIONS

=head2 max_key_length

Maximum content length to use as keys. If content length exceeds this, MD5
will be used to make keys to reduce memory usage. Default: 256.

=head1 HELPERS

=head2 stylesheet_for

    @@ index.html.ep
    % layout 'default';
    % stylesheet_for 'header' => 'css/main.css';
    ...
    % include 'someblock'

    @@ someblock.html.ep
    ...
    % stylesheet_for 'header' => 'css/main.css';

    @@ layouts/default.html.ep
    <!DOCTYPE html>
    <html>
        <head>
            <title>MyApp</title>
            %= content_for 'header';
        </head>
        <body>
            <%= content %>
        </body>
    </html

This example generates only one link to F<css/main.css>:

    <!DOCTYPE html>
    <html>
        <head>
            <title>MyApp</title>
            <link href="css/main.css" rel="stylesheet" />
        </head>
        <body>
        </body>
    </html>

=head2 javascript_for

    @@ index.html.ep
    % layout 'default';
    % javascript_for 'footer' => 'js/main.js';
    ...
    % include 'someblock'

    @@ someblock.html.ep
    ...
    % javascript_for 'footer' => 'js/main.js';

    @@ layouts/default.html.ep
    <!DOCTYPE html>
    <html>
        <head>
            <title>MyApp</title>
        </head>
        <body>
            <%= content %>
            %= content_for 'footer';
        </body>
    </html

This example generates only one link to F<js/main.js>:

    <!DOCTYPE html>
    <html>
        <head>
            <title>MyApp</title>
        </head>
        <body>
            <script src="js/main.js"></script>
        </body>
    </html>

=head2 unique_for

    @@ index.html.ep
    % layout 'default';
    % unique_for 'footer' => begin;
        <div id="modal">...</div>
    % end

    ...

    % unique_for 'footer' => begin;
        <div id="modal">...</div>
    % end

    @@ layouts/default.html.ep
    <!DOCTYPE html>
    <html>
        <head>
            <title>MyApp</title>
        </head>
        <body>
            <%= content %>
            %= content_for 'footer';
        </body>
    </html

This example generates only one "modal" element:

    <!DOCTYPE html>
    <html>
        <head>
            <title>MyApp</title>
        </head>
        <body>
            <div id="modal">...</div>
        </body>
    </html>

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<Mojolicious::Plugin::TagHelpers>,
L<http://mojolicio.us>.

=cut
