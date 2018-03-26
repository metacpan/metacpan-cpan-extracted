package Statocles::File;
our $VERSION = '0.089';
# ABSTRACT: A wrapper for a file on the filesystem

#pod =head1 SYNOPSIS
#pod
#pod     my $store = Statocles::Store->new( path => 'my/store' );
#pod     my $file = Statocles::File->new(
#pod         store => $store,
#pod         path => 'file.txt', # my/store/file.txt
#pod     );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class encapsulates the information for a file on the filesystem and provides
#pod methods to read the file.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Statocles::Store>, L<Statocles::Document>
#pod
#pod =cut

use Statocles::Base 'Class';

#pod =attr store
#pod
#pod The store that contains this file
#pod
#pod =cut

has store => (
    is => 'ro',
    isa => Store,
    coerce => Store->coercion,
);

#pod =attr path
#pod
#pod The path to this file, relative to the store
#pod
#pod =cut

has path => (
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
    lazy => 1,
    default => sub {
        return shift->path->openr_utf8;
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::File - A wrapper for a file on the filesystem

=head1 VERSION

version 0.089

=head1 SYNOPSIS

    my $store = Statocles::Store->new( path => 'my/store' );
    my $file = Statocles::File->new(
        store => $store,
        path => 'file.txt', # my/store/file.txt
    );

=head1 DESCRIPTION

This class encapsulates the information for a file on the filesystem and provides
methods to read the file.

=head1 ATTRIBUTES

=head2 store

The store that contains this file

=head2 path

The path to this file, relative to the store

=head2 fh

The file handle containing the contents of the page.

=head1 SEE ALSO

L<Statocles::Store>, L<Statocles::Document>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
