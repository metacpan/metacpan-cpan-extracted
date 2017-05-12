package Mojolicious::Plugin::ContextResources;
use Mojo::Base 'Mojolicious::Plugin';
use File::Spec::Functions   qw(catfile);

our $VERSION = '0.01';

# Get current context path
sub _context($) {
    my ($c) = @_;

    my @path;
    my $stash = $c->stash;
    if( $stash->{'controller'} && $stash->{'action'} ) {
        push @path, split m{[/\-]}, $stash->{'controller'};
        push @path, $stash->{'action'};
    } elsif( $stash->{'mojo.captures'}{'template'} ) {
        push @path, $stash->{'mojo.captures'}{'template'};
    }
    return @path;
}

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    # Path
    $conf->{home}       //= $app->home;
    $conf->{public}     //= '/public';
    $conf->{js}         //= '/js';
    $conf->{css}        //= '/css';

    $app->helper(url_context_stylesheet => sub {
        my ($c) = @_;

        my @path = _context( $c );
        return undef unless @path;

        my $file = catfile( $conf->{css}, @path ) . '.css';
        my $path = $conf->{home}->rel_file(catfile $conf->{public}, $file);
        return undef unless -f $path;

        return Mojo::URL->new( $file );
    });

    $app->helper(url_context_javascript => sub {
        my ($c) = @_;

        my @path = _context( $c );
        return undef unless @path;

        my $file = catfile( $conf->{js}, @path ) . '.js';
        my $path = $conf->{home}->rel_file(catfile $conf->{public}, $file);
        return undef unless -f $path;

        return Mojo::URL->new( $file );
    });

    $app->helper(stylesheet_context => sub {
        my ($c) = @_;

        my $url = $c->url_context_stylesheet;
        return Mojo::ByteStream->new('') unless $url;

        return Mojo::ByteStream->new( $c->stylesheet( $url ));
    });

    $app->helper(javascript_context => sub {
        my ($c) = @_;

        my $url = $c->url_context_javascript;
        return Mojo::ByteStream->new('') unless $url;

        return Mojo::ByteStream->new( $c->javascript( $url ));
    });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ContextResources - Mojolicious plugin for automatic
use javascript and stylesheet like a templates, by controller/action path.

=head1 SYNOPSIS

    # Automatically add link to
    # public/css/foo/bar.css and public/js/foo/bar.js
    # if exists

    # Mojolicious
    sub startup {
        my ($self) = @_;
        $self->plugin('ContextResources');
        $self->routes->get("/test")->to('foo#bar');
    }

    # Mojolicious::Lite
    plugin 'ContextResources';
    get '/test' => {template => 'foo/bar'};

    __DATA__
    @@ foo/bar.html.ep
    % layout 'default';

    @@ layouts/default.html.ep
    <!DOCTYPE html>
    <html>
        <head>
            <title>Test</title>
            %= stylesheet_context;
        </head>
        <body>
            %= content
            <footer>
                %= javascript_context;
            </footer>
        </body>
    </html>

=head1 DESCRIPTION

L<Mojolicious::Plugin::ContextResources> use I<controller> and I<action>,
or I<template> for automatic add js and css if it present.

=head1 HELPERS

=head2 url_context_stylesheet

Get L<Mojo::URL> for current context stylesheet.

=head2 url_context_javascript

Get L<Mojo::URL> for current context javascript.

=head2 stylesheet_context

Like I<stylesheet> helper for for current context stylesheet.

=head2 javascript_context

Like I<javascript> helper for for current context javascript.

=head1 OPTIONS

=head2 home

Path to basic folder. Default from L<Mojo::Home>

=head2 public

Public folder. Default: F<public>.

=head2 css

CSS folder. Default: F<css>.

=head2 js

JS folder. Default: F<js>.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>,
L<Mojolicious::Plugin::UniqueTagHelpers>.

=cut
