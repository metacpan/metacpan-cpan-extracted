package Muster::LeafFile::epub;
$Muster::LeafFile::epub::VERSION = '0.62';
#ABSTRACT: Muster::LeafFile::epub - an EPUB file in a Muster content tree
=head1 NAME

Muster::LeafFile::epub - an EPUB file in a Muster content tree

=head1 VERSION

version 0.62

=head1 DESCRIPTION

File nodes represent files in a Muster::Content content tree.
This is an EPUB file.

=cut

use Mojo::Base 'Muster::LeafFile::EXIF';

use Carp;

# this is not a page
sub is_this_a_page {
    my $self = shift;

    return undef;
}

1;

__END__
