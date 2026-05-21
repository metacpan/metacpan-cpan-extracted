package TUI::StdDlg::DirEntry;
# ABSTRACT: A directory entry for use in TDirCollection

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDirEntry
  new_TDirEntry
);

use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use TUI::toolkit qw( signature );
use TUI::toolkit::Types qw(
  Object
  Str
);

sub TDirEntry() { __PACKAGE__ }
sub new_TDirEntry { __PACKAGE__->from(@_) }

# private attributes
our %HAS; BEGIN {
  %HAS = ( 
    displayText => sub { die 'required' },
    directory   => sub { die 'required' },
  );
}

sub new {    # \$obj (%args)
  state $sig = signature(
    method => 1,
    named  => [
      displayText => Str, { alias => 'txt' },
      directory   => Str, { alias => 'dir' },
    ],
  );
  my ( $class, $args ) = $sig->( @_ );
  my $self = {
    displayText => $args->{displayText} // $HAS{displayText}->(),
    directory   => $args->{directory}   // $HAS{directory}->(),
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub from {    # $obj ($x, $y)
  state $sig = signature(
    method => 1,
    pos => [Str, Str],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( displayText => $args[0], directory => $args[1] );
}

sub dir  {
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{directory};
}

sub text {
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{displayText};
}

1

__END__

=pod

=head1 NAME

TUI::StdDlg::DirEntry - directory entry record used by standard dialogs

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $entry = TDirEntry->new(
    displayText => 'etc',
    directory   => '/etc'
  );

  my $text = $entry->text;
  my $dir  = $entry->dir;

=head1 DESCRIPTION

C<TDirEntry> represents a single directory entry used by the standard dialog
subsystem. It is a lightweight data object that stores the display text and the
associated directory path.

This class is not derived from C<TObject> and does not participate in the view
hierarchy. It exists solely as a structured data container and is used by
collections and list boxes to represent directory items.

=head1 CONSTRUCTOR

=head2 new

  my $entry = TDirEntry->new(
    displayText => $text,
    directory   => $dir
  );

Creates a new directory entry.

=over

=item displayText

Text shown to the user for this directory entry (I<Str>).

=item directory

Filesystem path associated with this entry (I<Str>).

=back

=head1 METHODS

=head2 text

  my $text = $entry->text;

Returns the display text of the directory entry.

=head2 dir

  my $dir = $entry->dir;

Returns the directory path associated with the entry.

=head1 SEE ALSO

L<TUI::StdDlg::DirCollection>,
L<TUI::StdDlg::DirListBox>,
L<TUI::StdDlg::ChDirDialog>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
