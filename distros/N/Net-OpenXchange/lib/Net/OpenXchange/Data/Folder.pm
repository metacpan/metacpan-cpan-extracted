use Modern::Perl;
package Net::OpenXchange::Data::Folder;
BEGIN {
  $Net::OpenXchange::Data::Folder::VERSION = '0.001';
}

use Moose::Role;
use namespace::autoclean;

# ABSTRACT: OpenXchange detailed folder data

use Net::OpenXchange::Types;

has title => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 300,
);

has module => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 301,
);

has subfolders => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Bool',
    coerce => 1,
    ox_id  => 304,
);

1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Data::Folder - OpenXchange detailed folder data

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Data::Folder is a role providing attributes for
L<Net::OpenXchange::Object|Net::OpenXchange::Object> packages.

=head1 ATTRIBUTES

=head2 title (Str)

Title of this folder

=head2 module (Str)

OpenXchange module providing this folder

=head2 subfolders (Bool)

True if this folder has subfolders

=head1 SEE ALSO

L<http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedFolderData|http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedFolderData>

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

