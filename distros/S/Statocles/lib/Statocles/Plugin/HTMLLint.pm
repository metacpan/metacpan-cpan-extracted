package Statocles::Plugin::HTMLLint;
our $VERSION = '0.094';
# ABSTRACT: Check HTML for common errors and issues

use Statocles::Base 'Class';
with 'Statocles::Plugin';
BEGIN {
    eval { require HTML::Lint::Pluggable; HTML::Lint::Pluggable->VERSION( 0.06 ); 1 }
        or die "Error loading Statocles::Plugin::HTMLLint. To use this plugin, install HTML::Lint::Pluggable";
};

#pod =attr plugins
#pod
#pod The L<HTML::Lint::Pluggable> plugins to use. Defaults to a generic set of
#pod plugins good for HTML5: 'HTML5' and 'TinyEntitesEscapeRule'
#pod
#pod =cut

has plugins => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [qw( HTML5 TinyEntitesEscapeRule )] },
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
    my @plugins = @{ $self->plugins };

    my $lint = HTML::Lint::Pluggable->new;
    $lint->load_plugins( @plugins );

    for my $page ( @{ $event->pages } ) {
        if ( $page->DOES( 'Statocles::Page::Document' ) ) {
            my $html = "".$page->dom;
            my $page_url = $page->path;

            $lint->newfile( $page_url );
            $lint->parse( $html );
            $lint->eof;
        }
    }

    if ( my @errors = $lint->errors ) {
        for my $error ( @errors ) {
            $event->emitter->log->warn( "-" . $error->as_string );
        }
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

Statocles::Plugin::HTMLLint - Check HTML for common errors and issues

=head1 VERSION

version 0.094

=head1 SYNOPSIS

    # site.yml
    site:
        class: Statocles::Site
        args:
            plugins:
                lint:
                    $class: Statocles::Plugin::HTMLLint

=head1 DESCRIPTION

This plugin checks all of the HTML to ensure it's correct and complete. If something
is missing, this plugin will write a warning to the screen.

=head1 ATTRIBUTES

=head2 plugins

The L<HTML::Lint::Pluggable> plugins to use. Defaults to a generic set of
plugins good for HTML5: 'HTML5' and 'TinyEntitesEscapeRule'

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
