package Muster::LeafFile::jpg;
$Muster::LeafFile::jpg::VERSION = '0.92';
#ABSTRACT: Muster::LeafFile::jpg - a JPEG file in a Muster content tree
=head1 NAME

Muster::LeafFile::jpg - a JPEG file in a Muster content tree

=head1 VERSION

version 0.92

=head1 DESCRIPTION

File nodes represent files in a Muster::Content content tree.
This is a JPEG file.

=cut

use Mojo::Base 'Muster::LeafFile::EXIF';

use Carp;

sub is_this_a_binary {
    my $self = shift;

    return 1;
}

1;

__END__
