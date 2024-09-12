package Net::FTP::Path::Iter::File;

# ABSTRACT: Class representing a File

use 5.010;
use strict;
use warnings;

our $VERSION = '0.07';

use strict;
use warnings;

use Carp;

use File::Spec::Functions qw[ catfile ];

use namespace::clean;

use parent 'Net::FTP::Path::Iter::Entry';

use constant is_file => 1;
use constant is_dir  => 0;

# if an entity doesn't have attributes, it didn't get loaded
# from a directory listing.  Try to get one.
sub _retrieve_attrs {

    my $self = shift;
    return if $self->_has_attrs;

    my ( $entry ) = my @entries = grep $self->name eq $_->{name}, $self->get_entries( $self->parent );

    croak( 'multiple ftp entries for ', $self->path )
      if @entries > 1;

    croak( 'unable to find attributes for ', $self->path )
      if @entries == 0;

    croak( $self->{path}, ': expected file, got ', $entry->{type} )
      unless $entry->{type} eq 'f';

    $self->$_( $entry->{$_} ) for keys %$entry;

    return;
}

#
# This file is part of Net-FTP-Path-Iter
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Net::FTP::Path::Iter::File - Class representing a File

=head1 VERSION

version 0.07

=head1 DESCRIPTION

B<Net::FTP::Path::Iter::File> is a class representing a file entry. It is a subclass
of L<Net::FTP::Path::Iter::Entry>; see it for all available methods.

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-net-ftp-path-iter@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-FTP-Path-Iter>

=head2 Source

Source is available at

  https://gitlab.com/djerius/net-ftp-path-iter

and may be cloned from

  https://gitlab.com/djerius/net-ftp-path-iter.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::FTP::Path::Iter|Net::FTP::Path::Iter>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
