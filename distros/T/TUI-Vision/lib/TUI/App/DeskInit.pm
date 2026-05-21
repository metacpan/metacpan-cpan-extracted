package TUI::App::DeskInit;
# ABSTRACT: helper for desktop background initialization

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDeskInit
  new_TDeskInit
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  CodeRef
  Object
);

sub TDeskInit() { __PACKAGE__ }
sub new_TDeskInit { __PACKAGE__->from(@_) }

# protected attributes
has createBackground => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      createBackground => CodeRef, { alias => 'cBackground' }
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($cBackground)
  state $sig = signature(
    method => 1,
    pos    => [CodeRef],
  );
  my ( $class, $cBackground ) = $sig->( @_ );
  return $class->new( createBackground => $cBackground );
}

sub createBackground {    # $background ($r)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $r ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createBackground} );
  return $class->$code( $r );
}

1

__END__

=pod

=head1 NAME

TUI::App::DeskInit - helper for desktop background initialization

=head1 SYNOPSIS

  use TUI::App::DeskInit;

  my $deskInit = TDeskInit->new(
    createBackground => sub {
      my ($rect) = @_;
      return TBackground->new($rect, ' ');
    }
  );

=head1 DESCRIPTION

C<TDeskInit> encapsulates the logic required to create the desktop background
view during application initialization.

The class stores a background factory callback which is invoked to construct a
C<TBackground> instance for a given screen rectangle. This allows applications
to customize how the desktop background is created without embedding that logic
directly into the desktop or application classes.

C<TDeskInit> is not a view itself and is not intended to be used directly by
application code beyond application setup.

=head1 CONSTRUCTOR

=head2 new

  my $deskInit = TDeskInit->new(
    createBackground => \&callback
  );

Creates a new desktop initialization helper.

=over

=item createBackground

A code reference that is called with a C<TRect> argument and must return a
C<TBackground> object. This callback defines how the desktop background view is
constructed.

=back

=head2 new_TDeskInit

  my $deskInit = new_TDeskInit(\&callback);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 createBackground

  my $background = $deskInit->createBackground($rect);

Invokes the stored background factory callback and returns a background view
for the specified rectangle.

=head1 SEE ALSO

L<TUI::App::DeskTop>,
L<TUI::App::Background>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
