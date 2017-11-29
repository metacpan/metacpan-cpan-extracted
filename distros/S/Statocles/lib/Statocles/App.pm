package Statocles::App;
our $VERSION = '0.087';
# ABSTRACT: Base role for Statocles applications

use Statocles::Base 'Role', 'Emitter';
use Statocles::Link;
requires 'pages';

#pod =attr site
#pod
#pod The site this app is part of.
#pod
#pod =cut

has site => (
    is => 'rw',
    isa => InstanceOf['Statocles::Site'],
);

#pod =attr data
#pod
#pod A hash of arbitrary data available to theme templates. This is a good place to
#pod put extra structured data like social network links or make easy customizations
#pod to themes like header image URLs.
#pod
#pod =cut

has data => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

#pod =attr url_root
#pod
#pod The URL root of this application. All pages from this app will be under this
#pod root. Use this to ensure two apps do not try to write the same path.
#pod
#pod =cut

has url_root => (
    is => 'ro',
    isa => Str,
    required => 1,
);

#pod =attr templates
#pod
#pod The templates to use for this application. A mapping of template names to
#pod template paths (relative to the theme root directory).
#pod
#pod Developers should get application templates using L<the C<template>
#pod method|/template>.
#pod
#pod =cut

has _templates => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
    init_arg => 'templates',
);

#pod =attr template_dir
#pod
#pod The directory (inside the theme directory) to use for this app's templates.
#pod
#pod =cut

has template_dir => (
    is => 'ro',
    isa => Str,
);

#pod =attr disable_content_template
#pod
#pod This disables processing the content in this application as a template.
#pod This can speed up processing when the content is not using template
#pod directives.
#pod
#pod This can be also set in the document
#pod (L<Statocles::Document/disable_content_template>), or for the entire site
#pod (L<Statocles::Site/disable_content_template>).
#pod
#pod =cut

has disable_content_template => (
    is => 'ro',
    isa => Bool,
    lazy => 1,
    default => 0,
    predicate => 'has_disable_content_template',
);

#pod =method pages
#pod
#pod     my @pages = $app->pages;
#pod
#pod Get the pages for this app. Must return a list of L<Statocles::Page> objects.
#pod
#pod =cut

around pages => sub {
    my ( $orig, $self, @args ) = @_;
    my @pages = $self->$orig( @args );

    # Add the url_root
    my $url_root = $self->url_root;
    for my $page ( @pages ) {
        my @url_attrs = qw( path );

        if ( $page->isa( 'Statocles::Page::List' ) ) {
            push @url_attrs, qw( next prev );
        }

        for my $attr ( @url_attrs ) {
            if ( $page->$attr && $page->$attr !~ /^$url_root/ ) {
                $page->$attr( join "/", $url_root, $page->$attr );
            }
        }
    }

    $self->emit( 'build' => class => 'Statocles::Event::Pages', pages => \@pages );

    return @pages;
};

#pod =method url
#pod
#pod     my $app_url = $app->url( $path );
#pod
#pod Get a URL to a page in this application. Prepends the app's L<url_root
#pod attribute|/url_root> if necessary. Strips "index.html" if possible.
#pod
#pod =cut

sub url {
    my ( $self, $url ) = @_;
    my $base = $self->url_root;
    $url =~ s{/index[.]html$}{/};

    # Remove the / from both sides of the join so we don't double up
    $base =~ s{/$}{};
    $url =~ s{^/}{};

    return join "/", $base, $url;
}

#pod =method link
#pod
#pod     my $link = $app->link( %args )
#pod
#pod Create a link to a page in this application. C<%args> are attributes to be
#pod given to L<Statocles::Link> constructor. The app's L<url_root
#pod attribute|/url_root> is prepended, if necessary.
#pod
#pod =cut

sub link {
    my ( $self, %args ) = @_;
    my $url_root = $self->url_root;
    if ( $args{href} !~ /^$url_root/ ) {
        $args{href} = $self->url( $args{href} );
    }
    return Statocles::Link->new( %args );
}

#pod =method template
#pod
#pod     my $template = $app->template( $tmpl_name );
#pod
#pod Get a L<template object|Statocles::Template> for the given template
#pod name. The default template is determined by the app's class name and the
#pod template name passed in.
#pod
#pod Applications should list the templates they have and describe what L<page
#pod class|Statocles::Page> they use.
#pod
#pod =cut

sub template {
    my ( $self, $name ) = @_;

    # Allow the site object to set the default layout
    if ( $name eq 'layout.html' && !$self->_templates->{ $name } ) {
        return $self->site->template( $name );
    }

    my $path    = $self->_templates->{ $name }
                ? $self->_templates->{ $name }
                : join "/", $self->template_dir, $name;

    return $self->site->theme->template( $path );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::App - Base role for Statocles applications

=head1 VERSION

version 0.087

=head1 SYNOPSIS

    package MyApp;
    use Statocles::Base 'Class';
    with 'Statocles::App';

    sub pages {
        return Statocles::Page::Content->new(
            path => '/index.html',
            content => 'Hello, World',
        );
    }

=head1 DESCRIPTION

A Statocles App creates a set of L<pages|Statocles::Pages> that can then be
written to the filesystem (or served directly, if desired).

Pages can be created from L<documents|Statocles::Documents> stored in a
L<store|Statocles::Store> (see L<Statocles::Page::Document>), files stored in a
store (see L<Statocles::Page::File>), lists of content (see
L<Statocles::Page::List>), or anything at all (see
L<Statocles::Page::Content>).

=head1 ATTRIBUTES

=head2 site

The site this app is part of.

=head2 data

A hash of arbitrary data available to theme templates. This is a good place to
put extra structured data like social network links or make easy customizations
to themes like header image URLs.

=head2 url_root

The URL root of this application. All pages from this app will be under this
root. Use this to ensure two apps do not try to write the same path.

=head2 templates

The templates to use for this application. A mapping of template names to
template paths (relative to the theme root directory).

Developers should get application templates using L<the C<template>
method|/template>.

=head2 template_dir

The directory (inside the theme directory) to use for this app's templates.

=head2 disable_content_template

This disables processing the content in this application as a template.
This can speed up processing when the content is not using template
directives.

This can be also set in the document
(L<Statocles::Document/disable_content_template>), or for the entire site
(L<Statocles::Site/disable_content_template>).

=head1 METHODS

=head2 pages

    my @pages = $app->pages;

Get the pages for this app. Must return a list of L<Statocles::Page> objects.

=head2 url

    my $app_url = $app->url( $path );

Get a URL to a page in this application. Prepends the app's L<url_root
attribute|/url_root> if necessary. Strips "index.html" if possible.

=head2 link

    my $link = $app->link( %args )

Create a link to a page in this application. C<%args> are attributes to be
given to L<Statocles::Link> constructor. The app's L<url_root
attribute|/url_root> is prepended, if necessary.

=head2 template

    my $template = $app->template( $tmpl_name );

Get a L<template object|Statocles::Template> for the given template
name. The default template is determined by the app's class name and the
template name passed in.

Applications should list the templates they have and describe what L<page
class|Statocles::Page> they use.

=head1 EVENTS

All apps by default expose the following events:

=head2 build

This event is fired after the app pages have been prepares and are ready to
be rendered. This event allows for modifying the pages before they are rendered.

The event will be a
L<Statocles::Event::Pages|Statocles::Event/Statocles::Event::Pages> object
containing all the pages prepared by the app.

=head1 INCLUDED APPS

These applications are included with the core Statocles distribution.

=over 4

=item L<Statocles::App::Blog>

=item L<Statocles::App::Basic>

=item L<Statocles::App::Static>

=item L<Statocles::App::Perldoc>

=back

=head1 SEE ALSO

=over 4

=item L<Statocles::Store>

=item L<Statocles::Page>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
