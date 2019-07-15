use utf8;

package SemanticWeb::Schema::Book;

# ABSTRACT: A book.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Book';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has abridged => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'abridged',
);



has book_edition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'bookEdition',
);



has book_format => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'bookFormat',
);



has illustrator => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'illustrator',
);



has isbn => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isbn',
);



has number_of_pages => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfPages',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Book - A book.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A book.

=head1 ATTRIBUTES

=head2 C<abridged>

Indicates whether the book is an abridged edition.

A abridged should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<book_edition>

C<bookEdition>

The edition of the book.

A book_edition should be one of the following types:

=over

=item C<Str>

=back

=head2 C<book_format>

C<bookFormat>

The format of the book.

A book_format should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BookFormatType']>

=back

=head2 C<illustrator>

The illustrator of the book.

A illustrator should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<isbn>

The ISBN of the book.

A isbn should be one of the following types:

=over

=item C<Str>

=back

=head2 C<number_of_pages>

C<numberOfPages>

The number of pages in the book.

A number_of_pages should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
