package Statocles::Plugin::LinkCheck;
our $VERSION = '0.098';
# ABSTRACT: Check links and images for validity during build

use Statocles::Base 'Class';
with 'Statocles::Plugin';
use Mojo::Util qw( url_escape url_unescape );

#pod =attr fatal
#pod
#pod If set to true, and there are any broken links, the plugin will also call
#pod C<die()> after printing the problems. Defaults to false.
#pod
#pod =cut

has fatal => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

#pod =attr ignore
#pod
#pod An array of URL patterns to ignore. These are interpreted as regular expressions,
#pod and are anchored to the beginning of the URL.
#pod
#pod For example:
#pod
#pod     /broken     will match "/broken.html" "/broken/page.html" but not "/page/broken"
#pod     .*/broken   will match "/broken.html" "/broken/page.html" and "/page/broken"
#pod
#pod =cut

has ignore => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
);

#pod =method check_pages
#pod
#pod     $plugin->check_pages( $event );
#pod
#pod Check the pages inside the given
#pod L<Statocles::Event::Pages|Statocles::Event::Pages> event.
#pod
#pod =cut

sub check_pages {
    my ( $self, $event ) = @_;

    my %page_paths = ();
    my %links = ();
    my %empty = (); # Pages with empty links
    for my $page ( @{ $event->pages } ) {
        $page_paths{ url_unescape $page->path } = 1;
        if ( $page->DOES( 'Statocles::Page::Document' ) ) {
            my $dom = $page->dom;

            for my $attr ( qw( src href ) ) {
                for my $el ( $dom->find( "[$attr]" )->each ) {
                    my $url = $el->attr( $attr );

                    if ( !$url ) {
                        push @{ $empty{ $page->path } }, $el;
                    }

                    $url =~ s{#.*$}{};
                    next unless $url; # Skip checking fragment-internal links for now
                    next if $url =~ m{^(?:[a-z][a-z0-9+.-]*):}i;
                    next if $url =~ m{^//};
                    if ( $url !~ m{^/} ) {
                        my $clone = $page->path->clone;
                        pop @$clone;
                        $url = join '/', $clone, $url;
                    }

                    # Fix ".." and ".". Path::Tiny->canonpath can't do
                    # this for us because these paths do not exist on
                    # the filesystem
                    $url =~ s{/[^/]+/[.][.]/}{/}g; # Fix ".." to refer to parent
                    $url =~ s{/[.]/}{/}g; # Fix "." to refer to self

                    $links{ url_unescape $url }{ url_unescape $page->path }++;

                }
            }
        }
    }

    my @missing; # Array of arrayrefs of [ link_url, page_path ]
    for my $link_url ( keys %links ) {
        $link_url .= 'index.html' if $link_url =~ m{/$};
        next if $page_paths{ $link_url } || $page_paths{ "$link_url/index.html" };
        next if grep { $link_url =~ /^$_/ } @{ $self->ignore };
        push @missing, [ $link_url, $_ ] for keys %{ $links{ $link_url } };
    }

    for my $page_url ( keys %empty ) {
        push @missing, map { [ '', $page_url, $_ ] } @{ $empty{ $page_url } };
    }

    if ( @missing ) {
        # Sort by page url and then missing link url
        for my $m ( sort { $a->[1] cmp $b->[1] || $a->[0] cmp $b->[0] } @missing ) {
            my $msg = $m->[0] ? sprintf( q{'%s' not found}, $m->[0] )
                    : sprintf( q{Link with text "%s" has no destination}, $m->[2]->text )
                    ;
            $event->emitter->log->warn( "URL broken on $m->[1]: $msg" );
        }

        die 'Link check failed!' if $self->fatal;
    }
}

#pod =method register
#pod
#pod Register this plugin to install its event handlers. Called automatically.
#pod
#pod =cut

sub register {
    my ( $self, $site ) = @_;
    $site->on( build => sub { $self->check_pages( @_ ) } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Plugin::LinkCheck - Check links and images for validity during build

=head1 VERSION

version 0.098

=head1 SYNOPSIS

    # site.yml
    site:
        class: Statocles::Site
        args:
            plugins:
                link_check:
                    $class: Statocles::Plugin::LinkCheck

=head1 DESCRIPTION

This plugin checks all of the links and images to ensure they exist. If something
is missing, this plugin will write a warning to the screen. If fatal is set to true,
it will also call C<die()> afterwards.

=head1 ATTRIBUTES

=head2 fatal

If set to true, and there are any broken links, the plugin will also call
C<die()> after printing the problems. Defaults to false.

=head2 ignore

An array of URL patterns to ignore. These are interpreted as regular expressions,
and are anchored to the beginning of the URL.

For example:

    /broken     will match "/broken.html" "/broken/page.html" but not "/page/broken"
    .*/broken   will match "/broken.html" "/broken/page.html" and "/page/broken"

=head1 METHODS

=head2 check_pages

    $plugin->check_pages( $event );

Check the pages inside the given
L<Statocles::Event::Pages|Statocles::Event::Pages> event.

=head2 register

Register this plugin to install its event handlers. Called automatically.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
