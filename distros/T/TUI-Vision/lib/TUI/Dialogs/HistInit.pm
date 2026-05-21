package TUI::Dialogs::HistInit;
# ABSTRACT: Provides a simple initializer for creating list viewer objects.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistInit
  new_THistInit
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

sub THistInit() { __PACKAGE__ }
sub new_THistInit { __PACKAGE__->from(@_) }

# private attributes
has createListViewer => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      createListViewer => CodeRef, { alias => 'cListViewer' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $init ($cListViewer)
  state $sig = signature(
    method => 1,
    pos    => [CodeRef],
  );
  my ( $class, $cListViewer ) = $sig->( @_ );
  return $class->new( cListViewer => $cListViewer );
}

sub createListViewer {    # $listViewer ($r, $win, $historyId)
  state $sig = signature(
    method => Object,
    pos    => [Object, Object, PositiveOrZeroInt],
  );
  my ( $self, $r, $win, $historyId ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createListViewer} );
  return $class->$code( $r, $win, $historyId );
}

1

__END__

=pod

=head1 NAME

TUI::Dialogs::HistInit - initializer for history list viewer creation

=head1 SYNOPSIS

  package MyHistoryWindow;

  use MyListViewer;
  use TUI::Dialogs::HistInit;

  # Callback creating a list viewer
  my $cb = sub {
    my ($extent, $win, $historyId) = @_;
    return MyListViewer->new(
      bounds    => $extent,
      owner     => $win,
      historyId => $historyId,
    );
  };

  # Used in our window class
  sub new {
    ...
    my $historyId = $args->{historyId};
    my $extent = $self->getExtent();

    # Initializer object
    my $init = THistInit->new(cListViewer => $cb);
    my $listViewer = $init->createListViewer($extent, $self, $historyId);
    $self->insert($listViewer);
    ...
  }

=head1 DESCRIPTION

C<TUI::Dialogs::HistInit> encapsulates the initialization logic required to
create history list viewer objects in TUI::Vision dialogs.

The class stores a user-supplied callback which is invoked whenever a list
viewer needs to be constructed. This allows dialogs to customize the concrete
list viewer implementation while keeping dialog initialization code simple and
decoupled.

C<HistInit> is not a view and does not participate in the view hierarchy. It
exists solely as a helper for dialog setup.

=head1 CONSTRUCTOR

=head2 new

  my $init = THistInit->new(
    createListViewer => \&callback
  );

Creates a new history initializer.

=over

=item createListViewer

A code reference that is called with three arguments:

  ($extent, $window, $historyId)

The callback must return a list viewer object suitable for insertion into the
owning dialog.

=back

=head2 new_THistInit

  my $init = new_THistInit(\&callback);

Factory-style constructor using a positional argument for the callback.

=head1 METHODS

=head2 createListViewer

  my $listViewer = $init->createListViewer($extent, $window, $historyId);

Invokes the stored callback and returns a newly created list viewer object.

=head1 SEE ALSO

L<TUI::Dialogs::History>,
L<TUI::Dialogs::ListBox>

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
