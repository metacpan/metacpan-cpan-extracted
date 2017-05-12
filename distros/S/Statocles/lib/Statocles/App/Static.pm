package Statocles::App::Static;
our $VERSION = '0.083';
# ABSTRACT: (DEPRECATED) Manage static files like CSS, JS, images, and other untemplated content

use Statocles::Base 'Class';
use Statocles::Page::File;
use Statocles::Util qw( derp );
with 'Statocles::App';

#pod =attr store
#pod
#pod The L<store|Statocles::Store> containing this app's files. Required.
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
#pod Get the L<page objects|Statocles::Page> for this app.
#pod
#pod =cut

sub pages {
    my ( $self ) = @_;

    derp qq{Statocles::App::Static has been replaced by Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.};

    my @pages;
    my $iter = $self->store->find_files( include_documents => 1 );
    FILE: while ( my $path = $iter->() ) {
        # Check for hidden files and folders
        next if $path->basename =~ /^[.]/;
        my $parent = $path->parent;
        while ( !$parent->is_rootdir ) {
            next FILE if $parent->basename =~ /^[.]/;
            $parent = $parent->parent;
        }

        push @pages, Statocles::Page::File->new(
            path => $path,
            file_path => $self->store->path->child( $path ),
        );
    }

    return @pages;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::App::Static - (DEPRECATED) Manage static files like CSS, JS, images, and other untemplated content

=head1 VERSION

version 0.083

=head1 DESCRIPTION

B<NOTE:> This application's functionality has been added to
L<Statocles::App::Basic>. You can use the Basic app to replace this app. This
class will be removed with v2.0. See L<Statocles::Help::Upgrading>.

This L<Statocles::App|Statocles::App> manages static content with no processing,
perfect for images, stylesheets, scripts, or already-built HTML.

=head1 ATTRIBUTES

=head2 store

The L<store|Statocles::Store> containing this app's files. Required.

=head1 METHODS

=head2 pages

    my @pages = $app->pages;

Get the L<page objects|Statocles::Page> for this app.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
