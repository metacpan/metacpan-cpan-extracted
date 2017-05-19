package Net::FTP::Path::Iter::Entry;

use 5.010;

# ABSTRACT: Class representing a Filesystem Entry

use strict;
use warnings;
use experimental 'switch';

our $VERSION = '0.04';

use Carp;
use Fcntl qw[ :mode ];

use File::Listing qw[ parse_dir ];

use namespace::clean;

use overload
  '-X'   => '_statit',
  'bool' => sub { 1 },
  '""'   => sub { $_[0]->{path} },
  ;

use Class::Tiny qw[
  name type size mtime mode parent server path
  ], { _has_attrs => 0 };

#pod =begin pod_coverage
#pod
#pod =head3 BUILD
#pod
#pod =end pod_coverage
#pod
#pod =cut


sub BUILD {

    my $self = shift;
    $self->_retrieve_attrs
      unless $self->_has_attrs;
}

sub _statit {

    my $self = shift;
    my $op   = shift;

    $self->_retrieve_attrs
      unless $self->_has_attrs;

    for ( $op ) {

        when ( 'd' ) { return $self->is_dir }

        when ( 'f' ) { return $self->is_file }

        when ( 's' ) { return $self->size }

        when ( 'z' ) { return $self->size != 0 }

        when ( 'r' ) { return S_IROTH & $self->mode }

        when ( 'R' ) { return S_IROTH & $self->mode }

        when ( 'l' ) { return 0 }

        default { croak( "unsupported file test: -$op\n" ) }

    }

}

sub _get_entries {

    my ( $self, $path ) = @_;

    my $server = $self->server;

    my $pwd = $server->pwd;

    # on some ftp servers, if $path is a symbolic link, dir($path)
    # willl return a listing of $path's own entry, not of its
    # contents.  as a work around, explicitly cwd($path),
    # get the listing, then restore the working directory

    my @entries;
    eval {
        $server->cwd( $path )
          or croak( "unable to chdir to ", $path, "\n" );

        my $listing = $server->dir( '.' )
          or croak( "error listing $path" );

        for my $entry ( parse_dir( $listing ) ) {

            my %attr;
            @attr{qw[ name type size mtime mode]} = @$entry;
            $attr{parent}                         = $path;
            $attr{_has_attrs}                      = 1;

            push @entries, \%attr;

        }
    };

    my $err = $@;

    $server->cwd( $pwd )
      or croak( "unable to return to directory: $pwd\n" );

    croak( $err ) if $err;


    return \@entries;

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

=pod

=head1 NAME

Net::FTP::Path::Iter::Entry - Class representing a Filesystem Entry

=head1 VERSION

version 0.04

=head1 DESCRIPTION

A B<Net::FTP::Path::Iter::Entry> object represents an entry in the remote
FTP filesystem.  It is rarely seen in the wild. Rather,
L<Net::FTP::Path::Iter> uses the subclasses B<Net::FTP::Path::Iter::Entry::File>
and B<Net::FTP::Path::Iter::Entry::Dir> when passing paths to callbacks or
returning paths to iterators.  These subclasses have no unique methods
or attributes of their own; they only have those of this, their parent
class.

=head1 ATTRIBUTES

=head2 mode

The entry mode as returned by L<stat>.

=head2 mtime

The entry modification time.

=head2 name

The entry name.

=head2 path

The complete path to the entry

=head2 parent

The parent directory of the entry

=head2 server

The L<Net::FTP> server object

=head2 size

The size of the entry

=head2 type

The type of the entry, one of

=over

=item f

file

=item d

directory

=item l

symbolic link. See however L<Net::FTP::Path::Iter/Symbolic Links>

=item ?

unknown

=back

=head1 METHODS

=head2 is_dir

  $bool = $entry->is_dir;

returns true if the entry is a directory.

=head2 is_file

  $bool = $entry->is_file;

returns true if the entry is a file.

=begin pod_coverage

=head3 BUILD

=end pod_coverage

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-FTP-Path-Iter>.

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

__END__

#pod =pod
#pod
#pod =method is_dir
#pod
#pod   $bool = $entry->is_dir;
#pod
#pod returns true if the entry is a directory.
#pod
#pod =method is_file
#pod
#pod   $bool = $entry->is_file;
#pod
#pod returns true if the entry is a file.
#pod
#pod =attr mode
#pod
#pod The entry mode as returned by L<stat>.
#pod
#pod =attr mtime
#pod
#pod The entry modification time.
#pod
#pod =attr name
#pod
#pod The entry name.
#pod
#pod =attr path
#pod
#pod The complete path to the entry
#pod
#pod =attr parent
#pod
#pod The parent directory of the entry
#pod
#pod =attr server
#pod
#pod The L<Net::FTP> server object
#pod
#pod =attr size
#pod
#pod The size of the entry
#pod
#pod =attr type
#pod
#pod The type of the entry, one of
#pod
#pod =over
#pod
#pod =item f
#pod
#pod file
#pod
#pod =item d
#pod
#pod directory
#pod
#pod =item l
#pod
#pod symbolic link. See however L<Net::FTP::Path::Iter/Symbolic Links>
#pod
#pod =item ?
#pod
#pod unknown
#pod
#pod
#pod =back
#pod
#pod =cut


#pod =head1 DESCRIPTION
#pod
#pod A B<Net::FTP::Path::Iter::Entry> object represents an entry in the remote
#pod FTP filesystem.  It is rarely seen in the wild. Rather,
#pod L<Net::FTP::Path::Iter> uses the subclasses B<Net::FTP::Path::Iter::Entry::File>
#pod and B<Net::FTP::Path::Iter::Entry::Dir> when passing paths to callbacks or
#pod returning paths to iterators.  These subclasses have no unique methods
#pod or attributes of their own; they only have those of this, their parent
#pod class.
#pod
