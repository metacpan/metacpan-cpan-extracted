package Muster::LeafFile::pdf;
$Muster::LeafFile::pdf::VERSION = '0.93';
#ABSTRACT: Muster::LeafFile::pdf - a PDF file in a Muster content tree
=head1 NAME

Muster::LeafFile::pdf - a PDF file in a Muster content tree

=head1 VERSION

version 0.93

=head1 DESCRIPTION

File nodes represent files in a Muster::Content content tree.
This is a PDF file.

=cut

use Mojo::Base 'Muster::LeafFile::EXIF';

use Carp;

sub is_this_a_binary {
    my $self = shift;

    return 1;
}

1;

__END__
