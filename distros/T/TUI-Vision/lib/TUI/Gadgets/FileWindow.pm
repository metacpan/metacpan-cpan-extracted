package TUI::Gadgets::FileWindow;
# ABSTRACT: TFileWindow is a file window for displaying file contents.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFileWindow
  new_TFileWindow
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  :is
  :types
);

use TUI::App::Program qw( $deskTop );
use TUI::Gadgets::FileViewer;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  ofTileable
  :sbXXXX
);
use TUI::Views::Window;

sub TFileWindow() { __PACKAGE__ }
sub new_TFileWindow { __PACKAGE__->from(@_) }

extends TWindow;

# declaration local variables
my $winNumber = 0;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      fileName => Str,
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds => $deskTop ? $deskTop->getExtent() : TRect->new(),
    title  => $args1->{fileName},
    number => $winNumber++,
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashRef $args );
  $self->{options} |= ofTileable;
  my $r = $self->getExtent();
  $r->grow( -1, -1 );
  $self->insert(
    TFileViewer->new(
      bounds     => $r,
      hScrollBar => $self->standardScrollBar( sbHorizontal | sbHandleKeyboard ),
      vScrollBar => $self->standardScrollBar( sbVertical | sbHandleKeyboard ),
      fileName   => $args->{fileName},
    )
  );
  return;
}

sub from {    # $fileWindow ($fileName)
  state $sig = signature(
    method => 1,
    pos => [Str],
  );
  my ( $class, $fileName ) = $sig->( @_ );
  return $class->new( fileName => $fileName );
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::FileWindow - window for viewing text files

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          TFileWindow

=head1 SYNOPSIS

  sub openFile {
    ...
    if ( $d && $deskTop->execView( $d ) != cmCancel ) {
      my $fileName;
      $d->getFileName( $fileName );

      my $w = $self->validView(
        new_TFileWindow( $fileName )
      );

      $deskTop->insert( $w ) if $w;
    }

    $self->destroy( $d );
  }

=head1 DESCRIPTION

C<TFileWindow> provides a standard window for viewing text files.

The window automatically creates a L<TFileViewer|TUI::Gadgets::FileViewer> 
together with horizontal and vertical scrollbars. The specified file is loaded 
when the window is created and can then be viewed using the standard scrolling 
facilities provided by the framework.

=head1 CONSTRUCTOR

=head2 new

  my $win = TFileWindow->new( fileName => $fileName );

Creates a new file window and initializes an embedded 
L<TFileViewer|TUI::Gadgets::FileViewer> for the specified file.

=over

=item fileName

Name of the file to be displayed (I<Str>).

=back

=head2 new_TFileWindow

  my $win = new_TFileWindow( $fileName );

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and
is provided for compatibility with traditional I<Turbo Vision> construction
patterns.

=head1 SEE ALSO

L<TFileViewer|TUI::Gadgets::FileViewer>,
L<TWindow|TUI::Views::Window>,
L<TScrollBar|TUI::Views::ScrollBar>

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
