package Statocles::Page::File;
our $VERSION = '0.087';
# ABSTRACT: A page wrapping a file (handle)

use Statocles::Base 'Class';
with 'Statocles::Page';

#pod =attr file_path
#pod
#pod The path to the file.
#pod
#pod =cut

has file_path => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
);

#pod =attr fh
#pod
#pod The file handle containing the contents of the page.
#pod
#pod =cut

has fh => (
    is => 'ro',
    isa => FileHandle,
);

#pod =method vars
#pod
#pod Dies. This page has no templates and no template variables.
#pod
#pod =cut

# XXX: This may have to be implemented in the future, to allow for some useful edge
# cases.
sub vars { die "Unimplemented" }

#pod =attr dom
#pod
#pod This page has no DOM, so trying to access it throws an exception.
#pod
#pod =cut

sub dom { die "Unimplemented" }

#pod =method has_dom
#pod
#pod Returns false. This page has no DOM.
#pod
#pod =cut

sub has_dom { 0 }

#pod =method render
#pod
#pod     my $fh = $page->render;
#pod
#pod Return the filehandle to the file containing the content for this page.
#pod
#pod =cut

sub render {
    my ( $self ) = @_;
    $self->site->log->debug( 'Render page: ' . $self->path );
    return $self->file_path ? $self->file_path : $self->fh;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Page::File - A page wrapping a file (handle)

=head1 VERSION

version 0.087

=head1 SYNOPSIS

    # File path
    my $page = Statocles::Page::File->new(
        path => '/path/to/page.txt',
        file_path => '/path/to/file.txt',
    );

    # Filehandle
    open my $fh, '<', '/path/to/file.txt';
    my $page = Statocles::Page::File->new(
        path => '/path/to/page.txt',
        fh => $fh,
    );

=head1 DESCRIPTION

This L<Statocles::Page> wraps a file handle in order to move files from one
L<store|Statocles::Store> to another.

=head1 ATTRIBUTES

=head2 file_path

The path to the file.

=head2 fh

The file handle containing the contents of the page.

=head2 dom

This page has no DOM, so trying to access it throws an exception.

=head1 METHODS

=head2 vars

Dies. This page has no templates and no template variables.

=head2 has_dom

Returns false. This page has no DOM.

=head2 render

    my $fh = $page->render;

Return the filehandle to the file containing the content for this page.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
