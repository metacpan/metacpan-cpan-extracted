package Net::FTP::Path::Iter::Entry;

use 5.010;

# ABSTRACT: Class representing a Filesystem Entry

use strict;
use warnings;

our $VERSION = '0.07';

use Carp;
use Fcntl qw[ :mode ];

use File::Listing qw[ parse_dir ];

use namespace::clean;

use overload
  '-X'     => '_statit',
  'bool'   => sub { 1 },
  '""'     => sub { $_[0]->{path} },
  fallback => !!1,
  ;

use Class::Tiny qw[
  name type size mtime mode parent server path
], { _has_attrs => 0 };










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

    ## no critic ( ControlStructures::ProhibitCascadingIfElse )
    if ( $op eq 'd' ) { return $self->is_dir }

    elsif ( $op eq 'f' ) { return $self->is_file }

    elsif ( $op eq 's' ) { return $self->size }

    elsif ( $op eq 'z' ) { return $self->size != 0 }

    elsif ( $op eq 'r' ) { return S_IROTH & $self->mode }

    elsif ( $op eq 'R' ) { return S_IROTH & $self->mode }

    elsif ( $op eq 'l' ) { return 0 }

    else { croak( "unsupported file test: -$op" ) }

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
    my $err;
    eval {
        $server->cwd( $path )
          or croak( 'unable to chdir to ', $path );

        my $listing = $server->dir( q{.} )
          or croak( "error listing $path" );

        for my $entry ( parse_dir( $listing ) ) {

            my %attr;
            @attr{qw[ name type size mtime mode]} = @$entry;
            $attr{parent}                         = $path;
            $attr{_has_attrs}                     = 1;

            push @entries, \%attr;

        }
        1;
    } // ( $err = $@ );

    $server->cwd( $pwd )
      or croak( "unable to return to directory: $pwd" );

    croak( $err ) if defined $err;

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

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Net::FTP::Path::Iter::Entry - Class representing a Filesystem Entry

=head1 VERSION

version 0.07

=head1 DESCRIPTION

A B<Net::FTP::Path::Iter::Entry> object represents an entry in the remote
FTP filesystem.  It is rarely seen in the wild. Rather,
L<Net::FTP::Path::Iter> uses the subclasses B<Net::FTP::Path::Iter::Entry::File>
and B<Net::FTP::Path::Iter::Entry::Dir> when passing paths to callbacks or
returning paths to iterators.  These subclasses have no unique methods
or attributes of their own; they only have those of this, their parent
class.

=head1 OBJECT ATTRIBUTES

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

=head1 INTERNALS

=begin pod_coverage

=head3 BUILD

=end pod_coverage

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
