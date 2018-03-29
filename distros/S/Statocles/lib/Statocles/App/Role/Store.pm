package Statocles::App::Role::Store;
our $VERSION = '0.091';
# ABSTRACT: Role for applications using files

#pod =head1 SYNOPSIS
#pod
#pod     package MyApp;
#pod     use Statocles::Base 'Class';
#pod     with 'Statocles::App::Role::Store';
#pod
#pod     around pages => sub {
#pod         my ( $orig, $self, %options ) = @_;
#pod         my @pages = $self->$orig( %options );
#pod
#pod         # ... Add/remove pages
#pod
#pod         return @pages;
#pod     };
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role provides some basic functionality for those applications that want
#pod to use L<store objects|Statocles::Store> to manage content with Markdown files.
#pod
#pod =cut

use Statocles::Base 'Role';
use Statocles::Page::Document;
use Statocles::Page::File;
with 'Statocles::App';

#pod =attr store
#pod
#pod The directory path or L<store object|Statocles::Store> containing this app's
#pod documents. Required.
#pod
#pod =cut

has store => (
    is => 'ro',
    isa => Store,
    required => 1,
    coerce => Store->coercion,
);

#pod =method pages
#pod
#pod     my @pages = $app->pages;
#pod
#pod Get all the pages for this application. Markdown documents are wrapped
#pod in L<Statocles::Page::Document> objects, and everything else is wrapped in
#pod L<Statocles::Page::File> objects.
#pod
#pod =cut

sub pages {
    my ( $self, %options ) = @_;
    my @pages;
    my $iter = $self->store->iterator;
    while ( my $obj = $iter->() ) {

        if ( $obj->isa( 'Statocles::Document' ) ) {
            my $page_path = $obj->path.'';
            $page_path =~ s{[.]\w+$}{.html};

            my %args = (
                path => $page_path,
                app => $self,
                layout => $self->template( 'layout.html' ),
                document => $obj,
            );

            push @pages, Statocles::Page::Document->new( %args );
        }
        else {
            # If there's a markdown file, don't keep the html file, since
            # we'll be building it from the markdown
            if ( $obj->path =~ /[.]html$/ ) {
                my $doc_path = $obj->path."";
                $doc_path =~ s/[.]html$/.markdown/;
                next if $self->store->has_file( $doc_path );
            }

            push @pages, Statocles::Page::File->new(
                app => $self,
                path => $obj->path->stringify,
                file_path => $self->store->path->child( $obj->path ),
            );
        }
    }

    return @pages;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::App::Role::Store - Role for applications using files

=head1 VERSION

version 0.091

=head1 SYNOPSIS

    package MyApp;
    use Statocles::Base 'Class';
    with 'Statocles::App::Role::Store';

    around pages => sub {
        my ( $orig, $self, %options ) = @_;
        my @pages = $self->$orig( %options );

        # ... Add/remove pages

        return @pages;
    };

=head1 DESCRIPTION

This role provides some basic functionality for those applications that want
to use L<store objects|Statocles::Store> to manage content with Markdown files.

=head1 ATTRIBUTES

=head2 store

The directory path or L<store object|Statocles::Store> containing this app's
documents. Required.

=head1 METHODS

=head2 pages

    my @pages = $app->pages;

Get all the pages for this application. Markdown documents are wrapped
in L<Statocles::Page::Document> objects, and everything else is wrapped in
L<Statocles::Page::File> objects.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
