package Nuvol::Role::Folder;
use Mojo::Base -role, -signatures;

requires qw|_do_make_path _do_remove_tree|;

# methods

sub make_path ($self)   { return $self->_load->_do_make_path; }
sub remove_tree ($self) { return $self->_do_remove_tree; }

1;

=encoding utf8

=head1 NAME

Nuvol::Role::Folder - Role for folders

=head1 SYNOPSIS

    my $folder  = $drive->item('path/to/folder/');

    $folder->make_path;
    $folder->remove_tree;

=head1 DESCRIPTION

L<Nuvol::Role::Folder> is a folder role for L<items|Nuvol::Item>. It is automatically applied if an
item is recognized as folder.

=head1 METHODS

=head2 make_path

    $folder = $folder->make_path;

Creates the folder hierarchy up to this folder.

=head2 remove_tree

    $folder = $folder->remove_tree;

Removes the folder and all the files and subfolders it contains.

=head1 SEE ALSO

L<Nuvol::Item>, L<Nuvol::Role::File>.

=cut
