package Muster::LeafFile::gif;
$Muster::LeafFile::gif::VERSION = '0.62';
#ABSTRACT: Muster::LeafFile::gif - a GIF file in a Muster content tree
=head1 NAME

Muster::LeafFile::gif - a GIF file in a Muster content tree

=head1 VERSION

version 0.62

=head1 DESCRIPTION

File nodes represent files in a Muster::Content content tree.
This is a GIF file.

=cut

use Mojo::Base 'Muster::LeafFile::EXIF';

use Carp;
use Image::ExifTool qw(:Public);

# this is not a page
sub is_this_a_page {
    my $self = shift;

    return undef;
}

1;

__END__
